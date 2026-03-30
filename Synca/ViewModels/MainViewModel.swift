import Foundation
import Combine
import SwiftUI

/// アプリ全体の状態管理（MVVM中枢）
@MainActor
final class MainViewModel: ObservableObject {
    // MARK: - Published: Core State
    @Published private(set) var emotionGauge: Double = 0.0
    @Published private(set) var emotionState: EmotionState = .calm
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var currentCharacter: Character
    @Published private(set) var currentDialogue: String = ""
    @Published private(set) var characterAnimationState: CharacterAnimationState = .idle
    @Published private(set) var availableCharacters: [Character]
    @Published private(set) var gaugePulseTrigger: Int = 0
    @Published private(set) var gaugePulseStrength: Double = 0.0

    // MARK: - Published: UI State
    @Published var showCharacterSelection: Bool = false
    @Published var showSettings: Bool = false
    @Published var isPremium: Bool = false

    // MARK: - Published: Settings
    @Published var sensitivity: Double = 1.0 {
        didSet {
            motionService.sensitivity = sensitivity
            motionAnalyzer.reset()
        }
    }
    @Published var volume: Double = 0.8 {
        didSet { audioService.volume = volume }
    }

    // MARK: - Dependencies
    private let motionService: MotionService
    private let motionAnalyzer: MotionAnalyzer
    private let audioService: AudioService
    private let dialogueManager: DialogueManager
    private let characterManager: CharacterManager
    let purchaseService: PurchaseService

    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Tunables
    private enum GaugeTuning {
        // 感度ごとの到達目標時間:
        // 最低(0.2) -> 30分, 1つ前(2.0) -> 1分, 最高(3.0) -> 30秒
        static let minSensitivity: Double = 0.2
        static let preMaxSensitivity: Double = 2.0
        static let maxSensitivity: Double = 3.0
        static let minTargetDuration: TimeInterval = 30 * 60
        static let preMaxTargetDuration: TimeInterval = 60
        static let maxTargetDuration: TimeInterval = 30

        static let decayRate: Double = 0.003
        static let decayInterval: TimeInterval = 0.1
        static let minMotionDelta: Double = 1.0 / 120.0
        static let maxMotionDelta: Double = 0.2

        // 振動強度の係数化
        static let intensityDeadZone: Double = 0.015
        static let referenceIntensity: Double = 0.22
        static let maxIntensityFactor: Double = 3.0

        static let pulseThreshold: Double = 0.012
        static let pulseMinInterval: TimeInterval = 0.08
    }

    private enum AnimationTuning {
        static let cooldown: TimeInterval = 0.15
        static let normalResetDelay: TimeInterval = 0.5
        static let specialResetDelay: TimeInterval = 1.5
    }

    // MARK: - Internal State
    private var lastAnimationTime: Date = .distantPast
    private var lastMotionTimestamp: TimeInterval?
    private var lastGaugePulseTimestamp: TimeInterval = 0
    private var currentLanguage: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: AppPreferenceKey.appLanguage) ?? AppLanguage.japanese.rawValue
        return AppLanguage(rawValue: raw) ?? .japanese
    }

    // MARK: - Init
    init(
        motionService: MotionService = MotionService(),
        motionAnalyzer: MotionAnalyzer = MotionAnalyzer(),
        audioService: AudioService = AudioService(),
        dialogueManager: DialogueManager = DialogueManager(),
        characterManager: CharacterManager = .shared,
        purchaseService: PurchaseService? = nil
    ) {
        self.motionService = motionService
        self.motionAnalyzer = motionAnalyzer
        self.audioService = audioService
        self.dialogueManager = dialogueManager
        self.characterManager = characterManager
        self.purchaseService = purchaseService ?? PurchaseService()
        self.availableCharacters = characterManager.allCharacters
        self.currentCharacter = characterManager.defaultCharacter
        currentDialogue = dialogueManager.getDialogue(
            for: .calm,
            characterId: currentCharacter.id,
            language: currentLanguage
        )
        setupBindings()
    }

    // MARK: - Public API

    func toggleSession() {
        isRunning ? stopSession() : startSession()
    }

    func startSession() {
        motionAnalyzer.reset()
        lastMotionTimestamp = nil
        lastGaugePulseTimestamp = 0
        motionService.start()
        isRunning = true
    }

    func stopSession() {
        motionService.stop()
        isRunning = false
        lastMotionTimestamp = nil
        characterAnimationState = .idle
    }

    func presentCharacterSelection() {
        showCharacterSelection = true
    }

    func presentSettings() {
        showSettings = true
    }

    func selectCharacter(_ character: Character) {
        guard let selectableCharacter = availableCharacters.first(where: { $0.id == character.id }),
              !selectableCharacter.isLocked else { return }
        currentCharacter = selectableCharacter
        showCharacterSelection = false
        refreshDialogue()
    }

    func purchaseCharacter(_ character: Character) async {
        guard let productID = character.productID else { return }
        await purchaseService.purchase(productID: productID)
    }

    func purchaseRemoveAds() async {
        await purchaseService.purchase(productID: PurchaseService.ProductID.removeAds)
    }

    func refreshDialogue() {
        currentDialogue = dialogueManager.getDialogue(
            for: emotionState,
            characterId: currentCharacter.id,
            language: currentLanguage
        )
    }

    // MARK: - Private: Setup

    private func setupBindings() {
        // Motion → Gauge update
        motionService.$currentMotionData
            .receive(on: RunLoop.main)
            .sink { [weak self] data in
                guard let self, self.isRunning else { return }
                self.processMotion(data)
            }
            .store(in: &cancellables)

        // Gauge decay timer
        Timer.publish(every: GaugeTuning.decayInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.decayGauge() }
            .store(in: &cancellables)

        // Purchase → unlock characters
        purchaseService.$purchasedProductIDs
            .sink { [weak self] ids in
                self?.applyPurchasedProducts(ids)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private: Motion Processing

    private func processMotion(_ data: MotionData) {
        let result = motionAnalyzer.analyze(data)
        let delta = clampedMotionDelta(for: data.timestamp)

        // ゲージ増加（感度ごとの目標時間 + 振動強度係数）
        let increaseRate = gaugeIncreasePerSecond(for: sensitivity)
        let intensityFactor = gaugeIntensityFactor(
            smoothedIntensity: result.smoothedIntensity,
            sensitivity: sensitivity
        )
        let increase = increaseRate * intensityFactor * delta
        emotionGauge = min(emotionGauge + increase, 100.0)

        // 振動イベントをUIへ通知（ゲージの増加を視覚化）
        let pulseInput = max(result.intensity, result.smoothedIntensity)
        if pulseInput > GaugeTuning.pulseThreshold,
           data.timestamp - lastGaugePulseTimestamp >= GaugeTuning.pulseMinInterval {
            lastGaugePulseTimestamp = data.timestamp
            gaugePulseStrength = min(max(pulseInput * 1.8, 0.18), 1.0)
            gaugePulseTrigger &+= 1
        }

        // アニメーション更新（クールダウン付き）
        let now = Date()
        if result.isPeak, now.timeIntervalSince(lastAnimationTime) > AnimationTuning.cooldown {
            lastAnimationTime = now
            let anim: CharacterAnimationState = result.intensity > 0.5 ? .excited : .react
            setAnimation(anim)
        }

        // 感情状態チェック
        let newState = EmotionState(gauge: emotionGauge)
        if newState != emotionState {
            transitionState(to: newState)
        }
    }

    private func clampedMotionDelta(for timestamp: TimeInterval) -> Double {
        defer { lastMotionTimestamp = timestamp }
        guard let previous = lastMotionTimestamp else { return 1.0 / 30.0 }
        let rawDelta = timestamp - previous
        return min(max(rawDelta, GaugeTuning.minMotionDelta), GaugeTuning.maxMotionDelta)
    }

    private func gaugeIncreasePerSecond(for sensitivity: Double) -> Double {
        let targetDuration = targetFillDuration(for: sensitivity)
        let targetNetIncrease = 100.0 / max(targetDuration, 1)
        let decayPerSecond = GaugeTuning.decayRate / GaugeTuning.decayInterval
        return targetNetIncrease + decayPerSecond
    }

    private func targetFillDuration(for sensitivity: Double) -> TimeInterval {
        let s = min(max(sensitivity, GaugeTuning.minSensitivity), GaugeTuning.maxSensitivity)

        if s <= GaugeTuning.preMaxSensitivity {
            let progress = (s - GaugeTuning.minSensitivity) /
                (GaugeTuning.preMaxSensitivity - GaugeTuning.minSensitivity)
            return logInterpolate(
                from: GaugeTuning.minTargetDuration,
                to: GaugeTuning.preMaxTargetDuration,
                progress: progress
            )
        } else {
            let progress = (s - GaugeTuning.preMaxSensitivity) /
                (GaugeTuning.maxSensitivity - GaugeTuning.preMaxSensitivity)
            return logInterpolate(
                from: GaugeTuning.preMaxTargetDuration,
                to: GaugeTuning.maxTargetDuration,
                progress: progress
            )
        }
    }

    private func logInterpolate(from: Double, to: Double, progress: Double) -> Double {
        let p = min(max(progress, 0), 1)
        return exp(log(from) + (log(to) - log(from)) * p)
    }

    private func gaugeIntensityFactor(smoothedIntensity: Double, sensitivity: Double) -> Double {
        // MotionService側で感度が乗算済みのため、ここでは一度感度で正規化して
        // 「実際の振動の強さ」に応じて係数化する。
        let normalizedIntensity = smoothedIntensity / max(sensitivity, GaugeTuning.minSensitivity)
        let adjusted = max(normalizedIntensity - GaugeTuning.intensityDeadZone, 0)
        let reference = max(GaugeTuning.referenceIntensity - GaugeTuning.intensityDeadZone, 0.0001)
        let normalized = adjusted / reference
        return min(max(normalized, 0), GaugeTuning.maxIntensityFactor)
    }

    private func decayGauge() {
        guard emotionGauge > 0 else {
            if characterAnimationState != .idle { characterAnimationState = .idle }
            return
        }
        emotionGauge = max(emotionGauge - GaugeTuning.decayRate, 0.0)
    }

    private func transitionState(to newState: EmotionState) {
        emotionState = newState
        refreshDialogue()
        audioService.playStateSound(for: newState)

        if newState == .special {
            setAnimation(.special)
        }
    }

    private func setAnimation(_ state: CharacterAnimationState) {
        characterAnimationState = state
        // 一定時間後に通常状態へ戻す
        let resetDelay = state == .special ? AnimationTuning.specialResetDelay : AnimationTuning.normalResetDelay
        DispatchQueue.main.asyncAfter(deadline: .now() + resetDelay) { [weak self] in
            guard let self, self.characterAnimationState == state else { return }
            self.characterAnimationState = self.emotionState == .special ? .special : .idle
        }
    }

    private func applyPurchasedProducts(_ productIDs: Set<String>) {
        for productID in productIDs {
            guard let character = characterManager.allCharacters.first(where: { $0.productID == productID }) else {
                continue
            }
            characterManager.unlock(characterId: character.id)
        }

        availableCharacters = characterManager.allCharacters

        if let current = characterManager.character(id: currentCharacter.id) {
            currentCharacter = current
        } else {
            currentCharacter = characterManager.defaultCharacter
        }

        isPremium = productIDs.contains(PurchaseService.ProductID.removeAds)
    }
}

// MARK: - Animation State
enum CharacterAnimationState: Equatable {
    case idle
    case react
    case excited
    case special
}

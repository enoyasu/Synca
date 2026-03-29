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

    // MARK: - Services (internal visibility for PurchaseService access)
    private let motionService = MotionService()
    private let motionAnalyzer = MotionAnalyzer()
    private let audioService = AudioService()
    private let dialogueManager = DialogueManager()
    let purchaseService = PurchaseService()

    // MARK: - Gauge constants
    private let gaugeIncreaseMultiplier: Double = 18.0
    private let gaugeDecayRate: Double = 0.5          // per tick
    private let gaugeDecayInterval: TimeInterval = 0.1

    // MARK: - Animation cooldown
    private var lastAnimationTime: Date = .distantPast
    private let animationCooldown: TimeInterval = 0.15

    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        currentCharacter = CharacterManager.shared.defaultCharacter
        setupBindings()
        currentDialogue = dialogueManager.getDialogue(for: .calm, characterId: currentCharacter.id)
    }

    // MARK: - Public API

    func toggleSession() {
        isRunning ? stopSession() : startSession()
    }

    func startSession() {
        motionAnalyzer.reset()
        motionService.start()
        isRunning = true
    }

    func stopSession() {
        motionService.stop()
        isRunning = false
        characterAnimationState = .idle
    }

    func selectCharacter(_ character: Character) {
        guard !character.isLocked else { return }
        currentCharacter = character
        refreshDialogue()
    }

    func refreshDialogue() {
        currentDialogue = dialogueManager.getDialogue(
            for: emotionState,
            characterId: currentCharacter.id
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
        Timer.publish(every: gaugeDecayInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.decayGauge() }
            .store(in: &cancellables)

        // Purchase → unlock characters
        purchaseService.$purchasedProductIDs
            .sink { [weak self] ids in
                guard let self else { return }
                for id in ids {
                    let character = CharacterManager.shared.allCharacters
                        .first(where: { $0.productID == id })
                    if let c = character {
                        CharacterManager.shared.unlock(characterId: c.id)
                    }
                }
                if ids.contains(PurchaseService.ProductID.removeAds) {
                    self.isPremium = true
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private: Motion Processing

    private func processMotion(_ data: MotionData) {
        let result = motionAnalyzer.analyze(data)

        // ゲージ増加
        let increase = result.smoothedIntensity * gaugeIncreaseMultiplier
        emotionGauge = min(emotionGauge + increase, 100.0)

        // アニメーション更新（クールダウン付き）
        let now = Date()
        if result.isPeak, now.timeIntervalSince(lastAnimationTime) > animationCooldown {
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

    private func decayGauge() {
        guard emotionGauge > 0 else {
            if characterAnimationState != .idle { characterAnimationState = .idle }
            return
        }
        emotionGauge = max(emotionGauge - gaugeDecayRate, 0.0)
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
        let resetDelay: TimeInterval = state == .special ? 1.5 : 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + resetDelay) { [weak self] in
            guard let self, self.characterAnimationState == state else { return }
            self.characterAnimationState = self.emotionState == .special ? .special : .idle
        }
    }
}

// MARK: - Animation State
enum CharacterAnimationState: Equatable {
    case idle
    case react
    case excited
    case special
}

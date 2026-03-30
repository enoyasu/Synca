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
        static let increaseMultiplier: Double = 18.0
        static let decayRate: Double = 0.5
        static let decayInterval: TimeInterval = 0.1
    }

    private enum AnimationTuning {
        static let cooldown: TimeInterval = 0.15
        static let normalResetDelay: TimeInterval = 0.5
        static let specialResetDelay: TimeInterval = 1.5
    }

    // MARK: - Internal State
    private var lastAnimationTime: Date = .distantPast

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
        currentDialogue = dialogueManager.getDialogue(for: .calm, characterId: currentCharacter.id)
        setupBindings()
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

        // ゲージ増加
        let increase = result.smoothedIntensity * GaugeTuning.increaseMultiplier
        emotionGauge = min(emotionGauge + increase, 100.0)

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

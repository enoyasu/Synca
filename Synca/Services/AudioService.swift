import Foundation
import AVFoundation

/// 状態ごとの効果音・BGM再生サービス
final class AudioService {
    // MARK: - Properties
    var volume: Double = 0.8 {
        didSet { updateVolume() }
    }

    private var audioPlayer: AVAudioPlayer?
    private var lastPlayedState: EmotionState?

    // MARK: - Public

    func playStateSound(for state: EmotionState) {
        // 同じ状態の音は連続再生しない
        guard state != lastPlayedState else { return }
        lastPlayedState = state

        let soundName: String
        switch state {
        case .calm:    soundName = "calm_chime"
        case .excited: soundName = "excited_beat"
        case .special: soundName = "special_fanfare"
        }

        playSound(named: soundName)
    }

    func playTapSound() {
        playSystemSound(id: 1104)
    }

    // MARK: - Private

    private func playSound(named name: String) {
        guard volume > 0 else { return }

        // バンドル内に音声ファイルがある場合に再生
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a") else {
            // ファイルが存在しない場合はシステムサウンドでフォールバック
            playFallbackSound()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = Float(volume)
            audioPlayer?.play()
        } catch {
            playFallbackSound()
        }
    }

    private func playFallbackSound() {
        playSystemSound(id: 1057)
    }

    private func playSystemSound(id: SystemSoundID) {
        guard volume > 0 else { return }
        AudioServicesPlaySystemSound(id)
    }

    private func updateVolume() {
        audioPlayer?.volume = Float(volume)
    }
}

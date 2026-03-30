import SwiftUI

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
    }

    func glowEffect(color: Color, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color, radius: radius / 2)
            .shadow(color: color, radius: radius)
    }
}

// MARK: - Double
extension Double {
    /// 0〜1の範囲にクランプ
    var normalized: Double { max(0, min(1, self)) }
}

// MARK: - Bundle
extension Bundle {
    var shortVersionString: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }

    var buildNumberString: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
    }
}

// MARK: - App Preferences
enum AppPreferenceKey {
    static let appLanguage = "app_language"
    static let gaugeDecayLevel = "gauge_decay_level"
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case japanese = "ja"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .japanese: return "日本語"
        case .english: return "English"
        }
    }
}

enum L10nKey {
    case close
    case live
    case start
    case stop
    case tabCharacter
    case tabSettings
    case characterSelectionTitle
    case characterSelectionHeader
    case purchase
    case cancel
    case unlockCharacterTitle
    case removeAds
    case removeAdsSubtitle
    case processing
    case unlocked
    case settingsTitle
    case sensorSettings
    case audioSettings
    case gaugeSettings
    case appInfo
    case languageSettings
    case sensitivity
    case volume
    case sensitivityPreview
    case gaugeDecaySpeed
    case version
    case build
    case premium
    case premiumEnabled
    case premiumDisabled
    case resetSettings
    case calmState
    case excitedState
    case specialState
    case calmChip
    case excitedChip
    case specialChip
}

enum L10n {
    static func text(_ key: L10nKey, language: AppLanguage) -> String {
        switch (key, language) {
        case (.close, .japanese): return "閉じる"
        case (.close, .english): return "Close"
        case (.live, .japanese): return "LIVE"
        case (.live, .english): return "LIVE"
        case (.start, .japanese): return "START"
        case (.start, .english): return "START"
        case (.stop, .japanese): return "STOP"
        case (.stop, .english): return "STOP"
        case (.tabCharacter, .japanese): return "キャラ"
        case (.tabCharacter, .english): return "CHAR"
        case (.tabSettings, .japanese): return "設定"
        case (.tabSettings, .english): return "SET"
        case (.characterSelectionTitle, .japanese): return "キャラクター選択"
        case (.characterSelectionTitle, .english): return "Characters"
        case (.characterSelectionHeader, .japanese): return "キャラクターを選んで、一緒に楽しもう！"
        case (.characterSelectionHeader, .english): return "Pick your character and have fun together!"
        case (.purchase, .japanese): return "購入"
        case (.purchase, .english): return "Buy"
        case (.cancel, .japanese): return "キャンセル"
        case (.cancel, .english): return "Cancel"
        case (.unlockCharacterTitle, .japanese): return "キャラクターを解放"
        case (.unlockCharacterTitle, .english): return "Unlock Character"
        case (.removeAds, .japanese): return "広告を削除"
        case (.removeAds, .english): return "Remove Ads"
        case (.removeAdsSubtitle, .japanese): return "¥250でずっと広告なし体験"
        case (.removeAdsSubtitle, .english): return "No ads forever for ¥250"
        case (.processing, .japanese): return "処理中..."
        case (.processing, .english): return "Processing..."
        case (.unlocked, .japanese): return "解放済み"
        case (.unlocked, .english): return "Unlocked"
        case (.settingsTitle, .japanese): return "設定"
        case (.settingsTitle, .english): return "Settings"
        case (.sensorSettings, .japanese): return "センサー設定"
        case (.sensorSettings, .english): return "Sensor"
        case (.audioSettings, .japanese): return "オーディオ"
        case (.audioSettings, .english): return "Audio"
        case (.gaugeSettings, .japanese): return "感情ゲージ"
        case (.gaugeSettings, .english): return "Emotion Gauge"
        case (.appInfo, .japanese): return "アプリ情報"
        case (.appInfo, .english): return "App Info"
        case (.languageSettings, .japanese): return "言語"
        case (.languageSettings, .english): return "Language"
        case (.sensitivity, .japanese): return "感度"
        case (.sensitivity, .english): return "Sensitivity"
        case (.volume, .japanese): return "音量"
        case (.volume, .english): return "Volume"
        case (.sensitivityPreview, .japanese): return "感度プレビュー"
        case (.sensitivityPreview, .english): return "Sensitivity Preview"
        case (.gaugeDecaySpeed, .japanese): return "ゲージ減少速度"
        case (.gaugeDecaySpeed, .english): return "Gauge Decay Speed"
        case (.version, .japanese): return "バージョン"
        case (.version, .english): return "Version"
        case (.build, .japanese): return "ビルド"
        case (.build, .english): return "Build"
        case (.premium, .japanese): return "プレミアム"
        case (.premium, .english): return "Premium"
        case (.premiumEnabled, .japanese): return "有効"
        case (.premiumEnabled, .english): return "Enabled"
        case (.premiumDisabled, .japanese): return "無効"
        case (.premiumDisabled, .english): return "Disabled"
        case (.resetSettings, .japanese): return "設定をリセット"
        case (.resetSettings, .english): return "Reset Settings"
        case (.calmState, .japanese): return "通常状態"
        case (.calmState, .english): return "Calm"
        case (.excitedState, .japanese): return "反応強状態"
        case (.excitedState, .english): return "Excited"
        case (.specialState, .japanese): return "特別状態 ✨"
        case (.specialState, .english): return "Special ✨"
        case (.calmChip, .japanese): return "通常"
        case (.calmChip, .english): return "Calm"
        case (.excitedChip, .japanese): return "反応強"
        case (.excitedChip, .english): return "Excite"
        case (.specialChip, .japanese): return "特別"
        case (.specialChip, .english): return "Special"
        }
    }

    static func unlockQuestion(characterName: String, language: AppLanguage) -> String {
        switch language {
        case .japanese: return "\(characterName) を解放しますか？"
        case .english: return "Unlock \(characterName)?"
        }
    }

    static func purchaseWithPrice(_ price: String, language: AppLanguage) -> String {
        switch language {
        case .japanese: return "購入 \(price)"
        case .english: return "Buy \(price)"
        }
    }

    static func sensitivityLabel(_ value: Double, language: AppLanguage) -> String {
        switch language {
        case .japanese:
            switch value {
            case ..<0.5: return "低"
            case ..<1.2: return "標準"
            case ..<2.0: return "高"
            default:     return "最高"
            }
        case .english:
            switch value {
            case ..<0.5: return "Low"
            case ..<1.2: return "Normal"
            case ..<2.0: return "High"
            default:     return "Max"
            }
        }
    }

    static func gaugeDecayValueLabel(level: Int, seconds: Int, language: AppLanguage) -> String {
        switch language {
        case .japanese:
            return "Lv\(level)・約\(seconds)秒"
        case .english:
            return "Lv\(level) • ~\(seconds)s"
        }
    }

    static func gaugeDecayHint(seconds: Int, language: AppLanguage) -> String {
        switch language {
        case .japanese:
            return "振動が止まると、ゲージは約\(seconds)秒で0になります。"
        case .english:
            return "When vibration stops, the gauge drops to zero in about \(seconds)s."
        }
    }

    static func characterDescription(id: String, fallbackJapanese: String, language: AppLanguage) -> String {
        guard language == .english else { return fallbackJapanese }

        switch id {
        case "yuna":
            return "Bright and energetic.\nLoves music and dance."
        case "hana":
            return "Calm and kind.\nLoves nature and flowers."
        case "riku":
            return "Cool and intelligent.\nLoves stars and puzzles."
        case "sora":
            return "Free-spirited and cheerful.\nLoves travel and the sky."
        default:
            return fallbackJapanese
        }
    }
}

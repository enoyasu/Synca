import SwiftUI

/// 感情ゲージ値（0〜100）に基づくキャラクターの状態
enum EmotionState: String, CaseIterable, Equatable {
    case calm    = "calm"    // 0〜30
    case excited = "excited" // 30〜70
    case special = "special" // 70〜100

    init(gauge: Double) {
        switch gauge {
        case 0..<30:  self = .calm
        case 30..<70: self = .excited
        default:      self = .special
        }
    }

    var displayName: String {
        switch self {
        case .calm:    return "通常"
        case .excited: return "反応強"
        case .special: return "特別状態"
        }
    }

    func displayName(for language: AppLanguage) -> String {
        switch self {
        case .calm:
            return language == .japanese ? "通常" : "Calm"
        case .excited:
            return language == .japanese ? "反応強" : "Excited"
        case .special:
            return language == .japanese ? "特別状態" : "Special"
        }
    }

    var primaryColor: Color {
        switch self {
        case .calm:    return Color(hex: "6B9FD4")
        case .excited: return Color(hex: "A855F7")
        case .special: return Color(hex: "F59E0B")
        }
    }

    var secondaryColor: Color {
        switch self {
        case .calm:    return Color(hex: "3B82F6")
        case .excited: return Color(hex: "EC4899")
        case .special: return Color(hex: "EF4444")
        }
    }

    var glowColor: Color {
        switch self {
        case .calm:    return Color.blue.opacity(0.25)
        case .excited: return Color.purple.opacity(0.35)
        case .special: return Color.orange.opacity(0.50)
        }
    }

    var gaugeRange: ClosedRange<Double> {
        switch self {
        case .calm:    return 0...30
        case .excited: return 30...70
        case .special: return 70...100
        }
    }
}

import SwiftUI

/// キャラクターデータモデル（課金拡張対応設計）
struct Character: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let description: String
    let accentColorHex: String
    var isLocked: Bool
    let unlockPrice: String?
    let productID: String?     // StoreKit Product ID（課金用）

    static func == (lhs: Character, rhs: Character) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Character {
    /// アクセントカラー（SwiftUI用）
    var accentColor: Color {
        Color(hex: accentColorHex)
    }

    /// グラデーション（状態ごと）
    func gradient(for state: EmotionState) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: accentColorHex),
                state.primaryColor
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func localizedDescription(for language: AppLanguage) -> String {
        L10n.characterDescription(id: id, fallbackJapanese: description, language: language)
    }
}

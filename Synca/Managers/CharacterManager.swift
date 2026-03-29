import Foundation

/// キャラクターの登録・管理を行うシングルトン
final class CharacterManager {
    static let shared = CharacterManager()

    private(set) var allCharacters: [Character] = []

    var defaultCharacter: Character {
        allCharacters.first(where: { !$0.isLocked }) ?? allCharacters[0]
    }

    private init() {
        registerCharacters()
    }

    // MARK: - Public

    func character(id: String) -> Character? {
        allCharacters.first(where: { $0.id == id })
    }

    func unlock(characterId: String) {
        guard let index = allCharacters.firstIndex(where: { $0.id == characterId }) else { return }
        allCharacters[index].isLocked = false
    }

    // MARK: - Private

    private func registerCharacters() {
        allCharacters = [
            Character(
                id: "yuna",
                name: "Yuna",
                description: "明るく元気なキャラクター。\n音楽とダンスが大好き。",
                accentColorHex: "A78BFA",
                isLocked: false,
                unlockPrice: nil,
                productID: nil
            ),
            Character(
                id: "hana",
                name: "Hana",
                description: "穏やかで優しいキャラクター。\n自然と花が好き。",
                accentColorHex: "34D399",
                isLocked: true,
                unlockPrice: "¥120",
                productID: PurchaseService.ProductID.characterHana
            ),
            Character(
                id: "riku",
                name: "Riku",
                description: "クールで知的なキャラクター。\n星空と謎解きが好き。",
                accentColorHex: "60A5FA",
                isLocked: true,
                unlockPrice: "¥120",
                productID: PurchaseService.ProductID.characterRiku
            ),
            Character(
                id: "sora",
                name: "Sora",
                description: "自由奔放で楽しいキャラクター。\n旅と空が好き。",
                accentColorHex: "F472B6",
                isLocked: true,
                unlockPrice: "¥250",
                productID: PurchaseService.ProductID.characterSora
            )
        ]
    }
}

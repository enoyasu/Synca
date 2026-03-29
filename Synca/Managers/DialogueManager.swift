import Foundation

/// キャラクターごと・状態ごとのセリフを管理するクラス
final class DialogueManager {
    // 最後に表示したセリフのインデックスを記録（重複防止）
    private var lastIndices: [String: Int] = [:]

    // MARK: - Dialogue Database
    private let dialogues: [String: [EmotionState: [String]]] = [
        // ─────────────────────────────────────
        // Yuna
        // ─────────────────────────────────────
        "yuna": [
            .calm: [
                "こんにちは！今日も一緒に楽しもうね",
                "ゆっくりしていていいよ",
                "リラックスしてる？",
                "何か面白いことしようか？",
                "今日はどんな気分？",
                "ちょっとだけ動いてみてよ！"
            ],
            .excited: [
                "なんだか楽しいね！",
                "いいリズムだね！",
                "もう少し続けてみる？",
                "すごい！その調子！",
                "テンション上がってきた！",
                "一緒に動くの楽しい！",
                "もっと感じて！"
            ],
            .special: [
                "最高！！",
                "このリズム、好きかも！",
                "一緒に盛り上がろう！",
                "すごいエネルギー！",
                "もっと！もっと！",
                "この感じ、最高だよ！！"
            ]
        ],
        // ─────────────────────────────────────
        // Hana
        // ─────────────────────────────────────
        "hana": [
            .calm: [
                "穏やかでいいね",
                "自然の風みたいだね",
                "ゆっくり流れていこうか",
                "今日も優しい時間だね",
                "一緒にいると落ち着くよ"
            ],
            .excited: [
                "花が咲くみたいに嬉しい！",
                "その動き、素敵だよ",
                "気持ちよくなってきた！",
                "もっと動いてみよう！",
                "風に乗ってるみたいだね"
            ],
            .special: [
                "満開！！",
                "最高に気持ちいい！",
                "一緒に踊ろう！",
                "こんなに楽しいなんて！",
                "もっと一緒にいたい！"
            ]
        ],
        // ─────────────────────────────────────
        // Riku
        // ─────────────────────────────────────
        "riku": [
            .calm: [
                "静かな夜みたいだね",
                "落ち着いている...",
                "星を見ているみたい",
                "今日も穏やかだね",
                "ゆっくり過ごそう"
            ],
            .excited: [
                "面白くなってきた",
                "データが反応している",
                "いいパターンだ",
                "その調子で続けよう",
                "リズムが整ってきた"
            ],
            .special: [
                "完璧なシンクロ！",
                "最大値を超えた！",
                "これは特別なデータだ",
                "一緒に記録を作ろう",
                "この瞬間を覚えておく"
            ]
        ],
        // ─────────────────────────────────────
        // Sora
        // ─────────────────────────────────────
        "sora": [
            .calm: [
                "どこへでも行けそうだね",
                "空みたいに自由だよ",
                "旅の始まりかな？",
                "風が気持ちいいね",
                "ゆっくり行こうか"
            ],
            .excited: [
                "冒険が始まった！",
                "どんどん進もう！",
                "楽しい旅になりそう！",
                "一緒に探検しよう！",
                "新しいことが見えてきた！"
            ],
            .special: [
                "最高の冒険！！",
                "どこまでも飛んでいける！",
                "一緒に空を超えよう！",
                "最高のパートナーだよ！",
                "この景色、最高だね！"
            ]
        ]
    ]

    // MARK: - Public

    /// 指定キャラクター・状態に対応するセリフを返す
    func getDialogue(for state: EmotionState, characterId: String) -> String {
        guard let charDialogues = dialogues[characterId],
              let stateLines = charDialogues[state],
              !stateLines.isEmpty else {
            return "..."
        }

        let key = "\(characterId)-\(state.rawValue)"
        let lastIndex = lastIndices[key] ?? -1

        let newIndex: Int
        if stateLines.count == 1 {
            newIndex = 0
        } else {
            var candidate: Int
            repeat {
                candidate = Int.random(in: 0..<stateLines.count)
            } while candidate == lastIndex
            newIndex = candidate
        }

        lastIndices[key] = newIndex
        return stateLines[newIndex]
    }
}

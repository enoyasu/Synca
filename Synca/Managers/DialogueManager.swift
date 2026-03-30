import Foundation

/// キャラクターごと・状態ごとのセリフを管理するクラス
final class DialogueManager {
    // 最後に表示したセリフのインデックスを記録（重複防止）
    private var lastIndices: [String: Int] = [:]

    // MARK: - Dialogue Database
    private let japaneseDialogues: [String: [EmotionState: [String]]] = [
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

    private let englishDialogues: [String: [EmotionState: [String]]] = [
        "yuna": [
            .calm: [
                "Hi there! Let's have fun today.",
                "Take it easy, no rush.",
                "Feeling relaxed?",
                "Want to try something fun?",
                "How are you feeling today?",
                "Try moving a little!"
            ],
            .excited: [
                "This is getting fun!",
                "Great rhythm!",
                "Want to keep going?",
                "Awesome! Keep it up!",
                "Your energy is rising!",
                "Moving together feels great!",
                "Feel it more!"
            ],
            .special: [
                "Amazing!!",
                "I love this rhythm!",
                "Let's hype it up together!",
                "What incredible energy!",
                "More! More!",
                "This feeling is the best!!"
            ]
        ],
        "hana": [
            .calm: [
                "So calm and gentle.",
                "Like a soft breeze.",
                "Let's go with the flow.",
                "Such a peaceful moment.",
                "I feel calm with you."
            ],
            .excited: [
                "It feels like flowers blooming!",
                "That movement is lovely.",
                "This feels so good!",
                "Let's move a bit more!",
                "Feels like riding the wind."
            ],
            .special: [
                "In full bloom!!",
                "This feels incredible!",
                "Let's dance together!",
                "I didn't expect this much fun!",
                "Stay with me a little longer!"
            ]
        ],
        "riku": [
            .calm: [
                "It's like a quiet night.",
                "Very stable...",
                "Like watching the stars.",
                "A calm day again.",
                "Let's take it slow."
            ],
            .excited: [
                "Now this is interesting.",
                "The data is reacting.",
                "Nice pattern.",
                "Keep this pace going.",
                "The rhythm is locking in."
            ],
            .special: [
                "Perfect sync!",
                "We've exceeded the limit!",
                "This is special data.",
                "Let's set a record together.",
                "I'll remember this moment."
            ]
        ],
        "sora": [
            .calm: [
                "Feels like we can go anywhere.",
                "As free as the sky.",
                "Is this the start of a journey?",
                "The wind feels nice.",
                "Let's go slowly."
            ],
            .excited: [
                "Adventure has started!",
                "Let's keep moving forward!",
                "This trip is getting fun!",
                "Let's explore together!",
                "I can see something new ahead!"
            ],
            .special: [
                "Best adventure ever!!",
                "We can fly anywhere!",
                "Let's go beyond the sky!",
                "You're the best partner!",
                "This view is incredible!"
            ]
        ]
    ]

    // MARK: - Public

    /// 指定キャラクター・状態に対応するセリフを返す
    func getDialogue(for state: EmotionState, characterId: String, language: AppLanguage = .japanese) -> String {
        let source = language == .english ? englishDialogues : japaneseDialogues
        guard let charDialogues = source[characterId],
              let stateLines = charDialogues[state],
              !stateLines.isEmpty else {
            return "..."
        }

        let key = "\(language.rawValue)-\(characterId)-\(state.rawValue)"
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

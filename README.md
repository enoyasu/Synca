# Synca 🌊

**センサー連動キャラクターインタラクションアプリ**

スマートフォンの加速度・ジャイロセンサーに応じて、キャラクター「Yuna」がリアルタイムに感情表現を変化させるインタラクティブ体験アプリ。

---

## 📱 スクリーンショット

| 通常状態 | 反応強状態 | 特別状態 |
|:---:|:---:|:---:|
| ゲージ 0〜30 | ゲージ 30〜70 | ゲージ 70〜100 |

---

## ✨ 機能一覧

### コア機能
- **リアルタイムセンサー取得** — CoreMotion（加速度 / ジャイロ）を30Hzで取得
- **動き解析ロジック** — 強度・テンポ・ピーク検出を独自アルゴリズムで算出
- **感情ゲージシステム** — 0〜100のゲージ。自然な増減・状態遷移
- **キャラクターアニメーション** — 純SwiftUIで実装された「Yuna」が表情・モーション・セリフを変化

### 状態システム
| ゲージ値 | 状態 | キャラクター反応 |
|:---:|:---:|:---|
| 0〜30 | 通常 | 穏やかな表情・日常セリフ |
| 30〜70 | 反応強 | 笑顔・音符エフェクト・テンションセリフ |
| 70〜100 | 特別状態 | 最大の笑顔・星エフェクト・興奮セリフ |

### UI / UX
- ダークモード対応のモダン・ミニマルデザイン
- グラスモーフィズムカード
- 状態連動のダイナミック背景グラデーション
- ゲージのシマーアニメーション

### キャラクター（将来課金対応）
| キャラ | カラー | 状態 | 価格 |
|:---:|:---:|:---:|:---:|
| Yuna | 紫 | 解放済み | 無料 |
| Hana | 緑 | ロック中 | ¥120 |
| Riku | 青 | ロック中 | ¥120 |
| Sora | ピンク | ロック中 | ¥250 |

---

## 🏗 アーキテクチャ

```
Synca/
├── App/
│   ├── SyncaApp.swift          # エントリーポイント（@main）
│   └── ContentView.swift       # ルートビュー
├── Models/
│   ├── Character.swift         # キャラクターデータモデル
│   ├── EmotionState.swift      # 感情状態enum（calm/excited/special）
│   └── MotionData.swift        # センサーデータ構造体
├── ViewModels/
│   ├── MainViewModel.swift     # 全状態管理（MVVM中枢）
│   └── MotionAnalyzer.swift    # 動き解析ロジック
├── Services/
│   ├── MotionService.swift     # CoreMotionラッパー（Combine）
│   ├── AudioService.swift      # AVFoundation音声再生
│   └── PurchaseService.swift   # StoreKit 2 課金管理
├── Managers/
│   ├── CharacterManager.swift  # キャラクター登録・管理
│   └── DialogueManager.swift   # セリフ管理（状態別・重複防止）
├── Views/
│   ├── Main/
│   │   ├── MainView.swift              # メイン画面
│   │   ├── CharacterView.swift         # キャラクターアニメーション
│   │   ├── EmotionGaugeView.swift      # 感情ゲージUI
│   │   └── ControlPanelView.swift      # START/STOP・操作パネル
│   ├── Character/
│   │   ├── CharacterSelectionView.swift  # キャラクター選択シート
│   │   └── CharacterCardView.swift       # キャラクターカード
│   ├── Settings/
│   │   └── SettingsView.swift          # 設定画面（感度・音量）
│   └── Common/
│       ├── Extensions.swift            # Color(hex:)・ViewModifier等
│       ├── CustomButton.swift          # 再利用可能ボタン
│       └── AdBannerView.swift          # AdMobバナー（UIViewRepresentable）
└── Resources/
    ├── Info.plist              # NSMotionUsageDescription等
    └── Assets.xcassets         # アイコン・カラー
```

### 設計パターン
- **MVVM** — View ↔ ViewModel（ObservableObject + @Published）
- **Combine** — センサーデータのリアクティブパイプライン
- **Single Responsibility** — Service / Manager / ViewModel を明確分離
- **Dependency Injection** — EnvironmentObject によるVMアクセス

---

## 🚀 セットアップ

### 必要環境
- Xcode 16.0+
- iOS 17.0+
- Swift 5.9+
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

### ビルド手順

```bash
# リポジトリをクローン
git clone https://github.com/enoyasu/Synca.git
cd Synca

# Xcodeプロジェクト生成（初回・project.yml変更時）
xcodegen generate

# Xcodeで開く
open Synca.xcodeproj
```

### AdMob SDK の追加（オプション）

```bash
# Podfileのコメントを外す
# pod 'Google-Mobile-Ads-SDK'

pod install
open Synca.xcworkspace
```

---

## 📡 センサー実装詳細

### CoreMotion フロー
```
CMDeviceMotion (30Hz)
    → MotionService (Combine @Published)
        → MainViewModel.processMotion()
            → MotionAnalyzer.analyze()
                → intensity (0〜1)
                → tempo (BPM)
                → isPeak (Bool)
            → emotionGauge 更新
            → EmotionState 遷移
            → CharacterAnimationState 更新
```

### ゲージ制御
| パラメータ | 値 | 説明 |
|:---|:---:|:---|
| 増加倍率 | ×18 | intensity × 18 でゲージ増加 |
| 減衰速度 | 0.5/tick | 100msごとに0.5減少 |
| 最大値 | 100 | 上限クランプ |

---

## 💰 課金設計（StoreKit 2）

| Product ID | 内容 | 価格 |
|:---|:---|:---:|
| `com.synca.app.removeads` | 広告削除 | ¥250 |
| `com.synca.app.character.hana` | Hana解放 | ¥120 |
| `com.synca.app.character.riku` | Riku解放 | ¥120 |
| `com.synca.app.character.sora` | Sora解放 | ¥250 |

---

## 🛡 App Store審査対応

- **性的・成人向け要素なし** — 全セリフ・ビジュアルを健全設計
- **NSMotionUsageDescription** — 日本語でのセンサー使用説明を記載
- **センサー使用目的が明確** — キャラクターインタラクションのみ
- **課金はApple公式StoreKit 2使用**
- **広告はAdMob（Googleポリシー準拠）**

---

## 🔧 今後の拡張予定

- [ ] 追加キャラクター（Hana / Riku / Sora）のアニメーション実装
- [ ] BGM・効果音アセットの追加
- [ ] ウィジェット対応
- [ ] Apple Watch コンパニオンアプリ
- [ ] シェア機能（感情ピーク瞬間のスクショ共有）
- [ ] ランキング機能（リズムスコア）

---

## 📄 ライセンス

MIT License © 2024 Synca

---

*Syncaは健全なエンターテイメントアプリです。App Store審査基準を最優先に設計されています。*

import SwiftUI

/// キャラクター選択画面の個別カード
struct CharacterCardView: View {
    let character: Character
    let isSelected: Bool
    let onTap: () -> Void
    let onPurchase: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: {
            if character.isLocked {
                onPurchase()
            } else {
                onTap()
            }
        }) {
            ZStack {
                // カード背景
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: character.accentColorHex).opacity(0.3),
                                Color(hex: character.accentColorHex).opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected
                                    ? Color(hex: character.accentColorHex)
                                    : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    )

                // コンテンツ
                VStack(spacing: 14) {
                    // キャラクターアイコン
                    characterIcon

                    // 名前・説明
                    VStack(spacing: 4) {
                        Text(character.name)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text(character.description)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }

                    // ロック状態バッジ
                    lockBadge
                }
                .padding(16)

                // 選択中チェック
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: character.accentColorHex))
                                .background(Circle().fill(Color.white).padding(3))
                        }
                        Spacer()
                    }
                    .padding(10)
                }

                // ロックオーバーレイ
                if character.isLocked {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.35))
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .shadow(
            color: isSelected
                ? Color(hex: character.accentColorHex).opacity(0.4)
                : Color.clear,
            radius: 16, y: 6
        )
        .animation(.spring(response: 0.3), value: isSelected)
    }

    // MARK: - Character Icon

    private var characterIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: character.accentColorHex),
                            Color(hex: character.accentColorHex).opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)

            // 顔（簡易）
            ZStack {
                // 目
                HStack(spacing: 14) {
                    ForEach(0..<2, id: \.self) { _ in
                        Ellipse()
                            .fill(Color.white)
                            .frame(width: 13, height: 15)
                            .overlay(
                                Circle()
                                    .fill(Color(hex: "1a1a2e"))
                                    .frame(width: 7, height: 7)
                                    .offset(y: 2)
                            )
                    }
                }
                .offset(y: -8)

                // 口
                Path { path in
                    path.move(to: CGPoint(x: -10, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: 10, y: 0),
                        control: CGPoint(x: 0, y: 7)
                    )
                }
                .stroke(Color.white.opacity(0.9),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 20, height: 8)
                .offset(y: 10)
            }

            // ロックアイコン
            if character.isLocked {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 72, height: 72)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }

    // MARK: - Lock Badge

    private var lockBadge: some View {
        Group {
            if character.isLocked {
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                    Text(character.unlockPrice ?? "¥120")
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "F59E0B"),
                                    Color(hex: "D97706")
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            } else {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "10B981"))
                        .frame(width: 7, height: 7)
                    Text("解放済み")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "10B981"))
                }
            }
        }
    }
}

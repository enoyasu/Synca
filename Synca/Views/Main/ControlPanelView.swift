import SwiftUI

/// 画面下部のコントロールパネル（START/STOP・キャラ選択・設定）
struct ControlPanelView: View {
    @EnvironmentObject var viewModel: MainViewModel

    var body: some View {
        VStack(spacing: 16) {
            // セリフ吹き出し
            dialogueBubble

            // メインコントロール
            HStack(spacing: 12) {
                // キャラクター選択
                IconButton(
                    icon: "person.2.fill",
                    label: "キャラ",
                    color: Color(hex: "A78BFA")
                ) {
                    viewModel.presentCharacterSelection()
                }

                // START / STOP メインボタン
                startStopButton
                    .frame(maxWidth: .infinity)

                // 設定
                IconButton(
                    icon: "slider.horizontal.3",
                    label: "設定",
                    color: Color(hex: "60A5FA")
                ) {
                    viewModel.presentSettings()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Dialogue Bubble

    private var dialogueBubble: some View {
        HStack(spacing: 12) {
            // キャラアイコン
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: viewModel.currentCharacter.accentColorHex),
                            viewModel.currentCharacter.accentColor.opacity(0.5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(viewModel.currentCharacter.name.prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )

            // セリフテキスト
            Text(viewModel.currentDialogue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
                .minimumScaleFactor(0.9)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: viewModel.currentDialogue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 16)
        .onTapGesture {
            viewModel.refreshDialogue()
        }
    }

    // MARK: - Start / Stop Button

    private var startStopButton: some View {
        Button {
            viewModel.toggleSession()
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Image(systemName: viewModel.isRunning ? "stop.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: viewModel.isRunning ? 0 : 1)
                }

                Text(viewModel.isRunning ? "STOP" : "START")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: startStopColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: (viewModel.isRunning ? Color.red : Color(hex: "A78BFA")).opacity(0.4),
                    radius: 12, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring(response: 0.3), value: viewModel.isRunning)
    }

    private var startStopColors: [Color] {
        viewModel.isRunning
            ? [Color(hex: "EF4444"), Color(hex: "DC2626")]
            : [Color(hex: "A78BFA"), Color(hex: "7C3AED")]
    }
}

#Preview {
    ZStack {
        Color(hex: "0D0D1A").ignoresSafeArea()
        VStack {
            Spacer()
            ControlPanelView()
                .environmentObject(MainViewModel())
        }
    }
}

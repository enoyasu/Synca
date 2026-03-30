import SwiftUI

/// 画面下部のコントロールパネル（START/STOP・キャラ選択・設定）
struct ControlPanelView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @AppStorage(AppPreferenceKey.appLanguage) private var appLanguageRaw = AppLanguage.japanese.rawValue
    let horizontalPadding: CGFloat
    let sideButtonWidth: CGFloat
    let layoutWidth: CGFloat

    init(horizontalPadding: CGFloat = 20, sideButtonWidth: CGFloat = 64, layoutWidth: CGFloat = 390) {
        self.horizontalPadding = horizontalPadding
        self.sideButtonWidth = sideButtonWidth
        self.layoutWidth = layoutWidth
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .japanese
    }

    var body: some View {
        VStack(spacing: 16) {
            // セリフ吹き出し
            dialogueBubble

            // メインコントロール
            controlButtons
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var controlButtons: some View {
        if layoutWidth < 370 {
            stackedButtons
        } else {
            ViewThatFits(in: .horizontal) {
                compactRowButtons
                stackedButtons
            }
        }
    }

    private var compactRowButtons: some View {
        HStack(spacing: sideButtonWidth < 60 ? 8 : 12) {
            characterButton(width: sideButtonWidth)
            startStopButton
                .frame(maxWidth: .infinity)
            settingsButton(width: sideButtonWidth)
        }
    }

    private var stackedButtons: some View {
        VStack(spacing: 8) {
            startStopButton

            HStack(spacing: 8) {
                characterButton(width: nil)
                    .frame(maxWidth: .infinity)
                settingsButton(width: nil)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Dialogue Bubble

    private var dialogueBubble: some View {
        let isCompactWidth = layoutWidth < 330
        let isMediumWidth = layoutWidth < 400
        let dialogueLineLimit = isCompactWidth ? 6 : (isMediumWidth ? 4 : 3)
        let iconSize: CGFloat = isCompactWidth ? 30 : 32

        return HStack(spacing: 12) {
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
                .frame(width: iconSize, height: iconSize)
                .overlay(
                    Text(String(viewModel.currentCharacter.name.prefix(1)))
                        .font(.system(size: isCompactWidth ? 13 : 14, weight: .bold))
                        .foregroundColor(.white)
                )

            // セリフテキスト
            Text(viewModel.currentDialogue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(dialogueLineLimit)
                .minimumScaleFactor(isCompactWidth ? 0.82 : 0.9)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: viewModel.currentDialogue)
        }
        .padding(.horizontal, isCompactWidth ? 12 : 14)
        .padding(.vertical, 10)
        .frame(minHeight: isCompactWidth ? 76 : 64, alignment: .leading)
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

                Text(startStopLabel)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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

    @ViewBuilder
    private func characterButton(width: CGFloat?) -> some View {
        IconButton(
            icon: "person.2.fill",
            label: L10n.text(.tabCharacter, language: language),
            color: Color(hex: "A78BFA"),
            width: width
        ) {
            viewModel.presentCharacterSelection()
        }
    }

    @ViewBuilder
    private func settingsButton(width: CGFloat?) -> some View {
        IconButton(
            icon: "slider.horizontal.3",
            label: L10n.text(.tabSettings, language: language),
            color: Color(hex: "60A5FA"),
            width: width
        ) {
            viewModel.presentSettings()
        }
    }

    private var startStopLabel: String {
        viewModel.isRunning
            ? L10n.text(.stop, language: language)
            : L10n.text(.start, language: language)
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

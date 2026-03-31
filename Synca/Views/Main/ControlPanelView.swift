import SwiftUI

/// 画面下部のコントロールパネル（START/STOP・キャラ選択・設定）
struct ControlPanelView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @AppStorage(AppPreferenceKey.appLanguage) private var appLanguageRaw = AppLanguage.japanese.rawValue
    let horizontalPadding: CGFloat
    let layoutWidth: CGFloat
    let compactMode: Bool

    init(horizontalPadding: CGFloat = 20, layoutWidth: CGFloat = 390, compactMode: Bool = false) {
        self.horizontalPadding = horizontalPadding
        self.layoutWidth = layoutWidth
        self.compactMode = compactMode
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .japanese
    }

    private var isCompactWidth: Bool {
        layoutWidth < 360 || compactMode
    }

    private var sectionSpacing: CGFloat { 12 }

    var body: some View {
        if compactMode {
            compactLandscapeContent
        } else {
            VStack(spacing: sectionSpacing) {
                dialogueBubble
                controlButtons
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var controlButtons: some View {
        portraitButtons
    }

    private var compactLandscapeContent: some View {
        GeometryReader { geo in
            // spacing・各セクション高さをコンパクトにし、合計が availableHeight を超えないようにする
            // 旧値: spacing=8, dialogue=64, action=58, minStart=48 → min合計186pt でオーバーフロー
            // 新値: spacing=6, dialogue=56, action=50, minStart=36 → min合計148pt に削減
            let spacing: CGFloat = 6
            let dialogueHeight: CGFloat = 56
            let actionRowHeight: CGFloat = 50
            let availableHeight = max(geo.size.height, 0)
            let startHeight = max(availableHeight - dialogueHeight - actionRowHeight - spacing * 2, 36)

            VStack(spacing: spacing) {
                dialogueBubble
                    .frame(height: dialogueHeight, alignment: .center)

                HStack(spacing: 10) {
                    characterButton(width: nil)
                        .frame(maxWidth: .infinity)
                    settingsButton(width: nil)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: actionRowHeight)

                startStopButton(height: startHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, horizontalPadding)
        }
    }

    private var portraitButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                characterButton(width: nil)
                    .frame(maxWidth: .infinity)
                settingsButton(width: nil)
                    .frame(maxWidth: .infinity)
            }

            startStopButton(height: 60)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dialogueBubble: some View {
        let dialogueLineLimit = compactMode ? 2 : (isCompactWidth ? 6 : (layoutWidth < 400 ? 4 : 3))
        let iconSize: CGFloat = isCompactWidth ? 30 : 32

        return HStack(alignment: .center, spacing: 12) {
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

            Text(viewModel.currentDialogue)
                .font(.system(size: compactMode ? 14 : 15, weight: .medium))
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
        .padding(.vertical, compactMode ? 8 : 10)
        .frame(maxWidth: .infinity, minHeight: compactMode ? 52 : (isCompactWidth ? 78 : 68), alignment: .leading)
        .glassCard(cornerRadius: 16)
        .onTapGesture {
            viewModel.refreshDialogue()
        }
    }

    private func startStopButton(height: CGFloat) -> some View {
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
            .frame(height: height)
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
            .shadow(
                color: (viewModel.isRunning ? Color.red : Color(hex: "A78BFA")).opacity(0.4),
                radius: 12,
                y: 4
            )
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

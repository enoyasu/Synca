import SwiftUI

/// アプリのメイン画面
struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel

    // MARK: - Background animation
    @State private var bgRotation: Double = 0
    @State private var bgScale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .top) {
            // ─── 背景 ───
            backgroundLayer

            GeometryReader { proxy in
                let isCompactHeight = proxy.size.height < 760
                let isNarrowWidth = proxy.size.width < 360
                let horizontalPadding: CGFloat = isNarrowWidth ? 14 : 20
                let characterHeight: CGFloat = isCompactHeight ? 220 : 280
                let sideButtonWidth: CGFloat = isNarrowWidth ? 56 : 64
                let topInset = max(proxy.safeAreaInsets.top, 8)
                let bottomInset = max(proxy.safeAreaInsets.bottom, 12)
                let contentMinHeight = max(proxy.size.height - topInset - bottomInset, 0)

                ScrollView(.vertical, showsIndicators: isCompactHeight) {
                    VStack(spacing: 0) {
                        // 上部：AdMobバナー
                        AdBannerView(isHidden: viewModel.isPremium)

                        // ヘッダー
                        headerBar(isNarrowWidth: isNarrowWidth)
                            .padding(.horizontal, horizontalPadding)
                            .padding(.top, 8)

                        // キャラクター
                        CharacterView(
                            character: viewModel.currentCharacter,
                            state: viewModel.emotionState,
                            animationState: viewModel.characterAnimationState,
                            gauge: viewModel.emotionGauge
                        )
                        .frame(height: characterHeight)
                        .padding(.top, isCompactHeight ? 8 : 24)

                        // 感情ゲージ
                        EmotionGaugeView(
                            gauge: viewModel.emotionGauge,
                            state: viewModel.emotionState
                        )
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, isCompactHeight ? 8 : 16)

                        // コントロールパネル
                        ControlPanelView(
                            horizontalPadding: horizontalPadding,
                            sideButtonWidth: sideButtonWidth
                        )
                            .padding(.top, isCompactHeight ? 6 : 12)
                    }
                    .padding(.top, topInset)
                    .frame(minHeight: contentMinHeight, alignment: .top)
                    .padding(.bottom, bottomInset)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                bgRotation = 360
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                bgScale = 1.08
            }
        }
        .sheet(isPresented: $viewModel.showCharacterSelection) {
            CharacterSelectionView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView()
                .environmentObject(viewModel)
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            // ベースカラー
            Color(hex: "0A0A1A")

            // ダイナミックグラデーション球
            Circle()
                .fill(viewModel.emotionState.primaryColor.opacity(0.12))
                .frame(width: 500, height: 500)
                .blur(radius: 80)
                .offset(x: -100, y: -200)
                .rotationEffect(.degrees(bgRotation))
                .scaleEffect(bgScale)

            Circle()
                .fill(viewModel.emotionState.secondaryColor.opacity(0.08))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: 120, y: 100)
                .rotationEffect(.degrees(-bgRotation * 0.7))
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 1.5), value: viewModel.emotionState)
    }

    // MARK: - Header

    private func headerBar(isNarrowWidth: Bool) -> some View {
        HStack(spacing: isNarrowWidth ? 8 : 12) {
            // アプリロゴ
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "A78BFA"),
                                    Color(hex: "7C3AED")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 30, height: 30)
                    Image(systemName: "waveform")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("Synca")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .layoutPriority(1)

            Spacer(minLength: isNarrowWidth ? 6 : 10)

            // 現在キャラ名
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.currentCharacter.accentColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: viewModel.currentCharacter.accentColor, radius: 4)
                Text(viewModel.currentCharacter.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .layoutPriority(1)
                    .frame(maxWidth: isNarrowWidth ? 88 : 140, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassCard(cornerRadius: 12)

            // セッション状態インジケーター
            if viewModel.isRunning && !isNarrowWidth {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "10B981"))
                        .frame(width: 6, height: 6)
                        .shadow(color: Color(hex: "10B981"), radius: 4)
                    Text("LIVE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "10B981"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .glassCard(cornerRadius: 10)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.isRunning)
    }
}

#Preview("iPhone 16") {
    MainView()
        .environmentObject(MainViewModel())
        .preferredColorScheme(.dark)
}

#Preview("iPhone 16 Pro Max") {
    MainView()
        .environmentObject(MainViewModel())
        .preferredColorScheme(.dark)
}

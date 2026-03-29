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

            // ─── コンテンツ ───
            VStack(spacing: 0) {
                // 上部：AdMobバナー
                AdBannerView(isHidden: viewModel.isPremium)

                // ヘッダー
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer()

                // キャラクター
                CharacterView(
                    character: viewModel.currentCharacter,
                    state: viewModel.emotionState,
                    animationState: viewModel.characterAnimationState,
                    gauge: viewModel.emotionGauge
                )
                .frame(height: 280)

                Spacer(minLength: 20)

                // 感情ゲージ
                EmotionGaugeView(
                    gauge: viewModel.emotionGauge,
                    state: viewModel.emotionState
                )
                .padding(.horizontal, 20)

                // コントロールパネル
                ControlPanelView()
                    .padding(.top, 12)

                // ホームインジケーター用スペーサー
                Spacer(minLength: 8)
            }
        }
        .ignoresSafeArea(edges: .top)
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

    private var headerBar: some View {
        HStack {
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
            }

            Spacer()

            // 現在キャラ名
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.currentCharacter.accentColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: viewModel.currentCharacter.accentColor, radius: 4)
                Text(viewModel.currentCharacter.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassCard(cornerRadius: 12)

            // セッション状態インジケーター
            if viewModel.isRunning {
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

#Preview {
    MainView()
        .environmentObject(MainViewModel())
        .preferredColorScheme(.dark)
}

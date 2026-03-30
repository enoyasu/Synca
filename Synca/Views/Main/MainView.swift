import SwiftUI

/// アプリのメイン画面
struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @AppStorage(AppPreferenceKey.appLanguage) private var appLanguageRaw = AppLanguage.japanese.rawValue

    // MARK: - Background animation
    @State private var bgRotation: Double = 0
    @State private var bgScale: CGFloat = 1.0

    private var language: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .japanese
    }

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { proxy in
                let isCompactHeight = proxy.size.height < 760
                let width = proxy.size.width
                let contentLeftOffset: CGFloat = -20
                let horizontalPadding: CGFloat = width < 360 ? 10 : (width < 420 ? 12 : 16)
                let characterHeight: CGFloat = isCompactHeight
                    ? (width < 360 ? 200 : 220)
                    : (width < 360 ? 250 : 280)
                let availableWidth = max(width - horizontalPadding * 2, 0)
                let contentWidth: CGFloat = width > 700 ? min(availableWidth, 400) : min(availableWidth, 440)
                let sideButtonWidth: CGFloat = contentWidth < 300 ? 42 : (contentWidth < 340 ? 44 : (contentWidth < 380 ? 48 : 56))
                let topInset = max(proxy.safeAreaInsets.top, 8)
                let bottomInset = max(proxy.safeAreaInsets.bottom, 12)
                let contentMinHeight = max(proxy.size.height - topInset - bottomInset, 0)

                ZStack(alignment: .top) {
                    backgroundLayer(
                        containerWidth: width,
                        containerHeight: proxy.size.height
                    )

                    ScrollView(.vertical, showsIndicators: isCompactHeight) {
                        VStack(spacing: 0) {
                            // 上部：AdMobバナー
                            AdBannerView(isHidden: viewModel.isPremium)

                            // ヘッダー
                            headerBar(layoutWidth: contentWidth, language: language)
                                .frame(maxWidth: contentWidth)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 8)

                            // キャラクター
                            CharacterView(
                                character: viewModel.currentCharacter,
                                state: viewModel.emotionState,
                                animationState: viewModel.characterAnimationState,
                                gauge: viewModel.emotionGauge,
                                layoutWidth: contentWidth
                            )
                            .frame(height: characterHeight)
                            .frame(maxWidth: contentWidth)
                            .frame(maxWidth: .infinity)
                            .padding(.top, isCompactHeight ? 8 : 24)

                            // 感情ゲージ
                            EmotionGaugeView(
                                gauge: viewModel.emotionGauge,
                                state: viewModel.emotionState,
                                layoutWidth: contentWidth,
                                pulseTrigger: viewModel.gaugePulseTrigger,
                                pulseStrength: viewModel.gaugePulseStrength
                            )
                            .frame(maxWidth: contentWidth)
                            .frame(maxWidth: .infinity)
                            .padding(.top, isCompactHeight ? 8 : 16)

                            // コントロールパネル
                            ControlPanelView(
                                horizontalPadding: 0,
                                sideButtonWidth: sideButtonWidth,
                                layoutWidth: contentWidth
                            )
                                .frame(maxWidth: contentWidth)
                                .frame(maxWidth: .infinity)
                                .padding(.top, isCompactHeight ? 6 : 12)
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, topInset)
                        .offset(x: contentLeftOffset)
                        .frame(minHeight: contentMinHeight, alignment: .top)
                        .padding(.bottom, bottomInset)
                    }
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

    private func backgroundLayer(containerWidth: CGFloat, containerHeight: CGFloat) -> some View {
        let orbBase = max(containerWidth, containerHeight)
        let primarySize = min(max(orbBase * 0.88, 280), 520)
        let secondarySize = min(max(orbBase * 0.7, 220), 430)

        return ZStack {
            // ベースカラー
            Color(hex: "0A0A1A")

            // ダイナミックグラデーション球
            Circle()
                .fill(viewModel.emotionState.primaryColor.opacity(0.12))
                .frame(width: primarySize, height: primarySize)
                .blur(radius: 80)
                .offset(x: -containerWidth * 0.28, y: -containerHeight * 0.28)
                .rotationEffect(.degrees(bgRotation))
                .scaleEffect(bgScale)

            Circle()
                .fill(viewModel.emotionState.secondaryColor.opacity(0.08))
                .frame(width: secondarySize, height: secondarySize)
                .blur(radius: 60)
                .offset(x: containerWidth * 0.32, y: containerHeight * 0.14)
                .rotationEffect(.degrees(-bgRotation * 0.7))
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 1.5), value: viewModel.emotionState)
    }

    // MARK: - Header

    private func headerBar(layoutWidth: CGFloat, language: AppLanguage) -> some View {
        let isCompactWidth = layoutWidth < 330
        let isMediumWidth = layoutWidth < 390
        let characterMaxWidth = max(
            min(layoutWidth * (isCompactWidth ? 0.26 : (isMediumWidth ? 0.30 : 0.36)), 170),
            52
        )

        return VStack(spacing: 8) {
            HStack(spacing: isCompactWidth ? 8 : 12) {
                // アプリロゴ
                HStack(spacing: 6) {
                    Image("BrandIcon")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.8)
                        )
                    Text("Synca")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .layoutPriority(1)

                Spacer(minLength: isCompactWidth ? 4 : 8)

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
                        .minimumScaleFactor(0.7)
                        .layoutPriority(1)
                        .frame(maxWidth: characterMaxWidth, alignment: .leading)
                }
                .padding(.horizontal, isCompactWidth ? 10 : 12)
                .padding(.vertical, 6)
                .glassCard(cornerRadius: 12)

                // 横幅に余裕がある場合のみ同列でLIVE表示
                if viewModel.isRunning && !isMediumWidth {
                    liveIndicator(showText: true, language: language)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // 中〜狭幅ではLIVEを2行目に逃して見切れを防止
            if viewModel.isRunning && isMediumWidth {
                HStack {
                    Spacer()
                    liveIndicator(showText: !isCompactWidth, language: language)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.isRunning)
    }

    private func liveIndicator(showText: Bool, language: AppLanguage) -> some View {
        HStack(spacing: showText ? 4 : 0) {
            Circle()
                .fill(Color(hex: "10B981"))
                .frame(width: 6, height: 6)
                .shadow(color: Color(hex: "10B981"), radius: 4)
            if showText {
                Text(L10n.text(.live, language: language))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "10B981"))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, showText ? 10 : 8)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 10)
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

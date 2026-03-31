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
        GeometryReader { proxy in
            let metrics = MainLayoutMetrics(proxy: proxy)

            ZStack(alignment: .top) {
                backgroundLayer(
                    containerWidth: proxy.size.width,
                    containerHeight: proxy.size.height
                )

                if metrics.isLandscape {
                    VStack(spacing: 0) {
                        AdBannerView(isHidden: viewModel.isPremium)
                        landscapeContent(metrics: metrics, language: language)
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .padding(.top, metrics.topInset)
                    .padding(.bottom, metrics.bottomInset)
                    .safeAreaPadding(.horizontal, metrics.baseHorizontalPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    ScrollView(.vertical, showsIndicators: metrics.showsScrollIndicators) {
                        VStack(spacing: 0) {
                            AdBannerView(isHidden: viewModel.isPremium)
                            portraitContent(metrics: metrics, language: language)
                        }
                        .padding(.top, metrics.topInset)
                        .padding(.bottom, metrics.bottomInset)
                        .frame(maxWidth: .infinity, minHeight: metrics.minContentHeight, alignment: .topLeading)
                    }
                    .safeAreaPadding(.horizontal, metrics.baseHorizontalPadding)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
            Color(hex: "0A0A1A")

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

    private func portraitContent(metrics: MainLayoutMetrics, language: AppLanguage) -> some View {
        let panelSpacing: CGFloat = 14

        return VStack(spacing: 0) {
            headerBar(layoutWidth: metrics.portraitContentWidth, language: language)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

            CharacterView(
                character: viewModel.currentCharacter,
                state: viewModel.emotionState,
                animationState: viewModel.characterAnimationState,
                gauge: viewModel.emotionGauge,
                layoutWidth: metrics.portraitContentWidth
            )
            .frame(height: metrics.portraitCharacterHeight)
            .frame(maxWidth: .infinity)
            .padding(.top, metrics.isCompactHeight ? 8 : 24)

            EmotionGaugeView(
                gauge: viewModel.emotionGauge,
                state: viewModel.emotionState,
                layoutWidth: metrics.portraitContentWidth,
                pulseTrigger: viewModel.gaugePulseTrigger,
                pulseStrength: viewModel.gaugePulseStrength
            )
            .frame(maxWidth: .infinity)
            .padding(.top, panelSpacing)

            ControlPanelView(
                horizontalPadding: 0,
                layoutWidth: metrics.portraitContentWidth
            )
            .frame(maxWidth: .infinity)
            .padding(.top, panelSpacing)
        }
        .frame(width: metrics.portraitContentWidth, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func landscapeContent(metrics: MainLayoutMetrics, language: AppLanguage) -> some View {
        GeometryReader { geo in
            let availableHeight = max(geo.size.height - 8, 0)
            let headerEstimatedHeight: CGFloat = metrics.landscapeLeftColumnWidth < 360 ? 78 : 52
            let sectionSpacing: CGFloat = 12
            let leftSpacing: CGFloat = sectionSpacing
            let characterHeight = max(
                min(metrics.landscapeCharacterHeight, availableHeight - headerEstimatedHeight - leftSpacing),
                160
            )

            HStack(alignment: .top, spacing: metrics.landscapeSpacing) {
                VStack(spacing: leftSpacing) {
                    headerBar(layoutWidth: metrics.landscapeLeftColumnWidth, language: language)

                    CharacterView(
                        character: viewModel.currentCharacter,
                        state: viewModel.emotionState,
                        animationState: viewModel.characterAnimationState,
                        gauge: viewModel.emotionGauge,
                        layoutWidth: metrics.landscapeLeftColumnWidth,
                        scaleBoost: metrics.landscapeCharacterScaleBoost
                    )
                    .frame(height: characterHeight)
                }
                .frame(width: metrics.landscapeLeftColumnWidth, alignment: .topLeading)

                // ゲージを自然高さで配置し、直下にコントロールを密着させる
                // VStack に availableHeight を明示し、内部 GeometryReader が正確な残余高さを取得できるようにする
                VStack(spacing: 14) {
                    EmotionGaugeView(
                        gauge: viewModel.emotionGauge,
                        state: viewModel.emotionState,
                        layoutWidth: metrics.landscapeRightColumnWidth,
                        pulseTrigger: viewModel.gaugePulseTrigger,
                        pulseStrength: viewModel.gaugePulseStrength,
                        compactMode: true
                    )
                    // 固定高さを廃止し自然サイズに委ねることでカード下の余白を除去

                    ControlPanelView(
                        horizontalPadding: 0,
                        layoutWidth: metrics.landscapeRightColumnWidth,
                        compactMode: true
                    )
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(width: metrics.landscapeRightColumnWidth, height: availableHeight, alignment: .topLeading)
            }
            .frame(width: metrics.landscapeContainerWidth, alignment: .leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 8)
        }
    }

    // MARK: - Header

    private func headerBar(layoutWidth: CGFloat, language: AppLanguage) -> some View {
        // 横画面の広い左カラムではバッジを大きく表示（0.70 × 最大 400pt）
        let badgeWidth = max(min(layoutWidth * (layoutWidth < 360 ? 0.72 : 0.70), 400), 96)

        return HStack(spacing: 10) {
            currentCharacterBadge(maxWidth: badgeWidth)

            Spacer(minLength: 8)

            if viewModel.isRunning {
                liveIndicator(showText: true, language: language)
                    .fixedSize(horizontal: true, vertical: false)
                    .layoutPriority(2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func currentCharacterBadge(maxWidth: CGFloat) -> some View {
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
                .frame(maxWidth: maxWidth, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 12)
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
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, showText ? 10 : 8)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 10)
    }
}

private struct MainLayoutMetrics {
    let size: CGSize
    let safeInsets: EdgeInsets
    let isLandscape: Bool
    let isCompactHeight: Bool
    let safeWidth: CGFloat
    let safeHeight: CGFloat
    let baseHorizontalPadding: CGFloat
    let leftBias: CGFloat
    let usableWidth: CGFloat
    let portraitContentWidth: CGFloat
    let portraitCharacterHeight: CGFloat
    let landscapeContainerWidth: CGFloat
    let landscapeSpacing: CGFloat
    let landscapeLeftColumnWidth: CGFloat
    let landscapeRightColumnWidth: CGFloat
    let landscapeCharacterHeight: CGFloat
    let landscapeCharacterScaleBoost: CGFloat
    let topInset: CGFloat
    let bottomInset: CGFloat
    let minContentHeight: CGFloat

    init(proxy: GeometryProxy) {
        size = proxy.size
        safeInsets = proxy.safeAreaInsets
        isLandscape = proxy.size.width > proxy.size.height
        isCompactHeight = proxy.size.height < 760
        safeWidth = max(proxy.size.width - proxy.safeAreaInsets.leading - proxy.safeAreaInsets.trailing, 0)
        safeHeight = max(proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom, 0)
        // 横画面は余白を最小化して全幅を活かす。縦画面は従来値を維持。
        baseHorizontalPadding = isLandscape
            ? (safeWidth < 360 ? 4 : 6)
            : (safeWidth < 360 ? 10 : (safeWidth < 420 ? 12 : 16))
        // 横画面は leftBias 不要（中央寄りの非対称補正をなくす）
        leftBias = isLandscape ? 0 : min(CGFloat(10), max(safeWidth * 0.08, 0))
        usableWidth = max(safeWidth - baseHorizontalPadding * 2 - leftBias, 0)
        let portraitBaseWidth = safeWidth > 700 ? min(usableWidth, 400) : min(usableWidth, 440)
        let portraitMaxWidthWithinPadding = max(safeWidth - baseHorizontalPadding * 2, 0)
        portraitContentWidth = min(portraitBaseWidth + 5, portraitMaxWidthWithinPadding)
        portraitCharacterHeight = isCompactHeight
            ? (safeWidth < 360 ? 200 : 220)
            : (safeWidth < 360 ? 250 : 280)
        landscapeSpacing = 10   // 均一化してカラム幅を最大化
        landscapeContainerWidth = usableWidth

        let totalColumnWidth = max(landscapeContainerWidth - landscapeSpacing, 0)
        let minColumnWidth: CGFloat = 240
        // 横画面：左カラム（キャラ）を 60-62% に拡大して画面を広く使う
        let targetLeftRatio: CGFloat = isLandscape
            ? (safeWidth >= 900 ? 0.62 : 0.60)
            : (safeWidth >= 900 ? 0.57 : 0.53)
        if totalColumnWidth >= minColumnWidth * 2 {
            let raw = totalColumnWidth * targetLeftRatio
            landscapeLeftColumnWidth = min(max(raw, minColumnWidth), totalColumnWidth - minColumnWidth)
        } else {
            landscapeLeftColumnWidth = totalColumnWidth * 0.52
        }
        landscapeRightColumnWidth = max(totalColumnWidth - landscapeLeftColumnWidth, 0)
        // キャラ高さを画面高さの 70% に拡大（最大 380pt）
        landscapeCharacterHeight = max(min(proxy.size.height * 0.70, 380), 200)
        landscapeCharacterScaleBoost = safeWidth >= 900 ? 1.28 : (safeWidth >= 760 ? 1.22 : 1.18)
        topInset = max(proxy.safeAreaInsets.top, 8)
        bottomInset = isLandscape ? max(proxy.safeAreaInsets.bottom, 4) : max(proxy.safeAreaInsets.bottom, 12)
        minContentHeight = max(safeHeight, 0)
    }

    var showsScrollIndicators: Bool {
        isCompactHeight || isLandscape
    }

    var useLandscapeColumns: Bool {
        isLandscape && landscapeRightColumnWidth >= 260
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

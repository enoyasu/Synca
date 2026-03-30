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

                ScrollView(.vertical, showsIndicators: metrics.showsScrollIndicators) {
                    VStack(spacing: 0) {
                        AdBannerView(isHidden: viewModel.isPremium)

                        if metrics.useLandscapeColumns {
                            landscapeContent(metrics: metrics, language: language)
                        } else {
                            portraitContent(metrics: metrics, language: language)
                        }
                    }
                    .padding(.top, metrics.topInset)
                    .padding(.bottom, metrics.bottomInset)
                    .frame(maxWidth: .infinity, minHeight: metrics.minContentHeight, alignment: .topLeading)
                }
                .safeAreaPadding(.horizontal, metrics.baseHorizontalPadding)
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
        VStack(spacing: 0) {
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
            .padding(.top, metrics.isCompactHeight ? 8 : 16)

            ControlPanelView(
                horizontalPadding: 0,
                layoutWidth: metrics.portraitContentWidth
            )
            .frame(maxWidth: .infinity)
            .padding(.top, metrics.isCompactHeight ? 6 : 12)
        }
        .frame(width: metrics.portraitContentWidth, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func landscapeContent(metrics: MainLayoutMetrics, language: AppLanguage) -> some View {
        HStack(alignment: .top, spacing: metrics.landscapeSpacing) {
            VStack(spacing: 12) {
                headerBar(layoutWidth: metrics.landscapeLeftColumnWidth, language: language)

                CharacterView(
                    character: viewModel.currentCharacter,
                    state: viewModel.emotionState,
                    animationState: viewModel.characterAnimationState,
                    gauge: viewModel.emotionGauge,
                    layoutWidth: metrics.landscapeLeftColumnWidth,
                    scaleBoost: metrics.landscapeCharacterScaleBoost
                )
                .frame(height: metrics.landscapeCharacterHeight)
            }
            .frame(width: metrics.landscapeLeftColumnWidth, alignment: .topLeading)

            VStack(spacing: 12) {
                EmotionGaugeView(
                    gauge: viewModel.emotionGauge,
                    state: viewModel.emotionState,
                    layoutWidth: metrics.landscapeRightColumnWidth,
                    pulseTrigger: viewModel.gaugePulseTrigger,
                    pulseStrength: viewModel.gaugePulseStrength
                )

                ControlPanelView(
                    horizontalPadding: 0,
                    layoutWidth: metrics.landscapeRightColumnWidth
                )
            }
            .frame(width: metrics.landscapeRightColumnWidth, alignment: .topLeading)
        }
        .frame(width: metrics.landscapeContainerWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    // MARK: - Header

    @ViewBuilder
    private func headerBar(layoutWidth: CGFloat, language: AppLanguage) -> some View {
        let isCompactWidth = layoutWidth < 330
        let shouldStack = layoutWidth < 360
        let characterMaxWidth = max(min(layoutWidth * (shouldStack ? 0.58 : 0.34), 190), 72)

        if shouldStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    appLogo
                    Spacer(minLength: 0)
                    if viewModel.isRunning {
                        liveIndicator(showText: !isCompactWidth, language: language)
                    }
                }

                currentCharacterBadge(maxWidth: characterMaxWidth)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(spacing: 10) {
                appLogo
                    .layoutPriority(1)

                Spacer(minLength: 8)

                currentCharacterBadge(maxWidth: characterMaxWidth)

                if viewModel.isRunning {
                    liveIndicator(showText: true, language: language)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var appLogo: some View {
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
        baseHorizontalPadding = safeWidth < 360 ? 10 : (safeWidth < 420 ? 12 : 16)
        let requestedBias: CGFloat = isLandscape ? 7 : 10
        leftBias = min(requestedBias, max(safeWidth * 0.08, 0))
        usableWidth = max(safeWidth - baseHorizontalPadding * 2 - leftBias, 0)
        portraitContentWidth = safeWidth > 700 ? min(usableWidth, 400) : min(usableWidth, 440)
        portraitCharacterHeight = isCompactHeight
            ? (safeWidth < 360 ? 200 : 220)
            : (safeWidth < 360 ? 250 : 280)
        landscapeSpacing = safeWidth < 780 ? 10 : 14
        landscapeContainerWidth = safeWidth > 1000 ? min(usableWidth, 940) : min(usableWidth, 860)

        let totalColumnWidth = max(landscapeContainerWidth - landscapeSpacing, 0)
        let minColumnWidth: CGFloat = 240
        let targetLeftRatio: CGFloat = safeWidth >= 900 ? 0.6 : 0.56
        if totalColumnWidth >= minColumnWidth * 2 {
            let raw = totalColumnWidth * targetLeftRatio
            landscapeLeftColumnWidth = min(max(raw, minColumnWidth), totalColumnWidth - minColumnWidth)
        } else {
            landscapeLeftColumnWidth = totalColumnWidth * 0.52
        }
        landscapeRightColumnWidth = max(totalColumnWidth - landscapeLeftColumnWidth, 0)
        landscapeCharacterHeight = max(min(proxy.size.height * 0.66, 430), 220)
        landscapeCharacterScaleBoost = safeWidth >= 900 ? 1.2 : (safeWidth >= 760 ? 1.16 : 1.1)
        topInset = max(proxy.safeAreaInsets.top, 8)
        bottomInset = max(proxy.safeAreaInsets.bottom, 12)
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

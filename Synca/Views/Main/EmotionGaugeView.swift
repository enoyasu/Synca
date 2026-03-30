import SwiftUI

/// 感情ゲージ（0〜100）の可視化コンポーネント
struct EmotionGaugeView: View {
    let gauge: Double           // 0.0〜100.0
    let state: EmotionState
    let layoutWidth: CGFloat
    let pulseTrigger: Int
    let pulseStrength: Double
    let compactMode: Bool

    @AppStorage(AppPreferenceKey.appLanguage) private var appLanguageRaw = AppLanguage.japanese.rawValue
    @State private var animatedGauge: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0

    private let barHeight: CGFloat = 14
    private let cornerRadius: CGFloat = 8

    init(
        gauge: Double,
        state: EmotionState,
        layoutWidth: CGFloat = 360,
        pulseTrigger: Int = 0,
        pulseStrength: Double = 0.0,
        compactMode: Bool = false
    ) {
        self.gauge = gauge
        self.state = state
        self.layoutWidth = layoutWidth
        self.pulseTrigger = pulseTrigger
        self.pulseStrength = pulseStrength
        self.compactMode = compactMode
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .japanese
    }

    var body: some View {
        let isCompactWidth = layoutWidth < 330 || compactMode
        let isMediumWidth = layoutWidth < 390
        let contentSpacing: CGFloat = compactMode ? 8 : 10

        VStack(spacing: contentSpacing) {
            // ラベル行
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(state.primaryColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: state.primaryColor, radius: 4)

                    Text(state.displayName(for: language))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(state.primaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .animation(.easeInOut(duration: 0.4), value: state)
                }

                Spacer()

                Text("\(Int(gauge))")
                    .font(.system(size: compactMode ? 20 : 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: Int(gauge))

                Text(" / 100")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            // ゲージバー
            ZStack(alignment: .leading) {
                // 背景トラック
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: barHeight)

                // 区切りマーカー（30 / 70）
                GeometryReader { geo in
                    let w = geo.size.width
                    let fillRatio = CGFloat(min(max(animatedGauge / 100, 0), 1))
                    let rawFillWidth = w * fillRatio
                    let fillWidth = fillRatio > 0 ? max(rawFillWidth, 2) : 0
                    ZStack(alignment: .leading) {
                        ZStack(alignment: .leading) {
                            // 塗り
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: Color(hex: "6B9FD4"), location: 0.0),
                                            .init(color: Color(hex: "A855F7"), location: 0.3),
                                            .init(color: Color(hex: "EC4899"), location: 0.7),
                                            .init(color: Color(hex: "F59E0B"), location: 1.0)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: fillWidth, height: barHeight)
                                .scaleEffect(x: pulseScale, y: 1.0, anchor: .leading)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animatedGauge)

                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color.white.opacity(pulseOpacity))
                                .frame(width: fillWidth, height: barHeight)

                            // シマーエフェクト
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.clear,
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 80, height: barHeight)
                                .offset(x: shimmerOffset)
                                .clipped()
                                .mask(
                                    RoundedRectangle(cornerRadius: cornerRadius)
                                        .frame(width: fillWidth)
                                )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }

                    // 区切りライン
                    ForEach([30.0, 70.0], id: \.self) { threshold in
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 1.5, height: barHeight + 6)
                            .offset(x: w * CGFloat(threshold / 100) - 0.75, y: -3)
                    }
                }
                .frame(height: barHeight)
            }
            .frame(height: barHeight + 6)

            // 状態インジケーター
            HStack(spacing: isCompactWidth ? 4 : 8) {
                stateIndicator(
                    label: isCompactWidth ? compactStateLabel(for: .calm) : fullStateLabel(for: .calm),
                    range: 0...30,
                    color: Color(hex: "6B9FD4"),
                    isCompactWidth: isCompactWidth
                )
                .frame(maxWidth: .infinity)

                stateIndicator(
                    label: isCompactWidth ? compactStateLabel(for: .excited) : fullStateLabel(for: .excited),
                    range: 30...70,
                    color: Color(hex: "A855F7"),
                    isCompactWidth: isCompactWidth
                )
                .frame(maxWidth: .infinity)

                stateIndicator(
                    label: isCompactWidth ? compactStateLabel(for: .special) : fullStateLabel(for: .special),
                    range: 70...100,
                    color: Color(hex: "F59E0B"),
                    isCompactWidth: isCompactWidth
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, isCompactWidth ? 12 : (isMediumWidth ? 14 : 18))
        .padding(.vertical, compactMode ? 10 : 16)
        .glassCard()
        .onAppear {
            animatedGauge = gauge
            startShimmer()
        }
        .onChange(of: gauge) { _, newValue in
            animatedGauge = newValue
        }
        .onChange(of: pulseTrigger) { _, _ in
            animateGaugePulse()
        }
    }

    private func stateIndicator(
        label: String,
        range: ClosedRange<Double>,
        color: Color,
        isCompactWidth: Bool
    ) -> some View {
        let isActive = state == EmotionState(gauge: (range.lowerBound + range.upperBound) / 2)
        return Text(label)
            .font(.system(size: compactMode ? 8.5 : (isCompactWidth ? 9 : 10), weight: isActive ? .bold : .regular))
            .foregroundColor(isActive ? color : .white.opacity(0.48))
            .lineLimit(compactMode ? 1 : 2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.center)
            .padding(.horizontal, isCompactWidth ? 4 : 8)
            .padding(.vertical, compactMode ? 2 : 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? color.opacity(0.18) : Color.clear)
            )
            .animation(.easeInOut(duration: 0.3), value: state)
    }

    private func fullStateLabel(for state: EmotionState) -> String {
        switch state {
        case .calm: return L10n.text(.calmState, language: language)
        case .excited: return L10n.text(.excitedState, language: language)
        case .special: return L10n.text(.specialState, language: language)
        }
    }

    private func compactStateLabel(for state: EmotionState) -> String {
        switch state {
        case .calm: return L10n.text(.calmChip, language: language)
        case .excited: return L10n.text(.excitedChip, language: language)
        case .special: return L10n.text(.specialChip, language: language)
        }
    }

    private func startShimmer() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            shimmerOffset = 400
        }
    }

    private func animateGaugePulse() {
        let normalized = min(max(pulseStrength, 0.0), 1.0)
        let scale = 1.0 + (0.02 + normalized * 0.06)

        withAnimation(.easeOut(duration: 0.08)) {
            pulseScale = scale
            pulseOpacity = 0.14 + normalized * 0.18
        }
        withAnimation(.easeOut(duration: 0.28).delay(0.08)) {
            pulseScale = 1.0
            pulseOpacity = 0.0
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "0D0D1A").ignoresSafeArea()
        VStack(spacing: 20) {
            EmotionGaugeView(gauge: 20, state: .calm)
            EmotionGaugeView(gauge: 55, state: .excited)
            EmotionGaugeView(gauge: 88, state: .special)
        }
        .padding()
    }
}

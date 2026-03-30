import SwiftUI

/// キャラクターをSwiftUIで描画するビュー（外部アセット不要）
struct CharacterView: View {
    let character: Character
    let state: EmotionState
    let animationState: CharacterAnimationState
    let gauge: Double
    let layoutWidth: CGFloat
    let scaleBoost: CGFloat

    // MARK: - Animation State
    @State private var isBlinking = false
    @State private var floatY: CGFloat = 0
    @State private var bodyScale: CGFloat = 1.0
    @State private var glowRadius: CGFloat = 30
    @State private var particleOpacity: Double = 0
    @State private var starRotation: Double = 0

    init(
        character: Character,
        state: EmotionState,
        animationState: CharacterAnimationState,
        gauge: Double,
        layoutWidth: CGFloat = 320,
        scaleBoost: CGFloat = 1.0
    ) {
        self.character = character
        self.state = state
        self.animationState = animationState
        self.gauge = gauge
        self.layoutWidth = layoutWidth
        self.scaleBoost = scaleBoost
    }

    var body: some View {
        let baseScale = min(max(layoutWidth / 320, 0.76), 1.0)
        let characterScale = min(max(baseScale * scaleBoost, 0.76), 1.22)

        ZStack {
            // 背景グロー
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            state.glowColor,
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 60,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 8)
                .animation(.easeInOut(duration: 1.0), value: state)

            // パーティクル（特別状態）
            if state == .special || state == .excited {
                ParticleEmitterView(state: state, opacity: particleOpacity)
            }

            // キャラクター本体
            characterBody
                .offset(y: floatY)
                .scaleEffect(bodyScale)
        }
        .scaleEffect(characterScale)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startFloatAnimation()
            startBlinkCycle()
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                starRotation = 360
            }
        }
        .onChange(of: state) { _, newState in
            handleStateChange(newState)
        }
        .onChange(of: animationState) { _, newAnim in
            handleAnimationChange(newAnim)
        }
    }

    // MARK: - Character Body

    private var characterBody: some View {
        ZStack {
            // 外側リング（状態色）
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            state.primaryColor.opacity(0.6),
                            state.secondaryColor.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 176, height: 176)
                .blur(radius: 2)

            // 本体（グラデーション円）
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: character.accentColorHex).opacity(0.85),
                            Color(hex: character.accentColorHex).opacity(0.5)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 168, height: 168)
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 168, height: 168)
                )

            // 顔パーツ
            faceLayer

            // 状態バッジ（特別状態のみ）
            if state == .special {
                specialBadge
                    .offset(x: 62, y: -62)
            }
        }
    }

    // MARK: - Face

    private var faceLayer: some View {
        ZStack {
            // 眉毛
            eyebrowsLayer
                .offset(y: -38)

            // 目
            eyesLayer
                .offset(y: -18)

            // 口
            mouthLayer
                .offset(y: 20)

            // 感情装飾
            emotionDecorations
        }
    }

    private var eyebrowsLayer: some View {
        HStack(spacing: 30) {
            eyebrow(isLeft: true)
            eyebrow(isLeft: false)
        }
    }

    private func eyebrow(isLeft: Bool) -> some View {
        let yOffset: CGFloat = {
            switch state {
            case .calm:    return 0
            case .excited: return -4
            case .special: return -6
            }
        }()
        let rotation: Double = isLeft
            ? (state == .special ? -15 : state == .excited ? -8 : 0)
            : (state == .special ? 15 : state == .excited ? 8 : 0)

        return RoundedRectangle(cornerRadius: 3)
            .fill(Color.white.opacity(0.9))
            .frame(width: 22, height: 3.5)
            .rotationEffect(.degrees(rotation))
            .offset(y: yOffset)
            .animation(.spring(response: 0.3), value: state)
    }

    private var eyesLayer: some View {
        HStack(spacing: 30) {
            eyeView(isLeft: true)
            eyeView(isLeft: false)
        }
    }

    private func eyeView(isLeft: Bool) -> some View {
        ZStack {
            // 白目
            Ellipse()
                .fill(Color.white)
                .frame(width: 30, height: isBlinking ? 3 : 34)
                .animation(.easeInOut(duration: 0.08), value: isBlinking)

            if !isBlinking {
                // 瞳
                Circle()
                    .fill(Color(hex: "1a1a2e"))
                    .frame(width: 15, height: 15)
                    .offset(
                        x: pupilOffset(isLeft: isLeft).x,
                        y: pupilOffset(isLeft: isLeft).y
                    )
                    .animation(.spring(response: 0.2), value: state)

                // ハイライト
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 5, height: 5)
                    .offset(x: -3, y: -4)

                // 特別状態：ハートマーク
                if state == .special {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Color(hex: "FF6B8A"))
                        .offset(x: isLeft ? 12 : 12, y: -14)
                        .scaleEffect(bodyScale > 1.05 ? 1.3 : 1.0)
                        .animation(.spring(response: 0.2), value: bodyScale)
                }
            }
        }
    }

    private func pupilOffset(isLeft: Bool) -> CGPoint {
        switch state {
        case .calm:    return CGPoint(x: 0, y: 3)
        case .excited: return CGPoint(x: isLeft ? -2 : 2, y: 2)
        case .special: return CGPoint(x: isLeft ? -3 : 3, y: 1)
        }
    }

    private var mouthLayer: some View {
        Group {
            switch state {
            case .calm:
                // 穏やかな微笑み
                MouthPath(curveAmount: 8, width: 28)
                    .stroke(Color.white.opacity(0.9),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 28, height: 12)

            case .excited:
                // 大きな笑顔
                MouthPath(curveAmount: 13, width: 36)
                    .stroke(Color.white,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 16)

            case .special:
                // 最大の笑顔 + テキスト
                ZStack {
                    MouthPath(curveAmount: 16, width: 42)
                        .stroke(Color.white,
                                style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: 42, height: 18)
                }
            }
        }
        .animation(.spring(response: 0.3), value: state)
    }

    private var emotionDecorations: some View {
        ZStack {
            switch state {
            case .calm:
                EmptyView()

            case .excited:
                // 音符装飾
                HStack {
                    Image(systemName: "music.note")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .rotationEffect(.degrees(-15))
                        .offset(x: -72, y: -28)

                    Spacer()

                    Image(systemName: "music.note.list")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .offset(x: 60, y: -42)
                }

            case .special:
                // 星エフェクト
                ForEach(0..<4, id: \.self) { i in
                    let positions: [(CGFloat, CGFloat)] = [(-72, -56), (68, -48), (-60, 30), (70, 22)]
                    let sizes: [CGFloat] = [12, 10, 9, 11]
                    Image(systemName: "sparkle")
                        .font(.system(size: sizes[i], weight: .bold))
                        .foregroundColor(.yellow)
                        .offset(x: positions[i].0, y: positions[i].1)
                        .rotationEffect(.degrees(starRotation + Double(i * 45)))
                        .opacity(particleOpacity)
                }
            }
        }
    }

    private var specialBadge: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "F59E0B"))
                .frame(width: 28, height: 28)
                .shadow(color: .orange, radius: 8)
            Image(systemName: "star.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(bodyScale > 1.05 ? 1.2 : 1.0)
        .animation(.spring(response: 0.2), value: bodyScale)
    }

    // MARK: - Animations

    private func startFloatAnimation() {
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            floatY = -12
        }
    }

    private func startBlinkCycle() {
        let delay = Double.random(in: 2.5...5.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            isBlinking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isBlinking = false
                startBlinkCycle()
            }
        }
    }

    private func handleStateChange(_ newState: EmotionState) {
        // ポップアニメーション
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            bodyScale = 1.15
            glowRadius = 50
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3)) {
                bodyScale = 1.0
                glowRadius = 30
            }
        }

        // パーティクル
        withAnimation(.easeIn(duration: 0.3)) {
            particleOpacity = newState == .calm ? 0 : 1
        }
    }

    private func handleAnimationChange(_ anim: CharacterAnimationState) {
        switch anim {
        case .idle:
            break
        case .react:
            withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { bodyScale = 1.06 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring()) { bodyScale = 1.0 }
            }
        case .excited:
            withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) { bodyScale = 1.12 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring()) { bodyScale = 1.0 }
            }
        case .special:
            withAnimation(.spring(response: 0.2, dampingFraction: 0.35)) { bodyScale = 1.22 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.4)) { bodyScale = 1.0 }
            }
        }
    }
}

// MARK: - Mouth Path Shape
private struct MouthPath: Shape {
    let curveAmount: CGFloat
    let width: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.minY + curveAmount)
        )
        return path
    }
}

// MARK: - Simple Particle View
private struct ParticleEmitterView: View {
    let state: EmotionState
    let opacity: Double

    private let particleCount = 8

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { i in
                Circle()
                    .fill(state == .special ? Color.yellow : state.primaryColor)
                    .frame(width: CGFloat.random(in: 3...7), height: CGFloat.random(in: 3...7))
                    .offset(
                        x: CGFloat.random(in: -120...120),
                        y: CGFloat.random(in: -120...120)
                    )
                    .opacity(opacity * Double.random(in: 0.3...0.8))
            }
        }
        .frame(width: 240, height: 240)
    }
}

#Preview {
    ZStack {
        Color(hex: "0D0D1A").ignoresSafeArea()
        CharacterView(
            character: CharacterManager.shared.defaultCharacter,
            state: .excited,
            animationState: .idle,
            gauge: 50
        )
    }
}

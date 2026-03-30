import SwiftUI

struct ContentView: View {
    @State private var rootPhase: RootPhase = .launchAnimation

    var body: some View {
        ZStack {
            switch rootPhase {
            case .launchAnimation:
                LaunchAnimationView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        rootPhase = .home
                    }
                }
                .transition(.opacity)

            case .home:
                HomeEntryView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                        rootPhase = .main
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.02)))

            case .main:
                MainView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: rootPhase)
    }
}

private enum RootPhase {
    case launchAnimation
    case home
    case main
}

private struct LaunchAnimationView: View {
    let onFinish: () -> Void

    @State private var logoScale: CGFloat = 0.72
    @State private var logoOpacity: Double = 0.0
    @State private var ringRotation: Double = -16
    @State private var glowOpacity: Double = 0.0
    @State private var hasScheduledFinish = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "05050D"), Color(hex: "14142A"), Color(hex: "05050D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ZStack {
                Circle()
                    .fill(Color(hex: "A78BFA").opacity(0.25))
                    .frame(width: 220, height: 220)
                    .blur(radius: 26)
                    .opacity(glowOpacity)

                Image("BrandIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .shadow(color: Color(hex: "A78BFA").opacity(0.35), radius: 18, y: 8)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .rotationEffect(.degrees(ringRotation))
            }
        }
        .onAppear {
            guard !hasScheduledFinish else { return }
            hasScheduledFinish = true

            withAnimation(.spring(response: 0.62, dampingFraction: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
                ringRotation = 0
                glowOpacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                withAnimation(.easeOut(duration: 0.22)) {
                    logoOpacity = 0.0
                    glowOpacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: onFinish)
            }
        }
    }
}

private struct HomeEntryView: View {
    let onTapStart: () -> Void
    @AppStorage(AppPreferenceKey.appLanguage) private var appLanguageRaw = AppLanguage.japanese.rawValue
    @State private var pulse = false

    private var language: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .japanese
    }

    private var tapHint: String {
        language == .japanese ? "画面をタップして開始" : "Tap Anywhere to Start"
    }

    var body: some View {
        GeometryReader { proxy in
            let safeWidth = max(proxy.size.width - proxy.safeAreaInsets.leading - proxy.safeAreaInsets.trailing, 0)
            let horizontalPadding: CGFloat = safeWidth < 360 ? 16 : 24
            let contentWidth = min(max(safeWidth - horizontalPadding * 2, 0), 320)

            ZStack {
                LinearGradient(
                    colors: [Color(hex: "070715"), Color(hex: "171732"), Color(hex: "090919")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image("BrandIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 126, height: 126)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .shadow(color: Color(hex: "A78BFA").opacity(0.35), radius: 20, y: 8)

                    Text("Synca")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color(hex: "D8B4FE")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text(tapHint)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassCard(cornerRadius: 14)
                        .scaleEffect(pulse ? 1.03 : 0.97)
                        .opacity(pulse ? 1.0 : 0.82)
                        .animation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true), value: pulse)
                }
                .frame(width: contentWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, horizontalPadding)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTapStart()
            }
            .onAppear { pulse = true }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MainViewModel())
        .preferredColorScheme(.dark)
}

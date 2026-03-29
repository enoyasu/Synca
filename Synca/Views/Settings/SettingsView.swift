import SwiftUI

/// 設定画面（感度・音量・バージョン情報）
struct SettingsView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0A0A1A").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // センサー設定
                        SettingsSection(title: "センサー設定", icon: "gyroscope") {
                            VStack(spacing: 18) {
                                SettingsSlider(
                                    title: "感度",
                                    icon: "dial.high.fill",
                                    value: $viewModel.sensitivity,
                                    range: 0.2...3.0,
                                    displayValue: sensitivityLabel(viewModel.sensitivity)
                                )

                                Divider().background(Color.white.opacity(0.1))

                                sensitivityPreview
                            }
                        }

                        // オーディオ設定
                        SettingsSection(title: "オーディオ", icon: "speaker.wave.2.fill") {
                            SettingsSlider(
                                title: "音量",
                                icon: "speaker.fill",
                                value: $viewModel.volume,
                                range: 0.0...1.0,
                                displayValue: "\(Int(viewModel.volume * 100))%"
                            )
                        }

                        // ゲージ設定
                        SettingsSection(title: "感情ゲージ", icon: "chart.bar.fill") {
                            VStack(alignment: .leading, spacing: 12) {
                                gaugeInfo(range: "0 〜 30", label: "通常状態", color: Color(hex: "6B9FD4"))
                                gaugeInfo(range: "30 〜 70", label: "反応強状態", color: Color(hex: "A855F7"))
                                gaugeInfo(range: "70 〜 100", label: "特別状態 ✨", color: Color(hex: "F59E0B"))
                            }
                        }

                        // アプリ情報
                        SettingsSection(title: "アプリ情報", icon: "info.circle.fill") {
                            VStack(spacing: 12) {
                                infoRow(label: "バージョン", value: "1.0.0")
                                Divider().background(Color.white.opacity(0.1))
                                infoRow(label: "ビルド", value: "1")
                                Divider().background(Color.white.opacity(0.1))
                                infoRow(label: "プレミアム", value: viewModel.isPremium ? "有効" : "無効")
                            }
                        }

                        // リセット
                        Button {
                            resetSettings()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("設定をリセット")
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "EF4444").opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .glassCard(cornerRadius: 14)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sub Views

    private var sensitivityPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("感度プレビュー")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 4) {
                ForEach(0..<10, id: \.self) { i in
                    let threshold = Double(i + 1) / 10.0
                    let active = viewModel.sensitivity / 3.0 >= threshold
                    RoundedRectangle(cornerRadius: 2)
                        .fill(active ? Color(hex: "A78BFA") : Color.white.opacity(0.15))
                        .frame(height: 18 + CGFloat(i * 2))
                }
            }
            .frame(height: 40, alignment: .bottom)
            .animation(.spring(response: 0.3), value: viewModel.sensitivity)
        }
    }

    private func gaugeInfo(range: String, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 4, height: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(range)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Circle()
                .fill(color.opacity(0.2))
                .overlay(Circle().stroke(color.opacity(0.5), lineWidth: 1))
                .frame(width: 12, height: 12)
                .shadow(color: color, radius: 4)
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private func sensitivityLabel(_ value: Double) -> String {
        switch value {
        case ..<0.5: return "低"
        case ..<1.2: return "標準"
        case ..<2.0: return "高"
        default:     return "最高"
        }
    }

    private func resetSettings() {
        withAnimation {
            viewModel.sensitivity = 1.0
            viewModel.volume = 0.8
        }
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // セクションヘッダー
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "A78BFA"))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .padding(.horizontal, 4)

            content()
                .padding(16)
                .glassCard(cornerRadius: 16)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Settings Slider

private struct SettingsSlider: View {
    let title: String
    let icon: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let displayValue: String

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "A78BFA"))
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                Spacer()
                Text(displayValue)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "A78BFA"))
                    .frame(width: 50, alignment: .trailing)
            }

            Slider(value: $value, in: range)
                .tint(Color(hex: "A78BFA"))
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(MainViewModel())
        .preferredColorScheme(.dark)
}

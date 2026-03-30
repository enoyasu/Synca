import SwiftUI

/// 設定画面（感度・音量・バージョン情報）
struct SettingsView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppPreferenceKey.appLanguage) private var appLanguageRaw = AppLanguage.japanese.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .japanese
    }

    private var languageSelection: Binding<AppLanguage> {
        Binding(
            get: { language },
            set: { newValue in
                appLanguageRaw = newValue.rawValue
                viewModel.refreshDialogue()
            }
        )
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let width = proxy.size.width
                let horizontalPadding: CGFloat = width < 360 ? 10 : (width < 410 ? 12 : 16)
                let availableWidth = max(width - horizontalPadding * 2, 0)
                let contentWidth: CGFloat = width > 700 ? min(availableWidth, 430) : min(availableWidth, 470)

                ZStack {
                    Color(hex: "0A0A1A").ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 16) {
                            // センサー設定
                            SettingsSection(title: L10n.text(.sensorSettings, language: language), icon: "gyroscope", horizontalPadding: horizontalPadding) {
                                VStack(spacing: 18) {
                                    SettingsSlider(
                                        title: L10n.text(.sensitivity, language: language),
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
                            SettingsSection(title: L10n.text(.audioSettings, language: language), icon: "speaker.wave.2.fill", horizontalPadding: horizontalPadding) {
                                SettingsSlider(
                                    title: L10n.text(.volume, language: language),
                                    icon: "speaker.fill",
                                    value: $viewModel.volume,
                                    range: 0.0...1.0,
                                    displayValue: "\(Int(viewModel.volume * 100))%"
                                )
                            }

                            // ゲージ設定
                            SettingsSection(title: L10n.text(.gaugeSettings, language: language), icon: "chart.bar.fill", horizontalPadding: horizontalPadding) {
                                VStack(alignment: .leading, spacing: 12) {
                                    gaugeInfo(range: "0 〜 30", label: L10n.text(.calmState, language: language), color: Color(hex: "6B9FD4"))
                                    gaugeInfo(range: "30 〜 70", label: L10n.text(.excitedState, language: language), color: Color(hex: "A855F7"))
                                    gaugeInfo(range: "70 〜 100", label: L10n.text(.specialState, language: language), color: Color(hex: "F59E0B"))
                                }
                            }

                            // 言語設定
                            SettingsSection(title: L10n.text(.languageSettings, language: language), icon: "globe", horizontalPadding: horizontalPadding) {
                                languagePicker
                            }

                            // アプリ情報
                            SettingsSection(title: L10n.text(.appInfo, language: language), icon: "info.circle.fill", horizontalPadding: horizontalPadding) {
                                VStack(spacing: 12) {
                                    infoRow(label: L10n.text(.version, language: language), value: Bundle.main.shortVersionString)
                                    Divider().background(Color.white.opacity(0.1))
                                    infoRow(label: L10n.text(.build, language: language), value: Bundle.main.buildNumberString)
                                    Divider().background(Color.white.opacity(0.1))
                                    infoRow(
                                        label: L10n.text(.premium, language: language),
                                        value: viewModel.isPremium
                                            ? L10n.text(.premiumEnabled, language: language)
                                            : L10n.text(.premiumDisabled, language: language)
                                    )
                                }
                            }

                            // リセット
                            Button {
                                resetSettings()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text(L10n.text(.resetSettings, language: language))
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "EF4444").opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .glassCard(cornerRadius: 14)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(.horizontal, horizontalPadding)
                        }
                        .frame(maxWidth: contentWidth)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle(L10n.text(.settingsTitle, language: language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text(.close, language: language)) { dismiss() }
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
            Text(L10n.text(.sensitivityPreview, language: language))
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

    private var languagePicker: some View {
        Picker("", selection: languageSelection) {
            ForEach(AppLanguage.allCases) { appLanguage in
                Text(appLanguage.displayName).tag(appLanguage)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 260, alignment: .leading)
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
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .layoutPriority(1)
        }
    }

    private func sensitivityLabel(_ value: Double) -> String {
        L10n.sensitivityLabel(value, language: language)
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
    let horizontalPadding: CGFloat
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
        .padding(.horizontal, horizontalPadding)
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .frame(minWidth: 44, alignment: .trailing)
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

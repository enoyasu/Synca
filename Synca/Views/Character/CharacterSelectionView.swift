import SwiftUI

/// キャラクター選択シート
struct CharacterSelectionView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingPurchaseAlert = false
    @State private var selectedForPurchase: Character?
    @State private var isPurchasing = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let isNarrowWidth = proxy.size.width < 360
                let horizontalPadding: CGFloat = isNarrowWidth ? 14 : 20
                let gridSpacing: CGFloat = isNarrowWidth ? 10 : 14

                ZStack {
                    // 背景
                    Color(hex: "0A0A1A").ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 20) {
                            // ヘッダー説明
                            headerInfo
                                .padding(.horizontal, horizontalPadding)
                                .padding(.top, 4)

                            // キャラクターグリッド
                            LazyVGrid(columns: gridColumns(isNarrowWidth: isNarrowWidth, spacing: gridSpacing), spacing: gridSpacing) {
                                ForEach(viewModel.availableCharacters) { character in
                                    CharacterCardView(
                                        character: character,
                                        isSelected: viewModel.currentCharacter.id == character.id,
                                        onTap: {
                                            viewModel.selectCharacter(character)
                                            dismiss()
                                        },
                                        onPurchase: {
                                            selectedForPurchase = character
                                            showingPurchaseAlert = true
                                        }
                                    )
                                    .frame(height: isNarrowWidth ? 210 : 220)
                                }
                            }
                            .padding(.horizontal, horizontalPadding)

                            // 広告削除オファー
                            if !viewModel.isPremium {
                                removeAdsCard(isNarrowWidth: isNarrowWidth)
                                    .padding(.horizontal, horizontalPadding)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("キャラクター選択")
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
        .alert("キャラクターを解放", isPresented: $showingPurchaseAlert, presenting: selectedForPurchase) { char in
            Button("購入 \(char.unlockPrice ?? "¥120")") {
                Task {
                    await purchaseCharacter(char)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: { char in
            Text("\(char.name) を解放しますか？")
        }
        .overlay {
            if isPurchasing {
                purchasingOverlay
            }
        }
    }

    // MARK: - Header Info

    private var headerInfo: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "A78BFA"))
            Text("キャラクターを選んで、一緒に楽しもう！")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .layoutPriority(1)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 12)
    }

    // MARK: - Remove Ads Card

    @ViewBuilder
    private func removeAdsCard(isNarrowWidth: Bool) -> some View {
        if isNarrowWidth {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    removeAdsIcon
                    removeAdsText
                }

                Button {
                    Task {
                        await viewModel.purchaseRemoveAds()
                    }
                } label: {
                    Text("購入")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "F59E0B"), Color(hex: "D97706")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(14)
            .glassCard(cornerRadius: 16)
        } else {
            HStack(spacing: 14) {
                removeAdsIcon
                removeAdsText

                Spacer()

                Button {
                    Task {
                        await viewModel.purchaseRemoveAds()
                    }
                } label: {
                    Text("購入")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "F59E0B"), Color(hex: "D97706")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .fixedSize(horizontal: true, vertical: false)
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(14)
            .glassCard(cornerRadius: 16)
        }
    }

    private var removeAdsIcon: some View {
        ZStack {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "F59E0B"), Color(hex: "EF4444")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    private var removeAdsText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("広告を削除")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text("¥250でずっと広告なし体験")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.65))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(1)
    }

    // MARK: - Purchasing Overlay

    private var purchasingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                Text("処理中...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(30)
            .glassCard(cornerRadius: 20)
        }
    }

    // MARK: - Purchase

    private func purchaseCharacter(_ character: Character) async {
        isPurchasing = true
        await viewModel.purchaseCharacter(character)
        isPurchasing = false
    }

    private func gridColumns(isNarrowWidth: Bool, spacing: CGFloat) -> [GridItem] {
        if isNarrowWidth {
            return [GridItem(.flexible(), spacing: spacing)]
        }
        return [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ]
    }
}

#Preview("iPhone 16") {
    CharacterSelectionView()
        .environmentObject(MainViewModel())
        .preferredColorScheme(.dark)
}

#Preview("iPhone 16 Pro Max") {
    CharacterSelectionView()
        .environmentObject(MainViewModel())
        .preferredColorScheme(.dark)
}

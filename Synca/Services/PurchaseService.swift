import Foundation
import StoreKit
import Combine

/// App内課金を管理するサービス（StoreKit 2）
@MainActor
final class PurchaseService: ObservableObject {
    // MARK: - Published
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Product IDs
    enum ProductID {
        static let removeAds    = "com.synca.app.removeads"
        static let characterHana = "com.synca.app.character.hana"
        static let characterRiku = "com.synca.app.character.riku"
        static let characterSora = "com.synca.app.character.sora"

        static var allCharacters: [String] {
            [characterHana, characterRiku, characterSora]
        }
    }

    // MARK: - Private
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Lifecycle
    init() {
        updateListenerTask = listenForTransactions()
        Task { await restorePurchases() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public

    /// 購入処理
    func purchase(productID: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: [productID])
            guard let product = products.first else {
                errorMessage = "商品が見つかりませんでした"
                return
            }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    purchasedProductIDs.insert(transaction.productID)
                    await transaction.finish()
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "購入に失敗しました: \(error.localizedDescription)"
        }
    }

    /// 購入済み確認
    func isPurchased(_ productID: String) -> Bool {
        purchasedProductIDs.contains(productID)
    }

    var isAdFree: Bool {
        isPurchased(ProductID.removeAds)
    }

    // MARK: - Private

    private func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result {
                    let productID = transaction.productID
                    _ = await MainActor.run {
                        self.purchasedProductIDs.insert(productID)
                    }
                    await transaction.finish()
                }
            }
        }
    }
}

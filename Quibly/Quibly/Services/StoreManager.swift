import StoreKit
import SwiftUI
import Combine

// Manages all In-App Purchase products and transactions via StoreKit 2.
@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    enum ProductID: String, CaseIterable {
        case starterPack  = "com.quibly.coins.starter"   // 100 coins
        case builderPack  = "com.quibly.coins.builder"   // 300 coins
        case masterPack   = "com.quibly.coins.master"    // 750 coins
        case sparkleBundle = "com.quibly.bundle.sparkle" // 1500 coins + power-ups

        var coinReward: Int {
            switch self {
            case .starterPack:   return 100
            case .builderPack:   return 300
            case .masterPack:    return 750
            case .sparkleBundle: return 1500
            }
        }
    }

    @Published var products: [Product] = []
    @Published var isPurchasing = false
    @Published var purchaseError: String? = nil

    private var transactionListener: Task<Void, Error>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProductID.allCases.map(\.rawValue))
            products = ProductID.allCases.compactMap { id in
                loaded.first { $0.id == id.rawValue }
            }
        } catch {
            print("[StoreManager] Failed to load products: \(error)")
        }
    }

    func product(for id: ProductID) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    func displayPrice(for id: ProductID) -> String {
        product(for: id)?.displayPrice ?? "—"
    }

    // MARK: - Purchasing

    @discardableResult
    func purchase(_ productID: ProductID) async -> Bool {
        guard let product = product(for: productID) else { return false }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                deliverRewards(for: productID)
                await transaction.finish()
                return true
            case .pending, .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try await self?.verified(result)
                    if let id = ProductID(rawValue: transaction?.productID ?? "") {
                        await MainActor.run { self?.deliverRewards(for: id) }
                    }
                    await transaction?.finish()
                } catch {
                    print("[StoreManager] Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Helpers

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreManagerError.failedVerification
        case .verified(let value): return value
        }
    }

    private func deliverRewards(for productID: ProductID) {
        deliverCoins(productID.coinReward)
        if productID == .sparkleBundle {
            deliverPowerUps(5)
        }
    }

    private func deliverCoins(_ amount: Int) {
        let key = "SlideWords_Coins"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + amount, forKey: key)
    }

    private func deliverPowerUps(_ amount: Int) {
        let ud = UserDefaults.standard
        for key in ["SlideWords_HintCharges", "SlideWords_ShuffleCharges",
                    "SlideWords_BombCharges", "SlideWords_WildCharges"] {
            ud.set(ud.integer(forKey: key) + amount, forKey: key)
        }
    }
}

enum StoreManagerError: LocalizedError {
    case failedVerification
    var errorDescription: String? { "Purchase could not be verified." }
}

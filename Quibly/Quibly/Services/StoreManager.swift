import StoreKit
import SwiftUI
import Combine

// Manages all In-App Purchase products and transactions via StoreKit 2.
@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    enum ProductID: String, CaseIterable {
        case starterPack  = "com.quibly.coins.starter"   // 1000 coins
        case builderPack  = "com.quibly.coins.builder2"   // 3000 coins
        case masterPack   = "com.quibly.coins.master"    // 7500 coins
        case sparkleBundle = "com.quibly.bundle.sparkle" // 15000 coins + power-ups

        var coinReward: Int {
            switch self {
            case .starterPack:   return 1000
            case .builderPack:   return 3000
            case .masterPack:    return 7500
            case .sparkleBundle: return 15000
            }
        }

        var fallbackPrice: String {
            switch self {
            case .starterPack:   return "$0.99"
            case .builderPack:   return "$1.99"
            case .masterPack:    return "$3.99"
            case .sparkleBundle: return "$9.99"
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
        product(for: id)?.displayPrice ?? id.fallbackPrice
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
                guard let self else { break }
                do {
                    let transaction = try await MainActor.run { try self.verified(result) }
                    if let id = ProductID(rawValue: transaction.productID) {
                        await MainActor.run { [weak self] in self?.deliverRewards(for: id) }
                    }
                    await transaction.finish()
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
            deliverTheme("sunset")
        }
    }

    private func deliverTheme(_ themeID: String) {
        let key = "Quibly_OwnedThemes"
        let current = UserDefaults.standard.string(forKey: key) ?? "cream"
        var owned = Set(current.components(separatedBy: ",").filter { !$0.isEmpty })
        owned.insert(themeID)
        UserDefaults.standard.set(owned.joined(separator: ","), forKey: key)
    }

    private func deliverCoins(_ amount: Int) {
        let key = "Quibly_Coins"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + amount, forKey: key)
    }

    private func deliverPowerUps(_ amount: Int) {
        let ud = UserDefaults.standard
        for key in ["Quibly_HintCharges", "Quibly_ShuffleCharges",
                    "Quibly_BombCharges", "Quibly_WildCharges"] {
            ud.set(ud.integer(forKey: key) + amount, forKey: key)
        }
    }
}

enum StoreManagerError: LocalizedError {
    case failedVerification
    var errorDescription: String? { "Purchase could not be verified." }
}

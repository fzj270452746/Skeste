import Foundation
import StoreKit

enum GiftPurchaseResult {
    case success
    case cancelled
    case pending
    case unavailable
    case failed(String)
}

final class StoreKitService {
    static let shared = StoreKitService()

    private(set) var products: [String: Product] = [:]
    private var isLoading = false
    private var updatesTask: Task<Void, Never>?

    private init() {}

    func startObservingTransactions() {
        guard updatesTask == nil else { return }
        updatesTask = Task.detached { [weak self] in
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
                await self?.markStoreChanged()
            }
        }
    }

    func loadProducts() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        let identifiers = Gift.catalog.map(\.productID)
        do {
            let fetched = try await Product.products(for: identifiers)
            products = Dictionary(uniqueKeysWithValues: fetched.map { ($0.id, $0) })
        } catch {
            products = [:]
        }
    }

    func priceLabel(for gift: Gift) -> String {
        products[gift.productID]?.displayPrice ?? gift.priceLabel
    }

    func purchase(_ gift: Gift) async -> GiftPurchaseResult {
        if products[gift.productID] == nil {
            await loadProducts()
        }
        guard let product = products[gift.productID] else {
            return .unavailable
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    return .failed("That purchase could not be verified.")
                }
                await transaction.finish()
                return .success
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed("That purchase could not be completed.")
            }
        } catch {
            return .failed("The gift could not be completed. Please try again.")
        }
    }

    @MainActor
    private func markStoreChanged() {
        NotificationCenter.default.post(name: .skesteContentChanged, object: nil)
    }
}

import Foundation
import StoreKit
import SuperwallKit

/// Custom purchase controller that bridges Superwall with StoreKit 2
/// This allows Superwall to use our StoreKit integration for purchases
@MainActor
final class SuperwallPurchaseController: PurchaseController {

    // MARK: - PurchaseController Protocol

    /// Called by Superwall to purchase a product
    /// - Parameter product: The StoreProduct from Superwall
    /// - Returns: PurchaseResult indicating success, failure, or cancellation
    func purchase(product: StoreProduct) async -> PurchaseResult {
        // Get the StoreKit 2 product from the StoreProduct
        guard let sk2Product = product.sk2Product else {
            // Fallback: try to fetch the product directly
            guard let fetchedProduct = await fetchStoreKit2Product(for: product.productIdentifier) else {
                return .failed(PurchaseError.productNotFound)
            }
            return await performPurchase(fetchedProduct)
        }

        return await performPurchase(sk2Product)
    }

    /// Performs the actual purchase with a StoreKit 2 Product
    private func performPurchase(_ product: StoreKit.Product) async -> PurchaseResult {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    // Finish the transaction
                    await transaction.finish()

                    // Update subscription status in our manager
                    await SubscriptionManager.shared.updateSubscriptionStatus()

                    // Sync Superwall's subscription status
                    await syncSuperwallSubscriptionStatus()

                    return .purchased

                case .unverified(_, let error):
                    return .failed(error)
                }

            case .userCancelled:
                return .cancelled

            case .pending:
                // Transaction is pending (e.g., parental approval)
                return .cancelled

            @unknown default:
                return .cancelled
            }
        } catch {
            return .failed(error)
        }
    }

    /// Called by Superwall to restore purchases
    func restorePurchases() async -> RestorationResult {
        do {
            try await AppStore.sync()

            // Update our subscription manager
            await SubscriptionManager.shared.updateSubscriptionStatus()

            // Sync Superwall's subscription status
            await syncSuperwallSubscriptionStatus()

            // Check if user has active subscription after restore
            if SubscriptionManager.shared.isPremium {
                return .restored
            } else {
                return .failed(nil)
            }
        } catch {
            return .failed(error)
        }
    }

    // MARK: - Subscription Status Sync

    /// Syncs the subscription status with Superwall
    /// Must be called whenever the user's entitlements change
    func syncSuperwallSubscriptionStatus() async {
        var activeProductIDs: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                activeProductIDs.insert(transaction.productID)
            }
        }

        if activeProductIDs.isEmpty {
            Superwall.shared.subscriptionStatus = .inactive
        } else {
            // Get the StoreProducts from Superwall for these product IDs
            let storeProducts = await Superwall.shared.products(for: activeProductIDs)
            let entitlements = Set(storeProducts.flatMap { $0.entitlements })

            if entitlements.isEmpty {
                // Fallback: if no entitlements mapped, just mark as active
                Superwall.shared.subscriptionStatus = .active([])
            } else {
                Superwall.shared.subscriptionStatus = .active(entitlements)
            }
        }
    }

    // MARK: - Helpers

    /// Fetches the StoreKit 2 Product for a given product identifier
    private func fetchStoreKit2Product(for productID: String) async -> StoreKit.Product? {
        do {
            let products = try await StoreKit.Product.products(for: [productID])
            return products.first
        } catch {
            MPLogger.error("Failed to fetch StoreKit 2 product", error: error, category: MPLogger.subscription)
            return nil
        }
    }
}

// MARK: - Purchase Errors

enum PurchaseError: LocalizedError {
    case productNotFound
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found in the App Store"
        case .verificationFailed:
            return "Transaction verification failed"
        }
    }
}

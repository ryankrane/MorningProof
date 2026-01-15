import Foundation
import SuperwallKit
import StoreKit

// MARK: - Superwall Service

/// Manages Superwall SDK integration for paywall presentation
final class SuperwallService: ObservableObject {
    static let shared = SuperwallService()

    private let apiKey = "pk_gy44ZZ9bIK5RvZTC9n_RZ"

    @Published var isConfigured = false

    private init() {}

    // MARK: - Configuration

    /// Configure Superwall SDK - call this on app launch
    func configure() {
        Superwall.configure(apiKey: apiKey, purchaseController: SuperwallPurchaseController())
        isConfigured = true

        // Set user attributes for targeting
        Task {
            await setUserAttributes()
        }
    }

    // MARK: - User Attributes

    /// Set user attributes for paywall targeting and analytics
    @MainActor
    func setUserAttributes() async {
        let manager = MorningProofManager.shared
        let subscriptionManager = SubscriptionManager.shared

        var attributes: [String: Any] = [:]

        // User info
        if !manager.settings.userName.isEmpty {
            attributes["name"] = manager.settings.userName
        }

        // Subscription status
        attributes["is_subscribed"] = subscriptionManager.isSubscribed
        attributes["subscription_status"] = subscriptionManager.isSubscribed ? "active" : "none"

        // App usage
        attributes["habits_count"] = manager.todaysHabits.count
        attributes["current_streak"] = manager.currentStreak

        // Onboarding status
        attributes["has_completed_onboarding"] = manager.hasCompletedOnboarding

        Superwall.shared.setUserAttributes(attributes)
    }

    // MARK: - Paywall Presentation

    /// Register a paywall event/placement
    /// - Parameters:
    ///   - event: The event name configured in Superwall dashboard
    ///   - params: Optional parameters to pass with the event
    ///   - completion: Called when paywall interaction completes
    func register(
        event: String,
        params: [String: Any]? = nil,
        onSkip: (() -> Void)? = nil,
        onPurchase: (() -> Void)? = nil,
        onRestore: (() -> Void)? = nil
    ) {
        let handler = PaywallPresentationHandler()

        handler.onSkip { reason in
            print("[Superwall] Paywall skipped: \(reason)")
            onSkip?()
        }

        handler.onPresent { info in
            print("[Superwall] Paywall presented: \(info.name)")
        }

        handler.onDismiss { info in
            print("[Superwall] Paywall dismissed: \(info.name)")
        }

        handler.onError { error in
            print("[Superwall] Paywall error: \(error)")
            // On error, skip to continue flow
            onSkip?()
        }

        Superwall.shared.register(event: event, params: params, handler: handler) {
            // Feature block - called if user has access (subscribed or paywall skipped)
            print("[Superwall] Feature access granted for event: \(event)")
        }
    }

    /// Present the onboarding paywall
    /// - Parameters:
    ///   - onComplete: Called when user completes paywall (subscribe or skip)
    func presentOnboardingPaywall(onComplete: @escaping () -> Void) {
        register(
            event: "onboarding_paywall",
            onSkip: onComplete,
            onPurchase: {
                onComplete()
            },
            onRestore: {
                onComplete()
            }
        )
    }

    /// Present paywall from settings
    func presentSettingsPaywall() {
        register(event: "settings_paywall")
    }

    /// Present paywall when user hits a limit
    func presentLimitPaywall() {
        register(event: "limit_reached")
    }

    // MARK: - Subscription Check

    /// Check if user should see paywall
    func shouldShowPaywall() -> Bool {
        return !SubscriptionManager.shared.isSubscribed
    }
}

// MARK: - Purchase Controller

/// Custom purchase controller to integrate Superwall with existing StoreKit 2 setup
final class SuperwallPurchaseController: PurchaseController {

    func purchase(product: SKProduct) async -> PurchaseResult {
        // Convert SKProduct to StoreKit 2 Product and use existing SubscriptionManager
        do {
            // Get the StoreKit 2 product
            let products = try await Product.products(for: [product.productIdentifier])
            guard let storeProduct = products.first else {
                return .failed(StoreError.productNotFound)
            }

            // Purchase using StoreKit 2
            let result = try await storeProduct.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await SubscriptionManager.shared.refreshSubscriptionStatus()
                    return .purchased
                case .unverified:
                    return .failed(StoreError.failedVerification)
                }
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .cancelled
            }
        } catch {
            return .failed(error)
        }
    }

    func restorePurchases() async -> RestorationResult {
        do {
            try await AppStore.sync()
            await SubscriptionManager.shared.refreshSubscriptionStatus()

            if SubscriptionManager.shared.isSubscribed {
                return .restored
            } else {
                return .failed(nil)
            }
        } catch {
            return .failed(error)
        }
    }
}

// MARK: - Superwall Events

/// Common Superwall event names for this app
enum SuperwallEvent {
    static let onboardingPaywall = "onboarding_paywall"
    static let settingsPaywall = "settings_paywall"
    static let limitReached = "limit_reached"
    static let featureGated = "feature_gated"
}

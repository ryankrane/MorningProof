import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Product IDs
    enum ProductID: String, CaseIterable {
        case monthlyPremium = "com.rk.morningproof.premium.monthly"
        case yearlyPremium = "com.rk.morningproof.premium.yearly"
        case streakRecovery = "com.rk.morningproof.streakrecovery"
    }

    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .none
    @Published private(set) var isLoading = false

    // Trial tracking
    @Published var trialStartDate: Date?
    @Published var trialEndDate: Date?
    @Published var freeRecoveriesUsedThisMonth: Int = 0

    // MARK: - Subscription Status
    enum SubscriptionStatus: Equatable {
        case none
        case trial(daysRemaining: Int)
        case premium
        case expired
    }

    // MARK: - Premium Features
    var isPremium: Bool {
        switch subscriptionStatus {
        case .premium, .trial:
            return true
        case .none, .expired:
            return false
        }
    }

    var isInTrial: Bool {
        if case .trial = subscriptionStatus {
            return true
        }
        return false
    }

    var trialDaysRemaining: Int {
        if case .trial(let days) = subscriptionStatus {
            return days
        }
        return 0
    }

    // MARK: - Feature Limits (Free Tier)
    let freeHabitLimit = 3
    let freeAIVerificationsPerMonth = 10
    let freeStreakRecoveriesPerMonth = 0

    // MARK: - Feature Limits (Premium)
    let premiumStreakRecoveriesPerMonth = 1
    let streakRecoveryPrice = "$0.99"

    // MARK: - Private
    private var updateListenerTask: Task<Void, Error>?
    private let userDefaults = UserDefaults.standard

    // UserDefaults Keys
    private let trialStartKey = "morningproof_trial_start"
    private let trialEndKey = "morningproof_trial_end"
    private let aiVerificationsKey = "morningproof_ai_verifications_count"
    private let aiVerificationsMonthKey = "morningproof_ai_verifications_month"
    private let freeRecoveriesKey = "morningproof_free_recoveries_used"
    private let freeRecoveriesMonthKey = "morningproof_free_recoveries_month"

    // MARK: - Initialization

    init() {
        loadTrialData()
        loadUsageData()

        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        isLoading = true

        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            isLoading = false
        } catch {
            MPLogger.error("Failed to load products", error: error, category: MPLogger.subscription)
            isLoading = false
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    func purchaseMonthly() async throws -> StoreKit.Transaction? {
        guard let product = products.first(where: { $0.id == ProductID.monthlyPremium.rawValue }) else {
            return nil
        }
        return try await purchase(product)
    }

    func purchaseYearly() async throws -> StoreKit.Transaction? {
        guard let product = products.first(where: { $0.id == ProductID.yearlyPremium.rawValue }) else {
            return nil
        }
        return try await purchase(product)
    }

    func purchaseStreakRecovery() async throws -> StoreKit.Transaction? {
        guard let product = products.first(where: { $0.id == ProductID.streakRecovery.rawValue }) else {
            return nil
        }
        return try await purchase(product)
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            MPLogger.error("Failed to restore purchases", error: error, category: MPLogger.subscription)
        }
    }

    // MARK: - Subscription Status

    func updateSubscriptionStatus() async {
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.productID == ProductID.monthlyPremium.rawValue ||
                   transaction.productID == ProductID.yearlyPremium.rawValue {
                    hasActiveSubscription = true
                }
            } catch {
                MPLogger.error("Failed to verify transaction", error: error, category: MPLogger.subscription)
            }
        }

        if hasActiveSubscription {
            subscriptionStatus = .premium
        } else if let trialEnd = trialEndDate {
            let now = Date()
            if now < trialEnd {
                let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: trialEnd).day ?? 0
                subscriptionStatus = .trial(daysRemaining: max(0, daysRemaining))
            } else {
                subscriptionStatus = .expired
            }
        } else {
            // Check if this is a new user - start trial
            if trialStartDate == nil {
                startTrial()
            } else {
                subscriptionStatus = .none
            }
        }
    }

    // MARK: - Trial Management

    func startTrial() {
        let now = Date()
        guard let trialEnd = Calendar.current.date(byAdding: .day, value: 7, to: now) else { return }

        trialStartDate = now
        trialEndDate = trialEnd

        userDefaults.set(now, forKey: trialStartKey)
        userDefaults.set(trialEnd, forKey: trialEndKey)

        let daysRemaining = 7
        subscriptionStatus = .trial(daysRemaining: daysRemaining)
    }

    private func loadTrialData() {
        trialStartDate = userDefaults.object(forKey: trialStartKey) as? Date
        trialEndDate = userDefaults.object(forKey: trialEndKey) as? Date
    }

    // MARK: - Usage Tracking

    private func loadUsageData() {
        let currentMonth = Calendar.current.component(.month, from: Date())

        // Reset AI verifications if new month
        let savedAIMonth = userDefaults.integer(forKey: aiVerificationsMonthKey)
        if savedAIMonth != currentMonth {
            userDefaults.set(0, forKey: aiVerificationsKey)
            userDefaults.set(currentMonth, forKey: aiVerificationsMonthKey)
        }

        // Reset free recoveries if new month
        let savedRecoveriesMonth = userDefaults.integer(forKey: freeRecoveriesMonthKey)
        if savedRecoveriesMonth != currentMonth {
            userDefaults.set(0, forKey: freeRecoveriesKey)
            userDefaults.set(currentMonth, forKey: freeRecoveriesMonthKey)
            freeRecoveriesUsedThisMonth = 0
        } else {
            freeRecoveriesUsedThisMonth = userDefaults.integer(forKey: freeRecoveriesKey)
        }
    }

    var aiVerificationsUsedThisMonth: Int {
        userDefaults.integer(forKey: aiVerificationsKey)
    }

    var canUseAIVerification: Bool {
        if isPremium { return true }
        return aiVerificationsUsedThisMonth < freeAIVerificationsPerMonth
    }

    var aiVerificationsRemaining: Int {
        if isPremium { return Int.max }
        return max(0, freeAIVerificationsPerMonth - aiVerificationsUsedThisMonth)
    }

    func recordAIVerification() {
        let count = aiVerificationsUsedThisMonth + 1
        userDefaults.set(count, forKey: aiVerificationsKey)
    }

    // MARK: - Streak Recovery

    var canUseFreeStreakRecovery: Bool {
        guard isPremium else { return false }
        return freeRecoveriesUsedThisMonth < premiumStreakRecoveriesPerMonth
    }

    func useFreeStreakRecovery() {
        freeRecoveriesUsedThisMonth += 1
        userDefaults.set(freeRecoveriesUsedThisMonth, forKey: freeRecoveriesKey)
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerifiedAsync(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    MPLogger.error("Transaction failed verification", error: error, category: MPLogger.subscription)
                }
            }
        }
    }

    private func checkVerified<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private nonisolated func checkVerifiedAsync<T>(_ result: StoreKit.VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Price Helpers

    var monthlyPrice: String {
        products.first { $0.id == ProductID.monthlyPremium.rawValue }?.displayPrice ?? "$4.99"
    }

    var yearlyPrice: String {
        products.first { $0.id == ProductID.yearlyPremium.rawValue }?.displayPrice ?? "$29.99"
    }

    var yearlySavings: String {
        // Calculate savings vs monthly
        guard let monthly = products.first(where: { $0.id == ProductID.monthlyPremium.rawValue }),
              let yearly = products.first(where: { $0.id == ProductID.yearlyPremium.rawValue }) else {
            return "Save 50%"
        }

        let monthlyAnnual = monthly.price * Decimal(12)
        let savings = ((monthlyAnnual - yearly.price) / monthlyAnnual) * Decimal(100)
        return "Save \(NSDecimalNumber(decimal: savings).intValue)%"
    }
}

// MARK: - Errors

enum StoreError: Error {
    case failedVerification
    case productNotFound
}

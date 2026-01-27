import SwiftUI
import SwiftData
import Combine
import SuperwallKit
import FirebaseCore

@main
struct MorningProofApp: App {
    let container: ModelContainer

    init() {
        MPLogger.info("MorningProofApp: init starting...", category: MPLogger.general)

        // Configure Firebase first (required for Functions, Crashlytics, Analytics)
        FirebaseApp.configure()
        MPLogger.info("MorningProofApp: Firebase configured", category: MPLogger.general)
        do {
            MPLogger.info("MorningProofApp: Creating model container...", category: MPLogger.general)
            container = try ModelContainer(for:
                SDSettings.self,
                SDHabitConfig.self,
                SDDailyLog.self,
                SDHabitCompletion.self,
                SDStreakRecord.self,
                SDUnlockedAchievement.self
            )
            MPLogger.info("MorningProofApp: Model container created successfully", category: MPLogger.general)
        } catch let primaryError {
            MPLogger.error("MorningProofApp: Failed to create model container", error: primaryError, category: MPLogger.general)
            // Create an in-memory container as fallback so the app at least launches
            do {
                container = try ModelContainer(for:
                    SDSettings.self,
                    SDHabitConfig.self,
                    SDDailyLog.self,
                    SDHabitCompletion.self,
                    SDStreakRecord.self,
                    SDUnlockedAchievement.self,
                    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                )
                MPLogger.warning("MorningProofApp: Using in-memory fallback container", category: MPLogger.general)
            } catch let fallbackError {
                // Both attempts failed - use an absolute last-resort in-memory container
                // This should never happen, but better than crashing
                MPLogger.error("MorningProofApp: CRITICAL - In-memory fallback also failed", error: fallbackError, category: MPLogger.general)

                // Try one more time with minimal configuration
                do {
                    let minimalConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                    container = try ModelContainer(for: SDSettings.self, configurations: minimalConfig)
                    MPLogger.error("MorningProofApp: Using minimal emergency container - some features may not work", error: fallbackError, category: MPLogger.general)
                } catch {
                    // Absolute last resort - this container won't persist anything but the app won't crash
                    MPLogger.error("MorningProofApp: All container creation failed - using empty container", error: error, category: MPLogger.general)
                    container = try! ModelContainer(for: SDSettings.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                }
            }
        }

        // Configure Superwall for paywalls with custom purchase controller
        // The purchase controller bridges Superwall with StoreKit 2 for handling purchases
        let purchaseController = SuperwallPurchaseController()
        Superwall.configure(
            apiKey: "pk_gy44ZZ9bIK5RvZTC9n_RZ",
            purchaseController: purchaseController
        )

        // Sync subscription status with Superwall on launch (with delay to avoid startup issues)
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
            await purchaseController.syncSuperwallSubscriptionStatus()
        }

        MPLogger.info("MorningProofApp: init complete", category: MPLogger.general)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

/// Root view that handles app initialization
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                ContentView()
            } else {
                // Simple loading screen while managers initialize
                ZStack {
                    Color(UIColor.systemBackground)
                        .ignoresSafeArea()
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.gray)
                        .offset(y: 40)
                }
            }
        }
        .task {
            MPLogger.info("RootView: Starting initialization...", category: MPLogger.general)

            // Run migration first, then mark ready
            MPLogger.info("RootView: Running migration...", category: MPLogger.general)
            await MigrationManager.shared.migrateIfNeeded(modelContext: modelContext)
            MPLogger.info("RootView: Migration complete", category: MPLogger.general)

            // Small delay to ensure main actor is ready
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec

            MPLogger.info("RootView: Setting isReady = true", category: MPLogger.general)
            await MainActor.run {
                isReady = true
            }
            MPLogger.info("RootView: Initialization complete", category: MPLogger.general)

            // Register HealthKit background observers (with delay to avoid startup issues)
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 sec delay
                let isAuthorized = await MainActor.run { HealthKitManager.shared.isAuthorized }
                if isAuthorized {
                    await HealthKitBackgroundDeliveryService.shared.registerObservers()
                    MPLogger.info("RootView: HealthKit background observers registered", category: MPLogger.healthKit)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Reset notification state if new day when app becomes active
                HealthKitBackgroundDeliveryService.shared.resetDailyNotificationStateIfNeeded()

                // Sync notification authorization status in case user changed it in iOS Settings
                Task {
                    let notificationManager = NotificationManager.shared
                    await notificationManager.checkAuthorizationStatus()

                    let manager = MorningProofManager.shared
                    if manager.settings.notificationsEnabled && !notificationManager.isAuthorized {
                        await MainActor.run {
                            manager.settings.notificationsEnabled = false
                            manager.saveCurrentState()
                        }
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    // Access singletons in the body, not as stored properties
    // This avoids deadlock during view initialization

    var body: some View {
        MainContentView()
    }
}

/// Actual content view that safely accesses managers
struct MainContentView: View {
    @StateObject private var manager = ManagerWrapper()
    @StateObject private var themeWrapper = ThemeWrapper()

    var body: some View {
        Group {
            if manager.morningProofManager.hasCompletedOnboarding {
                MainTabView(manager: manager.morningProofManager)
            } else {
                OnboardingFlowView(manager: manager.morningProofManager)
            }
        }
        .environmentObject(themeWrapper.themeManager)
        .preferredColorScheme(themeWrapper.themeManager.preferredColorScheme)
        .onOpenURL { url in
            _ = AuthenticationManager.shared.handleGoogleURL(url)
        }
    }
}

/// Wrapper to safely hold the MorningProofManager singleton
/// @StateObject requires ObservableObject, so we wrap the singleton
/// Forwards objectWillChange from the wrapped manager so SwiftUI updates properly
@MainActor
class ManagerWrapper: ObservableObject {
    let morningProofManager: MorningProofManager
    private var cancellable: AnyCancellable?

    init() {
        self.morningProofManager = MorningProofManager.shared
        // Forward objectWillChange from the manager to this wrapper
        cancellable = morningProofManager.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    deinit {
        cancellable?.cancel()
    }
}

/// Wrapper to safely hold the ThemeManager singleton
/// Forwards objectWillChange from the wrapped manager so SwiftUI updates properly
@MainActor
class ThemeWrapper: ObservableObject {
    let themeManager: ThemeManager
    private var cancellable: AnyCancellable?

    init() {
        self.themeManager = ThemeManager.shared
        // Forward objectWillChange from the manager to this wrapper
        cancellable = themeManager.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    deinit {
        cancellable?.cancel()
    }
}

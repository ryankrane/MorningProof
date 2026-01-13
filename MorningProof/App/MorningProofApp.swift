import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Firebase will be configured once GoogleService-Info.plist is added
        // FirebaseApp.configure()
        return true
    }
}

@main
struct MorningProofApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @ObservedObject private var manager = MorningProofManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared

    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            SDSettings.self,
            SDHabitConfig.self,
            SDDailyLog.self,
            SDHabitCompletion.self,
            SDStreakRecord.self,
            SDUnlockedAchievement.self
        ])

        do {
            // CloudKit sync disabled until paid developer account is set up
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            // Log error and attempt in-memory fallback
            MPLogger.error("Failed to initialize persistent ModelContainer", error: error, category: MPLogger.storage)

            // Try in-memory fallback - app will work but data won't persist
            do {
                let fallbackConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    cloudKitDatabase: .none
                )
                modelContainer = try ModelContainer(
                    for: schema,
                    configurations: [fallbackConfig]
                )
                MPLogger.warning("Using in-memory storage - data will not persist", category: MPLogger.storage)
            } catch {
                // This should never happen, but if it does, we can't recover
                fatalError("Could not initialize ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if manager.hasCompletedOnboarding {
                    MainTabView(manager: manager)
                } else {
                    OnboardingFlowView(manager: manager)
                }
            }
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.preferredColorScheme)
            .onOpenURL { url in
                // Handle Google Sign-In callback
                _ = authManager.handleGoogleURL(url)
            }
            .task {
                // Run migration if needed
                let context = modelContainer.mainContext
                await MigrationManager.shared.migrateIfNeeded(modelContext: context)

                // Check Apple credential state on launch
                authManager.checkAppleCredentialState()

                // Initialize notifications on app launch
                await notificationManager.checkAuthorizationStatus()
                if manager.settings.notificationsEnabled && notificationManager.isAuthorized {
                    await notificationManager.updateNotificationSchedule(settings: manager.settings)
                }
            }
        }
        .modelContainer(modelContainer)
    }
}

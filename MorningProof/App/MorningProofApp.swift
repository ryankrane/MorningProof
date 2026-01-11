import SwiftUI
import SwiftData
import FirebaseCore

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

    @StateObject private var manager = MorningProofManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = ThemeManager.shared

    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                SDSettings.self,
                SDHabitConfig.self,
                SDDailyLog.self,
                SDHabitCompletion.self,
                SDStreakRecord.self,
                SDUnlockedAchievement.self
            ])

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
            fatalError("Could not initialize ModelContainer: \(error)")
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

import SwiftUI

@main
struct MorningProofApp: App {
    @StateObject private var manager = MorningProofManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var authManager = AuthenticationManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if manager.hasCompletedOnboarding {
                    DashboardView(manager: manager)
                } else if authManager.isAuthenticated {
                    OnboardingView(manager: manager)
                } else {
                    WelcomeView(manager: manager)
                }
            }
            .task {
                // Check Apple credential state on launch
                authManager.checkAppleCredentialState()

                // Initialize notifications on app launch
                await notificationManager.checkAuthorizationStatus()
                if manager.settings.notificationsEnabled && notificationManager.isAuthorized {
                    await notificationManager.updateNotificationSchedule(settings: manager.settings)
                }
            }
        }
    }
}

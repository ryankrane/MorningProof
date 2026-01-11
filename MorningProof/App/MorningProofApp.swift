import SwiftUI

@main
struct MorningProofApp: App {
    @StateObject private var manager = MorningProofManager.shared
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if manager.hasCompletedOnboarding {
                    DashboardView(manager: manager)
                } else {
                    OnboardingView(manager: manager)
                }
            }
            .task {
                // Initialize notifications on app launch
                await notificationManager.checkAuthorizationStatus()
                if manager.settings.notificationsEnabled && notificationManager.isAuthorized {
                    await notificationManager.updateNotificationSchedule(settings: manager.settings)
                }
            }
        }
    }
}

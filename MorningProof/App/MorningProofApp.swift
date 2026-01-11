import SwiftUI

@main
struct MorningProofApp: App {
    @StateObject private var manager = MorningProofManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if manager.hasCompletedOnboarding {
                    DashboardView(manager: manager)
                } else {
                    OnboardingView(manager: manager)
                }
            }
        }
    }
}

import SwiftUI
import SwiftData
import Combine

@main
struct MorningProofApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            SDSettings.self,
            SDHabitConfig.self,
            SDDailyLog.self,
            SDHabitCompletion.self,
            SDStreakRecord.self,
            SDUnlockedAchievement.self
        ])
    }
}

/// Root view that handles app initialization safely
/// This avoids the @MainActor singleton deadlock by deferring manager access
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
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
                }
            }
        }
        .task {
            // Run migration first, then mark ready
            await MigrationManager.shared.migrateIfNeeded(modelContext: modelContext)
            // Small delay to ensure main actor is ready
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec
            await MainActor.run {
                isReady = true
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
}

/// Wrapper to safely hold the ThemeManager singleton
@MainActor
class ThemeWrapper: ObservableObject {
    let themeManager: ThemeManager

    init() {
        self.themeManager = ThemeManager.shared
    }
}

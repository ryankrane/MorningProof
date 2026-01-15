import SwiftUI
import SwiftData
import Combine
import SuperwallKit

@main
struct MorningProofApp: App {
    let container: ModelContainer

    init() {
        print("🚀 MorningProofApp: init starting...")

        // Configure Superwall early
        SuperwallService.shared.configure()
        print("🚀 MorningProofApp: Superwall configured")

        do {
            print("🚀 MorningProofApp: Creating model container...")
            container = try ModelContainer(for:
                SDSettings.self,
                SDHabitConfig.self,
                SDDailyLog.self,
                SDHabitCompletion.self,
                SDStreakRecord.self,
                SDUnlockedAchievement.self
            )
            print("🚀 MorningProofApp: Model container created successfully")
        } catch {
            print("🚨 MorningProofApp: FATAL - Failed to create model container: \(error)")
            // Create an in-memory container as fallback so the app at least launches
            container = try! ModelContainer(for:
                SDSettings.self,
                SDHabitConfig.self,
                SDDailyLog.self,
                SDHabitCompletion.self,
                SDStreakRecord.self,
                SDUnlockedAchievement.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            print("🚨 MorningProofApp: Using in-memory fallback container")
        }
        print("🚀 MorningProofApp: init complete")
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
            print("🚀 RootView: Starting initialization...")

            // Run migration first, then mark ready
            print("🚀 RootView: Running migration...")
            await MigrationManager.shared.migrateIfNeeded(modelContext: modelContext)
            print("🚀 RootView: Migration complete")

            // Small delay to ensure main actor is ready
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 sec

            print("🚀 RootView: Setting isReady = true")
            await MainActor.run {
                isReady = true
            }
            print("🚀 RootView: Initialization complete")
        }
        .onAppear {
            print("🚀 RootView: onAppear called")
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
}

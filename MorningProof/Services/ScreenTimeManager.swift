import Foundation

// MARK: - Screen Time Manager (Family Controls)
// Uses Apple's FamilyControls, ManagedSettings, and DeviceActivity frameworks
// to block distracting apps until morning habits are completed.

#if true
import FamilyControls
import ManagedSettings
import DeviceActivity

// MARK: - Device Activity Name Extension

extension DeviceActivityName {
    static let morningRoutine = Self("morningRoutine")
}

// MARK: - Screen Time Manager

/// Manages Screen Time integration for blocking apps until morning habits are completed.
/// Uses Apple's FamilyControls, ManagedSettings, and DeviceActivity frameworks.
@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    // MARK: - Published Properties

    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var selectedApps = FamilyActivitySelection()
    @Published var isMonitoring = false

    // MARK: - Private Properties

    private let center = AuthorizationCenter.shared
    private let activityCenter = DeviceActivityCenter()
    private let store = ManagedSettingsStore()

    private let appGroupSuite = "group.com.rk.morningproof"

    // UserDefaults keys for App Group storage
    private enum Keys {
        static let selectedApps = "screenTime_selectedApps"
        static let isMonitoring = "screenTime_isMonitoring"
    }

    // MARK: - Initialization

    private init() {
        authorizationStatus = center.authorizationStatus
        loadSelectedApps()
        checkMonitoringStatus()
    }

    // MARK: - Authorization

    /// Requests Screen Time authorization from the user.
    /// This presents a system dialog asking for permission.
    func requestAuthorization() async throws {
        try await center.requestAuthorization(for: .individual)
        authorizationStatus = center.authorizationStatus
    }

    /// Checks if we have authorization to use Screen Time features
    var isAuthorized: Bool {
        authorizationStatus == .approved
    }

    /// Refreshes the authorization status from the system.
    /// Call this when the view appears to detect if user enabled Screen Time in Settings.
    func refreshAuthorizationStatus() {
        authorizationStatus = center.authorizationStatus
    }

    // MARK: - App Selection Persistence

    /// Saves the user's selected apps to App Group UserDefaults.
    /// This allows extensions to access the selection.
    func saveSelectedApps(_ selection: FamilyActivitySelection) {
        selectedApps = selection

        guard let defaults = UserDefaults(suiteName: appGroupSuite) else {
            MPLogger.error("Failed to access App Group UserDefaults", category: MPLogger.screenTime)
            return
        }

        do {
            let encoded = try JSONEncoder().encode(selection)
            defaults.set(encoded, forKey: Keys.selectedApps)
            defaults.synchronize()
            MPLogger.info("Saved \(selection.applicationTokens.count) selected apps", category: MPLogger.screenTime)
        } catch {
            MPLogger.error("Failed to encode selected apps", error: error, category: MPLogger.screenTime)
        }
    }

    /// Loads the user's selected apps from App Group UserDefaults.
    func loadSelectedApps() {
        guard let defaults = UserDefaults(suiteName: appGroupSuite),
              let data = defaults.data(forKey: Keys.selectedApps) else {
            return
        }

        do {
            selectedApps = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            MPLogger.info("Loaded \(selectedApps.applicationTokens.count) selected apps", category: MPLogger.screenTime)
        } catch {
            MPLogger.error("Failed to decode selected apps", error: error, category: MPLogger.screenTime)
        }
    }

    /// Returns true if the user has selected any apps to block
    var hasSelectedApps: Bool {
        !selectedApps.applicationTokens.isEmpty || !selectedApps.categoryTokens.isEmpty
    }

    // MARK: - Schedule Management

    /// Starts monitoring for the morning routine schedule.
    /// Apps will be blocked from the user's blocking start time.
    /// NOTE: Apps stay locked until habits are complete - no auto-unlock at cutoff.
    ///
    /// - Parameters:
    ///   - startMinutes: When blocking starts (minutes from midnight, e.g. 360 = 6:00 AM)
    ///   - cutoffMinutes: The morning cutoff time (used for interval end, but extension won't auto-unlock)
    func startMorningBlockingSchedule(startMinutes: Int, cutoffMinutes: Int) throws {
        guard isAuthorized else {
            MPLogger.warning("Cannot start schedule - not authorized", category: MPLogger.screenTime)
            return
        }

        guard hasSelectedApps else {
            MPLogger.warning("Cannot start schedule - no apps selected", category: MPLogger.screenTime)
            return
        }

        guard startMinutes > 0 else {
            MPLogger.warning("Cannot start schedule - blocking start time not configured", category: MPLogger.screenTime)
            return
        }

        let startHour = startMinutes / 60
        let startMinute = startMinutes % 60
        let cutoffHour = cutoffMinutes / 60
        let cutoffMinute = cutoffMinutes % 60

        // Schedule from user's blocking start time to cutoff time
        // NOTE: The extension will NOT auto-remove shields at intervalEnd
        // Shields only removed when user completes habits and locks in
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startHour, minute: startMinute, second: 0),
            intervalEnd: DateComponents(hour: cutoffHour, minute: cutoffMinute, second: 0),
            repeats: true
        )

        do {
            try activityCenter.startMonitoring(.morningRoutine, during: schedule)
            isMonitoring = true
            saveMonitoringStatus(true)

            // Sync blocking start time to App Group for extension access
            AppLockingDataStore.blockingStartMinutes = startMinutes
            AppLockingDataStore.appLockingEnabled = true

            // If we're already in the blocking window, apply shields immediately
            // This handles the case where user enables app locking after the start time has passed
            if AppLockingDataStore.shouldApplyShields() && !AppLockingDataStore.hasLockedInToday {
                applyShields()
                MPLogger.info("Applied shields immediately (already in blocking window)", category: MPLogger.screenTime)
            }

            MPLogger.info("Started morning blocking schedule (\(startHour):\(String(format: "%02d", startMinute)) - \(cutoffHour):\(String(format: "%02d", cutoffMinute)))", category: MPLogger.screenTime)
        } catch {
            MPLogger.error("Failed to start monitoring", error: error, category: MPLogger.screenTime)
            throw error
        }
    }

    /// Stops monitoring for the morning routine.
    func stopMonitoring() {
        activityCenter.stopMonitoring([.morningRoutine])
        isMonitoring = false
        saveMonitoringStatus(false)
        MPLogger.info("Stopped morning blocking schedule", category: MPLogger.screenTime)
    }

    private func checkMonitoringStatus() {
        let activities = activityCenter.activities
        isMonitoring = activities.contains(.morningRoutine)
    }

    private func saveMonitoringStatus(_ status: Bool) {
        guard let defaults = UserDefaults(suiteName: appGroupSuite) else { return }
        defaults.set(status, forKey: Keys.isMonitoring)
        defaults.synchronize()
    }

    // MARK: - Shield Management

    /// Applies shields to block the selected apps.
    /// Called by the DeviceActivityMonitor extension when the morning starts,
    /// or manually when enabling app locking.
    func applyShields() {
        guard hasSelectedApps else {
            MPLogger.warning("Cannot apply shields - no apps selected", category: MPLogger.screenTime)
            return
        }

        store.shield.applications = selectedApps.applicationTokens.isEmpty ? nil : selectedApps.applicationTokens
        store.shield.applicationCategories = selectedApps.categoryTokens.isEmpty ? nil : .specific(selectedApps.categoryTokens)

        // Sync lock status to App Group
        AppLockingDataStore.isDayLockedIn = false

        MPLogger.info("Applied shields to \(selectedApps.applicationTokens.count) apps", category: MPLogger.screenTime)
    }

    /// Removes all shields, unlocking the apps.
    /// Called when the user completes their morning habits and locks in their day.
    func removeShields() {
        store.clearAllSettings()

        // Sync lock status to App Group
        AppLockingDataStore.isDayLockedIn = true

        MPLogger.info("Removed all shields - apps unlocked", category: MPLogger.screenTime)
    }

    // MARK: - Debug Helpers

    /// Returns a description of the current state for debugging
    var debugDescription: String {
        """
        ScreenTimeManager Status:
        - Authorization: \(authorizationStatus)
        - Selected Apps: \(selectedApps.applicationTokens.count)
        - Selected Categories: \(selectedApps.categoryTokens.count)
        - Is Monitoring: \(isMonitoring)
        """
    }
}

#else

// MARK: - Stub Implementation (Feature Disabled)

/// Stub ScreenTimeManager while Family Controls approval is pending.
/// This allows the app to compile and run without Screen Time features.
@MainActor
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published var isMonitoring = false

    var hasSelectedApps: Bool { false }
    var isAuthorized: Bool { false }

    private init() {}

    func requestAuthorization() async throws {
        // No-op: Feature disabled
    }

    func startMorningBlockingSchedule(startMinutes: Int, cutoffMinutes: Int) throws {
        // No-op: Feature disabled
    }

    func stopMonitoring() {
        // No-op: Feature disabled
    }

    func applyShields() {
        // No-op: Feature disabled
    }

    func removeShields() {
        // No-op: Feature disabled
    }
}

#endif

import Foundation

/// Shared data store for app locking state between main app and extensions.
/// Uses App Group UserDefaults to share data across targets.
///
/// This is used by:
/// - Main MorningProof app (to update lock status when habits completed)
/// - DeviceActivityMonitor extension (to check if should apply/remove shields)
/// - ShieldConfiguration extension (to customize shield messages)
struct AppLockingDataStore {

    // MARK: - Constants

    static let suiteName = "group.com.rk.morningproof"

    // MARK: - Keys

    private enum Keys {
        static let isDayLockedIn = "appLocking_isDayLockedIn"
        static let morningCutoffMinutes = "appLocking_cutoffMinutes"
        static let appLockingEnabled = "appLocking_enabled"
        static let lastLockInDate = "appLocking_lastLockInDate"
        static let selectedAppsData = "appLocking_selectedApps"
    }

    // MARK: - Private Helpers

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Day Lock Status

    /// Whether the user has locked in their day (completed all habits).
    /// When true, app shields should be removed.
    static var isDayLockedIn: Bool {
        get { defaults?.bool(forKey: Keys.isDayLockedIn) ?? false }
        set {
            defaults?.set(newValue, forKey: Keys.isDayLockedIn)
            if newValue {
                lastLockInDate = Date()
            }
            defaults?.synchronize()
        }
    }

    /// The date/time when the user last locked in their day.
    /// Used to determine if the lock-in is still valid for today.
    static var lastLockInDate: Date? {
        get {
            defaults?.object(forKey: Keys.lastLockInDate) as? Date
        }
        set {
            defaults?.set(newValue, forKey: Keys.lastLockInDate)
            defaults?.synchronize()
        }
    }

    /// Checks if the user has already locked in today.
    /// Returns false if the lock-in was from a previous day.
    static var hasLockedInToday: Bool {
        guard isDayLockedIn, let lockDate = lastLockInDate else { return false }
        return Calendar.current.isDateInToday(lockDate)
    }

    // MARK: - Settings

    /// The morning cutoff time in minutes from midnight.
    /// e.g., 540 = 9:00 AM (default)
    static var morningCutoffMinutes: Int {
        get { defaults?.integer(forKey: Keys.morningCutoffMinutes) ?? 540 }
        set {
            defaults?.set(newValue, forKey: Keys.morningCutoffMinutes)
            defaults?.synchronize()
        }
    }

    /// Whether app locking is enabled by the user.
    static var appLockingEnabled: Bool {
        get { defaults?.bool(forKey: Keys.appLockingEnabled) ?? false }
        set {
            defaults?.set(newValue, forKey: Keys.appLockingEnabled)
            defaults?.synchronize()
        }
    }

    // MARK: - Helpers

    /// Resets the lock status for a new day.
    /// Called by the DeviceActivityMonitor at the start of the morning period.
    static func resetForNewDay() {
        isDayLockedIn = false
    }

    /// Checks if shields should currently be applied.
    /// Returns true if:
    /// - App locking is enabled
    /// - The user hasn't locked in today
    /// - We're within the morning blocking period
    static func shouldApplyShields() -> Bool {
        guard appLockingEnabled else { return false }
        guard !hasLockedInToday else { return false }

        // Check if we're before the cutoff time
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)

        return currentMinutes < morningCutoffMinutes
    }

    /// Debug description of current state
    static var debugDescription: String {
        """
        AppLockingDataStore:
        - Enabled: \(appLockingEnabled)
        - Day Locked In: \(isDayLockedIn)
        - Has Locked In Today: \(hasLockedInToday)
        - Cutoff: \(morningCutoffMinutes) minutes
        - Should Apply Shields: \(shouldApplyShields())
        """
    }
}

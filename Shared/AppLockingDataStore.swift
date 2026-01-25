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
        static let blockingStartMinutes = "appLocking_blockingStartMinutes"
        static let appLockingEnabled = "appLocking_enabled"
        static let lastLockInDate = "appLocking_lastLockInDate"
        static let selectedAppsData = "appLocking_selectedApps"
        static let wasEmergencyUnlock = "appLocking_wasEmergencyUnlock"
        static let customDeadlinesEnabled = "appLocking_customDeadlinesEnabled"
        static let weekdayDeadlineMinutes = "appLocking_weekdayDeadlineMinutes"
        static let weekendDeadlineMinutes = "appLocking_weekendDeadlineMinutes"
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

    /// The time when app blocking starts, in minutes from midnight.
    /// e.g., 360 = 6:00 AM
    /// A value of 0 means not configured - user must set this.
    static var blockingStartMinutes: Int {
        get { defaults?.integer(forKey: Keys.blockingStartMinutes) ?? 0 }
        set {
            defaults?.set(newValue, forKey: Keys.blockingStartMinutes)
            defaults?.synchronize()
        }
    }

    /// Whether the user has configured a blocking start time.
    static var hasConfiguredBlockingStartTime: Bool {
        blockingStartMinutes > 0
    }

    /// Whether app locking is enabled by the user.
    static var appLockingEnabled: Bool {
        get { defaults?.bool(forKey: Keys.appLockingEnabled) ?? false }
        set {
            defaults?.set(newValue, forKey: Keys.appLockingEnabled)
            defaults?.synchronize()
        }
    }

    // MARK: - Custom Deadlines (Weekday vs Weekend)

    /// Whether custom weekday/weekend deadlines are enabled.
    static var customDeadlinesEnabled: Bool {
        get { defaults?.bool(forKey: Keys.customDeadlinesEnabled) ?? false }
        set {
            defaults?.set(newValue, forKey: Keys.customDeadlinesEnabled)
            defaults?.synchronize()
        }
    }

    /// Weekday deadline in minutes from midnight (Mon-Fri).
    /// Default: 540 (9:00 AM)
    static var weekdayDeadlineMinutes: Int {
        get { defaults?.integer(forKey: Keys.weekdayDeadlineMinutes) ?? 540 }
        set {
            defaults?.set(newValue, forKey: Keys.weekdayDeadlineMinutes)
            defaults?.synchronize()
        }
    }

    /// Weekend deadline in minutes from midnight (Sat-Sun).
    /// Default: 660 (11:00 AM)
    static var weekendDeadlineMinutes: Int {
        get { defaults?.integer(forKey: Keys.weekendDeadlineMinutes) ?? 660 }
        set {
            defaults?.set(newValue, forKey: Keys.weekendDeadlineMinutes)
            defaults?.synchronize()
        }
    }

    /// Returns the effective cutoff minutes for a given date, considering weekday/weekend settings.
    /// Use this instead of `morningCutoffMinutes` when you need the day-aware value.
    static func getCutoffMinutes(for date: Date) -> Int {
        guard customDeadlinesEnabled else {
            return morningCutoffMinutes
        }
        let isWeekend = Calendar.current.isDateInWeekend(date)
        return isWeekend ? weekendDeadlineMinutes : weekdayDeadlineMinutes
    }

    // MARK: - Emergency Unlock

    /// Whether the last unlock was an emergency unlock (user bypassed habits).
    /// The main app checks this to break the streak.
    static var wasEmergencyUnlock: Bool {
        get { defaults?.bool(forKey: Keys.wasEmergencyUnlock) ?? false }
        set {
            defaults?.set(newValue, forKey: Keys.wasEmergencyUnlock)
            defaults?.synchronize()
        }
    }

    /// Emergency unlock - removes shields but marks it as a bypass.
    /// This should break the user's streak when the main app detects it.
    static func emergencyUnlock() {
        wasEmergencyUnlock = true
        isDayLockedIn = true
        lastLockInDate = Date()
    }

    // MARK: - Helpers

    /// Resets the lock status for a new day.
    /// Called by the DeviceActivityMonitor at the start of the morning period.
    static func resetForNewDay() {
        isDayLockedIn = false
        wasEmergencyUnlock = false
    }

    /// Checks if shields should currently be applied.
    /// Returns true if:
    /// - App locking is enabled
    /// - A blocking start time is configured
    /// - The user hasn't locked in today
    /// - We're past the blocking start time
    ///
    /// NOTE: Shields stay active until habits are complete - no auto-unlock at cutoff.
    static func shouldApplyShields() -> Bool {
        guard appLockingEnabled else { return false }
        guard hasConfiguredBlockingStartTime else { return false }
        guard !hasLockedInToday else { return false }

        // Check if we're past the blocking start time
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let currentMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)

        // Apps are blocked from start time onwards until habits are complete
        return currentMinutes >= blockingStartMinutes
    }

    /// Debug description of current state
    static var debugDescription: String {
        """
        AppLockingDataStore:
        - Enabled: \(appLockingEnabled)
        - Blocking Start: \(blockingStartMinutes) minutes
        - Cutoff: \(morningCutoffMinutes) minutes
        - Custom Deadlines Enabled: \(customDeadlinesEnabled)
        - Weekday Deadline: \(weekdayDeadlineMinutes) minutes
        - Weekend Deadline: \(weekendDeadlineMinutes) minutes
        - Effective Cutoff Today: \(getCutoffMinutes(for: Date())) minutes
        - Day Locked In: \(isDayLockedIn)
        - Has Locked In Today: \(hasLockedInToday)
        - Was Emergency Unlock: \(wasEmergencyUnlock)
        - Should Apply Shields: \(shouldApplyShields())
        """
    }
}

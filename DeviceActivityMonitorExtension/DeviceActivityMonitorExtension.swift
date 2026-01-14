import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

/// Extension that monitors the morning routine schedule and applies/removes app shields.
/// This runs as a separate process from the main app.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    let store = ManagedSettingsStore()

    // MARK: - Schedule Callbacks

    /// Called when the morning blocking period starts (at midnight).
    /// This applies shields to block the user's selected apps.
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        guard activity == .morningRoutine else { return }
        guard AppLockingDataStore.appLockingEnabled else { return }

        // Reset lock status for the new day
        AppLockingDataStore.resetForNewDay()

        // Apply shields if user hasn't already completed habits
        if !AppLockingDataStore.hasLockedInToday {
            applyShields()
        }
    }

    /// Called when the morning blocking period ends (at cutoff time).
    /// This removes shields regardless of whether habits were completed.
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        guard activity == .morningRoutine else { return }

        // Cutoff time reached - remove all shields
        store.clearAllSettings()
    }

    /// Called when a usage threshold is reached (not used in our implementation).
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // Not used for morning routine blocking
    }

    // MARK: - Shield Management

    /// Applies shields to the user's selected apps.
    private func applyShields() {
        guard let defaults = UserDefaults(suiteName: AppLockingDataStore.suiteName),
              let data = defaults.data(forKey: "screenTime_selectedApps") else {
            return
        }

        do {
            let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)

            if !selection.applicationTokens.isEmpty {
                store.shield.applications = selection.applicationTokens
            }

            if !selection.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(selection.categoryTokens)
            }
        } catch {
            // Failed to decode - can't apply shields
        }
    }
}

// MARK: - DeviceActivityName Extension

extension DeviceActivityName {
    static let morningRoutine = Self("morningRoutine")
}

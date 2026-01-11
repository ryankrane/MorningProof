import Foundation
import SwiftData

/// Manages migration from UserDefaults to SwiftData
@MainActor
class MigrationManager {
    static let shared = MigrationManager()

    private let migrationVersionKey = "morningproof_migration_version"
    private let currentMigrationVersion = 1

    private init() {}

    /// Check if migration is needed and perform it
    func migrateIfNeeded(modelContext: ModelContext) async {
        let currentVersion = UserDefaults.standard.integer(forKey: migrationVersionKey)

        guard currentVersion < currentMigrationVersion else {
            print("Migration: Already at version \(currentVersion), no migration needed")
            return
        }

        print("Migration: Starting migration from version \(currentVersion) to \(currentMigrationVersion)")

        // Migration v0 -> v1: UserDefaults to SwiftData
        if currentVersion < 1 {
            await migrateFromUserDefaults(to: modelContext)
        }

        UserDefaults.standard.set(currentMigrationVersion, forKey: migrationVersionKey)
        print("Migration: Complete, now at version \(currentMigrationVersion)")
    }

    /// Check if there's existing data that needs migration
    func needsMigration() -> Bool {
        let currentVersion = UserDefaults.standard.integer(forKey: migrationVersionKey)
        return currentVersion < currentMigrationVersion && hasLegacyData()
    }

    /// Check if there's legacy data in UserDefaults
    private func hasLegacyData() -> Bool {
        let storage = StorageService()
        return storage.loadMorningProofSettings() != nil ||
               storage.loadHabitConfigs() != nil ||
               storage.hasCompletedOnboarding()
    }

    /// Migrate all data from UserDefaults to SwiftData
    private func migrateFromUserDefaults(to context: ModelContext) async {
        let storage = StorageService()

        print("Migration: Reading legacy data from UserDefaults...")

        // 1. Migrate Settings
        if let settings = storage.loadMorningProofSettings() {
            print("Migration: Migrating settings...")
            let sdSettings = createSDSettings(from: settings)
            context.insert(sdSettings)
        }

        // 2. Migrate Habit Configs
        if let configs = storage.loadHabitConfigs() {
            print("Migration: Migrating \(configs.count) habit configs...")
            for config in configs {
                let sdConfig = SDHabitConfig(from: config)
                context.insert(sdConfig)
            }
        }

        // 3. Migrate Daily Logs (last 365 days)
        print("Migration: Migrating daily logs...")
        let calendar = Calendar.current
        var migratedLogs = 0

        for dayOffset in 0..<365 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()),
               let log = storage.loadDailyLog(for: date) {
                let sdLog = createSDDailyLog(from: log, context: context)
                context.insert(sdLog)
                migratedLogs += 1
            }
        }
        print("Migration: Migrated \(migratedLogs) daily logs")

        // 4. Migrate Achievements
        let achievements = storage.loadAchievements()
        if !achievements.unlockedAchievements.isEmpty {
            print("Migration: Migrating \(achievements.unlockedAchievements.count) achievements...")
            for (id, date) in achievements.unlockedAchievements {
                let sdAchievement = SDUnlockedAchievement(achievementId: id, unlockedDate: date)
                context.insert(sdAchievement)
            }
        }

        // 5. Migrate Onboarding status
        if storage.hasCompletedOnboarding() {
            UserDefaults.standard.set(true, forKey: "swiftdata_onboarding_completed")
        }

        // Save all migrations
        do {
            try context.save()
            print("Migration: Successfully saved all data to SwiftData")
        } catch {
            print("Migration: Failed to save - \(error)")
            await MainActor.run {
                CrashReportingService.shared.recordError(error, userInfo: ["context": "migration"])
            }
        }
    }

    // MARK: - Conversion Helpers

    private func createSDSettings(from settings: MorningProofSettings) -> SDSettings {
        let sd = SDSettings()
        sd.userName = settings.userName
        sd.morningCutoffMinutes = settings.morningCutoffMinutes
        sd.stepGoal = settings.stepGoal
        sd.sleepGoalHours = settings.sleepGoalHours
        sd.customSleepGoal = settings.customSleepGoal
        sd.customStepGoal = settings.customStepGoal
        sd.currentStreak = settings.currentStreak
        sd.longestStreak = settings.longestStreak
        sd.lastPerfectMorningDate = settings.lastPerfectMorningDate
        sd.totalPerfectMornings = settings.totalPerfectMornings
        sd.notificationsEnabled = settings.notificationsEnabled
        sd.morningReminderTime = settings.morningReminderTime
        sd.countdownWarnings = settings.countdownWarnings
        sd.appLockingEnabled = settings.appLockingEnabled
        sd.lockedApps = settings.lockedApps
        sd.lockGracePeriod = settings.lockGracePeriod
        sd.strictModeEnabled = settings.strictModeEnabled
        sd.allowStreakRecovery = settings.allowStreakRecovery
        sd.weeklyPerfectMorningsGoal = settings.weeklyPerfectMorningsGoal
        return sd
    }

    private func createSDDailyLog(from log: DailyLog, context: ModelContext) -> SDDailyLog {
        let sd = SDDailyLog(date: log.date)
        sd.id = log.id
        sd.morningScore = log.morningScore
        sd.allCompletedBeforeCutoff = log.allCompletedBeforeCutoff

        for completion in log.completions {
            let sdCompletion = SDHabitCompletion(from: completion)
            sdCompletion.dailyLog = sd
            sd.completions.append(sdCompletion)
        }

        return sd
    }
}

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
            MPLogger.debug("Already at version \(currentVersion), no migration needed", category: MPLogger.migration)
            return
        }

        MPLogger.info("Starting migration from version \(currentVersion) to \(currentMigrationVersion)", category: MPLogger.migration)

        // Migration v0 -> v1: UserDefaults to SwiftData
        if currentVersion < 1 {
            await migrateFromUserDefaults(to: modelContext)
        }

        UserDefaults.standard.set(currentMigrationVersion, forKey: migrationVersionKey)
        MPLogger.info("Migration complete, now at version \(currentMigrationVersion)", category: MPLogger.migration)
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

        MPLogger.debug("Reading legacy data from UserDefaults", category: MPLogger.migration)

        // 1. Migrate Settings
        if let settings = storage.loadMorningProofSettings() {
            MPLogger.debug("Migrating settings", category: MPLogger.migration)
            let sdSettings = createSDSettings(from: settings)
            context.insert(sdSettings)
        }

        // 2. Migrate Habit Configs
        if let configs = storage.loadHabitConfigs() {
            MPLogger.debug("Migrating \(configs.count) habit configs", category: MPLogger.migration)
            for config in configs {
                let sdConfig = SDHabitConfig(from: config)
                context.insert(sdConfig)
            }
        }

        // 3. Migrate Daily Logs (last 365 days)
        MPLogger.debug("Migrating daily logs", category: MPLogger.migration)
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
        MPLogger.debug("Migrated \(migratedLogs) daily logs", category: MPLogger.migration)

        // 4. Migrate Achievements
        let achievements = storage.loadAchievements()
        if !achievements.unlockedAchievements.isEmpty {
            MPLogger.debug("Migrating \(achievements.unlockedAchievements.count) achievements", category: MPLogger.migration)
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
            MPLogger.info("Successfully saved all data to SwiftData", category: MPLogger.migration)
        } catch {
            MPLogger.error("Failed to save migration data", error: error, category: MPLogger.migration)
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
        sd.blockingStartMinutes = settings.blockingStartMinutes
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

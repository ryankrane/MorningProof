import Foundation
import SwiftData

// MARK: - Settings Model

@Model
final class SDSettings {
    @Attribute(.unique) var id: UUID

    // User Info
    var userName: String

    // Timing
    var morningCutoffMinutes: Int

    // Habit Goals
    var stepGoal: Int
    var sleepGoalHours: Int
    var customSleepGoal: Double
    var customStepGoal: Int

    // Streak Tracking
    var currentStreak: Int
    var longestStreak: Int
    var lastPerfectMorningDate: Date?
    var totalPerfectMornings: Int

    // Notifications
    var notificationsEnabled: Bool
    var morningReminderTime: Int
    var countdownWarnings: [Int]

    // App Locking
    var appLockingEnabled: Bool
    var lockedApps: [String]
    var blockingStartMinutes: Int  // When app blocking starts (minutes from midnight, e.g. 360 = 6 AM)

    // Accountability
    var strictModeEnabled: Bool
    var allowStreakRecovery: Bool

    // Goals
    var weeklyPerfectMorningsGoal: Int

    // Custom per-day deadlines
    // Mode: 0 = same every day, 1 = weekday/weekend, 2 = each day
    var deadlineCustomizationMode: Int
    var weekdayDeadlineMinutes: Int
    var weekendDeadlineMinutes: Int
    // Per-day deadlines: index 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    var perDayDeadlineMinutes: [Int]

    // Legacy support (maps to mode 1 if true)
    var customDeadlinesEnabled: Bool {
        get { deadlineCustomizationMode == 1 }
        set { deadlineCustomizationMode = newValue ? 1 : 0 }
    }

    init() {
        self.id = UUID()
        self.userName = ""
        self.morningCutoffMinutes = 540 // 9:00 AM
        self.stepGoal = 500
        self.sleepGoalHours = 7
        self.customSleepGoal = 7.0
        self.customStepGoal = 500
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastPerfectMorningDate = nil
        self.totalPerfectMornings = 0
        self.notificationsEnabled = true
        self.morningReminderTime = 420 // 7:00 AM
        self.countdownWarnings = [15, 5, 1]
        self.appLockingEnabled = false
        self.lockedApps = []
        self.blockingStartMinutes = 0  // 0 = not configured, user must set
        self.strictModeEnabled = true
        self.allowStreakRecovery = false
        self.weeklyPerfectMorningsGoal = 5
        self.deadlineCustomizationMode = 0  // Same every day
        self.weekdayDeadlineMinutes = 540   // 9:00 AM
        self.weekendDeadlineMinutes = 660   // 11:00 AM
        // Default all days to 9:00 AM
        self.perDayDeadlineMinutes = [540, 540, 540, 540, 540, 540, 540]
    }
}

// MARK: - Habit Config Model

@Model
final class SDHabitConfig {
    @Attribute(.unique) var habitTypeRaw: String
    var isEnabled: Bool
    var goal: Int
    var displayOrder: Int

    var habitType: HabitType? {
        HabitType(rawValue: habitTypeRaw)
    }

    init(habitType: HabitType, isEnabled: Bool = true, goal: Int? = nil, displayOrder: Int = 0) {
        self.habitTypeRaw = habitType.rawValue
        self.isEnabled = isEnabled
        self.goal = goal ?? habitType.defaultGoal
        self.displayOrder = displayOrder
    }

    convenience init(from config: HabitConfig) {
        self.init(
            habitType: config.habitType,
            isEnabled: config.isEnabled,
            goal: config.goal,
            displayOrder: config.displayOrder
        )
    }
}

// MARK: - Daily Log Model

@Model
final class SDDailyLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    @Relationship(deleteRule: .cascade, inverse: \SDHabitCompletion.dailyLog)
    var completions: [SDHabitCompletion]
    var morningScore: Int
    var allCompletedBeforeCutoff: Bool

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.completions = []
        self.morningScore = 0
        self.allCompletedBeforeCutoff = false
    }

    convenience init(from log: DailyLog) {
        self.init(date: log.date)
        self.id = log.id
        self.morningScore = log.morningScore
        self.allCompletedBeforeCutoff = log.allCompletedBeforeCutoff
        // Note: completions should be added separately after creation
    }
}

// MARK: - Habit Completion Model

@Model
final class SDHabitCompletion {
    @Attribute(.unique) var id: UUID
    var habitTypeRaw: String
    var date: Date
    var isCompleted: Bool
    var score: Int
    var completedAt: Date?

    // Verification data (flattened)
    var photoURL: String?
    var aiScore: Int?
    var aiFeedback: String?
    var stepCount: Int?
    var sleepHours: Double?
    var textEntry: String?

    // Relationship
    var dailyLog: SDDailyLog?

    var habitType: HabitType? {
        HabitType(rawValue: habitTypeRaw)
    }

    init(habitType: HabitType, date: Date = Date()) {
        self.id = UUID()
        self.habitTypeRaw = habitType.rawValue
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = false
        self.score = 0
        self.completedAt = nil
    }

    convenience init(from completion: HabitCompletion) {
        self.init(habitType: completion.habitType, date: completion.date)
        self.id = completion.id
        self.isCompleted = completion.isCompleted
        self.score = completion.score
        self.completedAt = completion.completedAt

        if let data = completion.verificationData {
            self.photoURL = data.photoURL
            self.aiScore = data.aiScore
            self.aiFeedback = data.aiFeedback
            self.stepCount = data.stepCount
            self.sleepHours = data.sleepHours
            self.textEntry = data.textEntry
        }
    }
}

// MARK: - Streak Data Model (for historical tracking)

@Model
final class SDStreakRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var wasCompleted: Bool

    init(date: Date, wasCompleted: Bool = true) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.wasCompleted = wasCompleted
    }
}

// MARK: - Achievement Model

@Model
final class SDUnlockedAchievement {
    @Attribute(.unique) var achievementId: String
    var unlockedDate: Date

    init(achievementId: String, unlockedDate: Date = Date()) {
        self.achievementId = achievementId
        self.unlockedDate = unlockedDate
    }
}

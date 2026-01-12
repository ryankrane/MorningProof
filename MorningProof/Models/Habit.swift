import Foundation
import SwiftData

// Verification tier determines how the habit is confirmed
enum HabitVerificationTier: Int, Codable, CaseIterable {
    case aiVerified = 1      // Requires AI analysis (e.g., bed photo)
    case autoTracked = 2     // Auto-tracked via HealthKit
    case honorSystem = 3     // Manual confirmation with friction

    var description: String {
        switch self {
        case .aiVerified: return "AI Verified"
        case .autoTracked: return "Auto-Tracked"
        case .honorSystem: return "Honor System"
        }
    }
}

// Predefined habit types - Core 9 high-value habits
enum HabitType: String, Codable, CaseIterable, Identifiable {
    case madeBed = "made_bed"
    case sleepDuration = "sleep_duration"
    case coldShower = "cold_shower"
    case noSnooze = "no_snooze"
    case morningWorkout = "morning_workout"
    case sunlightExposure = "sunlight_exposure"
    case morningStretch = "morning_stretch"
    case morningSteps = "morning_steps"
    case meditation = "meditation"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .madeBed: return "Made Bed"
        case .sleepDuration: return "Sleep Goal"
        case .coldShower: return "Cold Shower"
        case .noSnooze: return "No Snooze"
        case .morningWorkout: return "Workout"
        case .sunlightExposure: return "Sunlight"
        case .morningStretch: return "Morning Stretch"
        case .morningSteps: return "Morning Walk"
        case .meditation: return "Meditation"
        }
    }

    var icon: String {
        switch self {
        case .madeBed: return "bed.double.fill"
        case .sleepDuration: return "moon.zzz.fill"
        case .coldShower: return "snowflake"
        case .noSnooze: return "alarm.fill"
        case .morningWorkout: return "figure.strengthtraining.traditional"
        case .sunlightExposure: return "sun.max.fill"
        case .morningStretch: return "figure.flexibility"
        case .morningSteps: return "figure.walk"
        case .meditation: return "brain.head.profile"
        }
    }

    var tier: HabitVerificationTier {
        switch self {
        case .madeBed: return .aiVerified
        case .morningSteps, .sleepDuration, .morningWorkout: return .autoTracked
        case .coldShower, .noSnooze, .sunlightExposure, .morningStretch, .meditation: return .honorSystem
        }
    }

    var defaultGoal: Int {
        switch self {
        case .madeBed: return 7 // Score out of 10
        case .morningSteps: return 500 // Steps
        case .sleepDuration: return 7 // Hours
        case .sunlightExposure: return 10 // Minutes
        case .morningWorkout: return 20 // Minutes
        case .coldShower, .noSnooze, .morningStretch, .meditation: return 1 // Binary
        }
    }

    var requiresHoldToConfirm: Bool {
        // All habits use tap-to-complete for better UX
        return false
    }

    var requiresTextEntry: Bool {
        return false // None of the core habits require text entry
    }

    var minimumTextLength: Int {
        return 0
    }

    var textEntryPrompt: String {
        return ""
    }

    var description: String {
        switch self {
        case .madeBed: return "Make your bed to start the day with accomplishment"
        case .sleepDuration: return "Track your sleep quality"
        case .coldShower: return "Cold exposure for energy and focus"
        case .noSnooze: return "Get up on the first alarm"
        case .morningWorkout: return "Exercise to boost energy and mood"
        case .sunlightExposure: return "Natural light to regulate your circadian rhythm"
        case .morningStretch: return "Stretch to wake up your body"
        case .morningSteps: return "Get moving with a morning walk"
        case .meditation: return "Start with a clear, calm mind"
        }
    }
}

// User's habit configuration
struct HabitConfig: Codable, Identifiable {
    var id: String { habitType.rawValue }
    var habitType: HabitType
    var isEnabled: Bool
    var goal: Int
    var displayOrder: Int

    init(habitType: HabitType, isEnabled: Bool = true, goal: Int? = nil, displayOrder: Int = 0) {
        self.habitType = habitType
        self.isEnabled = isEnabled
        self.goal = goal ?? habitType.defaultGoal
        self.displayOrder = displayOrder
    }

    static var defaultConfigs: [HabitConfig] {
        HabitType.allCases.enumerated().map { index, type in
            HabitConfig(
                habitType: type,
                isEnabled: [.madeBed, .sleepDuration, .coldShower, .noSnooze].contains(type),
                displayOrder: index
            )
        }
    }
}

// A single habit completion record
struct HabitCompletion: Codable, Identifiable {
    var id: UUID
    var habitType: HabitType
    var date: Date
    var isCompleted: Bool
    var score: Int // 0-100, percentage of goal achieved
    var verificationData: VerificationData?
    var completedAt: Date?

    struct VerificationData: Codable {
        var photoURL: String?
        var aiScore: Int?
        var aiFeedback: String?
        var stepCount: Int?
        var sleepHours: Double?
        var textEntry: String?
    }

    init(habitType: HabitType, date: Date = Date()) {
        self.id = UUID()
        self.habitType = habitType
        self.date = Calendar.current.startOfDay(for: date)
        self.isCompleted = false
        self.score = 0
        self.verificationData = nil
        self.completedAt = nil
    }
}

// Daily log containing all habit completions for a day
struct DailyLog: Codable, Identifiable {
    var id: UUID
    var date: Date
    var completions: [HabitCompletion]
    var morningScore: Int // 0-100
    var allCompletedBeforeCutoff: Bool

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.completions = []
        self.morningScore = 0
        self.allCompletedBeforeCutoff = false
    }

    mutating func calculateScore(enabledHabits: [HabitConfig]) {
        let enabledTypes = Set(enabledHabits.filter { $0.isEnabled }.map { $0.habitType })
        let relevantCompletions = completions.filter { enabledTypes.contains($0.habitType) }

        guard !relevantCompletions.isEmpty else {
            morningScore = 0
            return
        }

        let totalScore = relevantCompletions.reduce(0) { $0 + $1.score }
        morningScore = totalScore / relevantCompletions.count
    }
}

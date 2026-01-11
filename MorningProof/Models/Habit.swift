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

// Predefined habit types
enum HabitType: String, Codable, CaseIterable, Identifiable {
    case madeBed = "made_bed"
    case morningSteps = "morning_steps"
    case sleepDuration = "sleep_duration"
    case drankWater = "drank_water"
    case morningStretch = "morning_stretch"
    case noSnooze = "no_snooze"
    case journaling = "journaling"
    case meditation = "meditation"
    case breakfast = "breakfast"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .madeBed: return "Made Bed"
        case .morningSteps: return "Morning Walk"
        case .sleepDuration: return "Sleep Goal"
        case .drankWater: return "Drank Water"
        case .morningStretch: return "Morning Stretch"
        case .noSnooze: return "No Snooze"
        case .journaling: return "Journaling"
        case .meditation: return "Meditation"
        case .breakfast: return "Made Breakfast"
        }
    }

    var icon: String {
        switch self {
        case .madeBed: return "bed.double.fill"
        case .morningSteps: return "figure.walk"
        case .sleepDuration: return "moon.zzz.fill"
        case .drankWater: return "drop.fill"
        case .morningStretch: return "figure.flexibility"
        case .noSnooze: return "alarm.fill"
        case .journaling: return "book.fill"
        case .meditation: return "brain.head.profile"
        case .breakfast: return "fork.knife"
        }
    }

    var tier: HabitVerificationTier {
        switch self {
        case .madeBed: return .aiVerified
        case .morningSteps, .sleepDuration: return .autoTracked
        case .drankWater, .morningStretch, .noSnooze, .journaling, .meditation, .breakfast: return .honorSystem
        }
    }

    var defaultGoal: Int {
        switch self {
        case .madeBed: return 7 // Score out of 10
        case .morningSteps: return 500 // Steps
        case .sleepDuration: return 7 // Hours
        default: return 1 // Binary
        }
    }

    var requiresHoldToConfirm: Bool {
        switch self {
        case .drankWater, .morningStretch: return true
        default: return false
        }
    }

    var requiresTextEntry: Bool {
        self == .journaling
    }

    var minimumTextLength: Int {
        self == .journaling ? 10 : 0
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
                isEnabled: [.madeBed, .morningSteps, .sleepDuration, .drankWater].contains(type),
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

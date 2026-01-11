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
    // Original habits
    case madeBed = "made_bed"
    case morningSteps = "morning_steps"
    case sleepDuration = "sleep_duration"
    case drankWater = "drank_water"
    case morningStretch = "morning_stretch"
    case noSnooze = "no_snooze"
    case journaling = "journaling"
    case meditation = "meditation"
    case breakfast = "breakfast"

    // Health & Biohacking
    case coldShower = "cold_shower"
    case sunlightExposure = "sunlight_exposure"
    case morningWorkout = "morning_workout"
    case takeVitamins = "take_vitamins"
    case skincareRoutine = "skincare_routine"

    // Mindfulness & Mental
    case gratitude = "gratitude"
    case dailyGoals = "daily_goals"
    case affirmations = "affirmations"
    case morningReading = "morning_reading"

    // Digital Wellness
    case screenFreeMorning = "screen_free_morning"
    case reviewCalendar = "review_calendar"

    // Self-Care
    case getDressed = "get_dressed"
    case oralCare = "oral_care"

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
        case .coldShower: return "Cold Shower"
        case .sunlightExposure: return "Sunlight"
        case .morningWorkout: return "Workout"
        case .takeVitamins: return "Vitamins"
        case .skincareRoutine: return "Skincare"
        case .gratitude: return "Gratitude"
        case .dailyGoals: return "Daily Goals"
        case .affirmations: return "Affirmations"
        case .morningReading: return "Reading"
        case .screenFreeMorning: return "Screen-Free"
        case .reviewCalendar: return "Review Calendar"
        case .getDressed: return "Get Dressed"
        case .oralCare: return "Oral Care"
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
        case .coldShower: return "snowflake"
        case .sunlightExposure: return "sun.max.fill"
        case .morningWorkout: return "figure.strengthtraining.traditional"
        case .takeVitamins: return "pill.fill"
        case .skincareRoutine: return "face.smiling.fill"
        case .gratitude: return "heart.fill"
        case .dailyGoals: return "target"
        case .affirmations: return "text.bubble.fill"
        case .morningReading: return "book.closed.fill"
        case .screenFreeMorning: return "iphone.slash"
        case .reviewCalendar: return "calendar.badge.clock"
        case .getDressed: return "tshirt.fill"
        case .oralCare: return "mouth.fill"
        }
    }

    var tier: HabitVerificationTier {
        switch self {
        case .madeBed: return .aiVerified
        case .morningSteps, .sleepDuration, .morningWorkout: return .autoTracked
        default: return .honorSystem
        }
    }

    var defaultGoal: Int {
        switch self {
        case .madeBed: return 7 // Score out of 10
        case .morningSteps: return 500 // Steps
        case .sleepDuration: return 7 // Hours
        case .morningReading: return 10 // Minutes
        case .sunlightExposure: return 10 // Minutes
        case .morningWorkout: return 20 // Minutes
        default: return 1 // Binary
        }
    }

    var requiresHoldToConfirm: Bool {
        switch self {
        case .drankWater, .morningStretch, .coldShower, .sunlightExposure,
             .skincareRoutine, .screenFreeMorning, .oralCare:
            return true
        default:
            return false
        }
    }

    var requiresTextEntry: Bool {
        switch self {
        case .journaling, .gratitude, .dailyGoals:
            return true
        default:
            return false
        }
    }

    var minimumTextLength: Int {
        switch self {
        case .journaling: return 10
        case .gratitude: return 5
        case .dailyGoals: return 5
        default: return 0
        }
    }

    var textEntryPrompt: String {
        switch self {
        case .journaling: return "Write about your morning thoughts..."
        case .gratitude: return "What are you grateful for today?"
        case .dailyGoals: return "What are your top 3 priorities today?"
        default: return ""
        }
    }

    var description: String {
        switch self {
        case .madeBed: return "Make your bed to start the day with accomplishment"
        case .morningSteps: return "Get moving with a morning walk"
        case .sleepDuration: return "Track your sleep quality"
        case .drankWater: return "Hydrate first thing in the morning"
        case .morningStretch: return "Stretch to wake up your body"
        case .noSnooze: return "Get up on the first alarm"
        case .journaling: return "Reflect on your thoughts"
        case .meditation: return "Start with a clear, calm mind"
        case .breakfast: return "Fuel your body for the day"
        case .coldShower: return "Cold exposure for energy and focus"
        case .sunlightExposure: return "Natural light to regulate your circadian rhythm"
        case .morningWorkout: return "Exercise to boost energy and mood"
        case .takeVitamins: return "Support your health with supplements"
        case .skincareRoutine: return "Take care of your skin"
        case .gratitude: return "Cultivate a positive mindset"
        case .dailyGoals: return "Set intentions for a productive day"
        case .affirmations: return "Positive self-talk to build confidence"
        case .morningReading: return "Learn something new each morning"
        case .screenFreeMorning: return "Avoid screens for a mindful start"
        case .reviewCalendar: return "Know what's ahead for your day"
        case .getDressed: return "Get out of pajamas and ready for the day"
        case .oralCare: return "Brush and floss for dental health"
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

import Foundation
import SwiftData

// Functional category for grouping habits in settings
enum HabitCategory: String, CaseIterable {
    case wakeUp = "Wake Up"
    case movement = "Movement"
    case wellness = "Wellness"

    var icon: String {
        switch self {
        case .wakeUp: return "sunrise.fill"
        case .movement: return "figure.run"
        case .wellness: return "heart.fill"
        }
    }
}

// Verification tier determines how the habit is confirmed
enum HabitVerificationTier: Int, Codable, CaseIterable {
    case aiVerified = 1      // Requires AI analysis (e.g., bed photo)
    case autoTracked = 2     // Auto-tracked via Apple Health
    case honorSystem = 3     // Manual confirmation with friction

    var description: String {
        switch self {
        case .aiVerified: return "AI Verified"
        case .autoTracked: return "Apple Health"
        case .honorSystem: return "Honor System"
        }
    }

    var sectionTitle: String {
        switch self {
        case .aiVerified: return "Photo Verified"
        case .autoTracked: return "Apple Health"
        case .honorSystem: return "Hold to Confirm"
        }
    }

    var icon: String {
        switch self {
        case .aiVerified: return "camera.fill"
        case .autoTracked: return "heart.fill"
        case .honorSystem: return "hand.tap.fill"
        }
    }
}

// Predefined habit types - Core 10 high-value habits
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
    case hydration = "hydration"

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
        case .hydration: return "Hydration"
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
        case .hydration: return "drop.fill"
        }
    }

    var tier: HabitVerificationTier {
        switch self {
        case .madeBed, .sunlightExposure, .hydration: return .aiVerified
        case .morningSteps, .sleepDuration, .morningWorkout: return .autoTracked
        case .coldShower, .noSnooze, .morningStretch, .meditation: return .honorSystem
        }
    }

    var category: HabitCategory {
        switch self {
        case .noSnooze, .madeBed, .sleepDuration: return .wakeUp
        case .morningStretch, .morningWorkout, .morningSteps: return .movement
        case .meditation, .coldShower, .sunlightExposure, .hydration: return .wellness
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
        case .hydration: return 1 // Binary - just verify water
        }
    }

    var requiresHoldToConfirm: Bool {
        // Honor system habits require hold to prevent accidental completion
        return self.tier == .honorSystem
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
        case .hydration: return "Start your day hydrated with a glass of water"
        }
    }

    /// Short, exciting explanation for onboarding
    var howItWorksShort: String {
        switch self {
        case .madeBed: return "Snap a photo — AI verifies it's made"
        case .sunlightExposure: return "Take a photo outside — AI verifies the daylight"
        case .hydration: return "Snap your water — AI confirms you're hydrated"
        case .sleepDuration: return "Syncs automatically from Apple Health"
        case .morningSteps: return "Syncs your steps from Apple Health"
        case .morningWorkout: return "Detected automatically from Apple Health"
        case .coldShower: return "Hold to confirm you took the plunge"
        case .noSnooze: return "Hold to confirm you didn't snooze"
        case .morningStretch: return "Hold to confirm you stretched"
        case .meditation: return "Hold to confirm you meditated"
        }
    }

    /// Detailed explanation for settings (includes fallbacks)
    var howItWorksDetailed: String {
        switch self {
        case .madeBed: return "Snap a photo of your bed. We'll check if it's made — sheets smooth, pillows in place."
        case .sunlightExposure: return "Take a photo outside or by a window. We'll verify you got some natural light."
        case .hydration: return "Snap a photo of your glass of water. We'll confirm you're starting hydrated."
        case .sleepDuration: return "Syncs automatically from Apple Health. No Apple Watch? You can enter manually."
        case .morningSteps: return "Steps sync from Apple Health. If unavailable, hold to confirm you walked."
        case .morningWorkout: return "Detected from Apple Health (workout, 1000+ steps, or 100+ calories). No data? Hold to confirm."
        case .coldShower: return "Hold to confirm you took a cold shower this morning."
        case .noSnooze: return "Hold to confirm you got up without hitting snooze."
        case .morningStretch: return "Hold to confirm you did your morning stretch."
        case .meditation: return "Hold to confirm you completed your meditation."
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
    var activeDays: Set<Int> // 1=Sunday...7=Saturday (matches Calendar.weekday)

    init(habitType: HabitType, isEnabled: Bool = true, goal: Int? = nil, displayOrder: Int = 0, activeDays: Set<Int>? = nil) {
        self.habitType = habitType
        self.isEnabled = isEnabled
        self.goal = goal ?? habitType.defaultGoal
        self.displayOrder = displayOrder
        self.activeDays = activeDays ?? Set(1...7) // Default to all days
    }

    // Custom decoder for backward compatibility (existing users get all days)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        habitType = try container.decode(HabitType.self, forKey: .habitType)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        goal = try container.decode(Int.self, forKey: .goal)
        displayOrder = try container.decode(Int.self, forKey: .displayOrder)
        activeDays = try container.decodeIfPresent(Set<Int>.self, forKey: .activeDays) ?? Set(1...7)
    }

    private enum CodingKeys: String, CodingKey {
        case habitType, isEnabled, goal, displayOrder, activeDays
    }

    static var defaultConfigs: [HabitConfig] {
        HabitType.allCases.enumerated().map { index, type in
            HabitConfig(
                habitType: type,
                isEnabled: [.madeBed, .sleepDuration, .coldShower, .morningSteps].contains(type),
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
        var workoutDetected: Bool?
        var isFromHealthKit: Bool?  // Track if data came from HealthKit vs manual entry
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
    var isDayLockedIn: Bool // True when user has explicitly locked in the day
    var lockedInAt: Date? // Timestamp when day was locked in

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.completions = []
        self.morningScore = 0
        self.allCompletedBeforeCutoff = false
        self.isDayLockedIn = false
        self.lockedInAt = nil
    }

    // Custom decoder to handle old data without new fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        completions = try container.decode([HabitCompletion].self, forKey: .completions)
        morningScore = try container.decode(Int.self, forKey: .morningScore)
        allCompletedBeforeCutoff = try container.decode(Bool.self, forKey: .allCompletedBeforeCutoff)
        // Default to false if not present in old data
        isDayLockedIn = try container.decodeIfPresent(Bool.self, forKey: .isDayLockedIn) ?? false
        lockedInAt = try container.decodeIfPresent(Date.self, forKey: .lockedInAt)
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, completions, morningScore, allCompletedBeforeCutoff, isDayLockedIn, lockedInAt
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

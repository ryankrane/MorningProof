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
    case journaling = 3      // Text entry habits (gratitude, planning)
    case honorSystem = 4     // Manual confirmation with friction

    var description: String {
        switch self {
        case .aiVerified: return "AI Verified"
        case .autoTracked: return "Apple Health"
        case .journaling: return "Journaling"
        case .honorSystem: return "Honor System"
        }
    }

    var sectionTitle: String {
        switch self {
        case .aiVerified: return "AI Verified"
        case .autoTracked: return "Apple Health"
        case .journaling: return "Journaling"
        case .honorSystem: return "Self-Reported"
        }
    }

    var icon: String {
        switch self {
        case .aiVerified: return "sparkles"
        case .autoTracked: return "heart.fill"
        case .journaling: return "square.and.pencil"
        case .honorSystem: return "hand.tap.fill"
        }
    }
}

// Predefined habit types - Core habits
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
    case prayer = "prayer"
    case reading = "reading"
    case walkDog = "walk_dog"
    // New AI-verified habits
    case healthyBreakfast = "healthy_breakfast"
    case morningJournal = "morning_journal"
    case vitamins = "vitamins"
    case skincare = "skincare"
    case mealPrep = "meal_prep"
    // New honor system habits
    case gratitude = "gratitude"
    case noPhoneFirst30 = "no_phone_first_30"
    case dailyPlanning = "daily_planning"
    case breathingExercises = "breathing_exercises"
    case floss = "floss"

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
        case .morningSteps: return "Step Goal"
        case .meditation: return "Meditation"
        case .hydration: return "Hydration"
        case .prayer: return "Prayer"
        case .reading: return "Reading"
        case .walkDog: return "Walk the Dog"
        case .healthyBreakfast: return "Healthy Breakfast"
        case .morningJournal: return "Morning Journal"
        case .vitamins: return "Vitamins"
        case .skincare: return "Skincare"
        case .mealPrep: return "Meal Prep"
        case .gratitude: return "Gratitude"
        case .noPhoneFirst30: return "No Phone (30 min)"
        case .dailyPlanning: return "Daily Planning"
        case .breathingExercises: return "Breathing"
        case .floss: return "Floss"
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
        case .prayer: return "hands.sparkles.fill"
        case .reading: return "book.fill"
        case .walkDog: return "dog.fill"
        case .healthyBreakfast: return "fork.knife"
        case .morningJournal: return "book.closed.fill"
        case .vitamins: return "pills.fill"
        case .skincare: return "face.smiling.fill"
        case .mealPrep: return "takeoutbag.and.cup.and.straw.fill"
        case .gratitude: return "heart.text.square.fill"
        case .noPhoneFirst30: return "iphone.slash"
        case .dailyPlanning: return "list.clipboard.fill"
        case .breathingExercises: return "wind"
        case .floss: return "mouth.fill"
        }
    }

    var tier: HabitVerificationTier {
        switch self {
        case .madeBed, .sunlightExposure, .hydration, .healthyBreakfast, .morningJournal, .vitamins, .skincare, .mealPrep: return .aiVerified
        case .morningSteps, .sleepDuration, .morningWorkout: return .autoTracked
        case .gratitude, .dailyPlanning: return .journaling
        case .coldShower, .noSnooze, .morningStretch, .meditation, .prayer, .reading, .walkDog, .noPhoneFirst30, .breathingExercises, .floss: return .honorSystem
        }
    }

    var category: HabitCategory {
        switch self {
        case .noSnooze, .madeBed, .sleepDuration, .noPhoneFirst30: return .wakeUp
        case .morningStretch, .morningWorkout, .morningSteps, .walkDog: return .movement
        case .meditation, .coldShower, .sunlightExposure, .hydration, .prayer, .reading, .healthyBreakfast, .morningJournal, .vitamins, .skincare, .mealPrep, .gratitude, .dailyPlanning, .breathingExercises, .floss: return .wellness
        }
    }

    var defaultGoal: Int {
        switch self {
        case .madeBed: return 7 // Score out of 10
        case .morningSteps: return 500 // Steps
        case .sleepDuration: return 7 // Hours
        case .sunlightExposure: return 10 // Minutes
        case .morningWorkout: return 20 // Minutes
        case .coldShower, .noSnooze, .morningStretch, .meditation, .prayer, .reading, .walkDog: return 1 // Binary
        case .hydration: return 1 // Binary - just verify water
        case .healthyBreakfast, .morningJournal, .vitamins, .skincare, .mealPrep: return 1 // Binary AI verification
        case .gratitude, .noPhoneFirst30, .dailyPlanning, .breathingExercises, .floss: return 1 // Binary honor system
        }
    }

    /// Minimum valid goal for this habit type (prevents invalid goals like 0 or negative)
    var minimumGoal: Int {
        switch self {
        case .morningSteps: return 50 // At least 50 steps
        case .sleepDuration: return 4 // At least 4 hours
        case .morningWorkout: return 5 // At least 5 minutes
        default: return 1 // Binary habits or others - minimum 1
        }
    }

    var requiresHoldToConfirm: Bool {
        // Honor system habits require hold to prevent accidental completion
        return self.tier == .honorSystem
    }

    var requiresTextEntry: Bool {
        switch self {
        case .gratitude, .dailyPlanning: return true
        default: return false
        }
    }

    var minimumTextLength: Int {
        switch self {
        case .gratitude, .dailyPlanning: return 10
        default: return 0
        }
    }

    var textEntryPrompt: String {
        switch self {
        case .gratitude: return "What are you grateful for today?"
        case .dailyPlanning: return "What are your top priorities today?"
        default: return ""
        }
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
        case .morningSteps: return "Hit your step goal before your deadline"
        case .meditation: return "Start with a clear, calm mind"
        case .hydration: return "Start your day hydrated with a glass of water"
        case .prayer: return "Begin your day with spiritual connection"
        case .reading: return "Feed your mind with morning reading"
        case .walkDog: return "Get outside and give your dog some exercise"
        case .healthyBreakfast: return "Fuel your morning with nutritious food"
        case .morningJournal: return "Clear your mind by putting thoughts on paper"
        case .vitamins: return "Support your health with daily supplements"
        case .skincare: return "Take care of your skin with a morning routine"
        case .mealPrep: return "Set yourself up for healthy eating all day"
        case .gratitude: return "Start your day with a grateful mindset"
        case .noPhoneFirst30: return "Protect your focus by avoiding screens"
        case .dailyPlanning: return "Set clear intentions for your day"
        case .breathingExercises: return "Center yourself with intentional breathing"
        case .floss: return "Keep your teeth and gums healthy"
        }
    }

    /// Short, exciting explanation for onboarding
    var howItWorksShort: String {
        switch self {
        case .madeBed: return "Snap a photo — AI verifies it's made"
        case .sunlightExposure: return "Take a photo outside — AI verifies the daylight"
        case .hydration: return "Snap your water — AI confirms you're hydrated"
        case .sleepDuration: return "Auto-syncs from Apple Health"
        case .morningSteps: return "Auto-syncs your steps from Apple Health"
        case .morningWorkout: return "Auto-syncs from Apple Health"
        case .coldShower: return "Hold to confirm you took the plunge"
        case .noSnooze: return "Hold to confirm you didn't snooze"
        case .morningStretch: return "Hold to confirm you stretched"
        case .meditation: return "Hold to confirm you meditated"
        case .prayer: return "Hold to confirm you prayed"
        case .reading: return "Hold to confirm you read"
        case .walkDog: return "Hold to confirm you walked your dog"
        case .healthyBreakfast: return "Snap your breakfast — AI checks if it's healthy"
        case .morningJournal: return "Show your journal — AI verifies you wrote"
        case .vitamins: return "Snap your vitamins — AI confirms your supplements"
        case .skincare: return "Snap your skincare — AI verifies your routine"
        case .mealPrep: return "Show your prep — AI confirms you're ready"
        case .gratitude: return "Journal your gratitude — text entry required"
        case .noPhoneFirst30: return "Hold to confirm you stayed phone-free"
        case .dailyPlanning: return "Journal your priorities — text entry required"
        case .breathingExercises: return "Hold to confirm you did your breathing"
        case .floss: return "Hold to confirm you flossed"
        }
    }

    /// Detailed explanation for settings (includes fallbacks)
    var howItWorksDetailed: String {
        switch self {
        case .madeBed: return "Snap a photo of your bed. We'll check if it's made."
        case .sunlightExposure: return "Take a photo outside. We'll verify you got some natural light."
        case .hydration: return "Snap a photo of your drink. We'll confirm you're staying hydrated."
        case .sleepDuration: return "Syncs automatically from Apple Health. Don't track sleep with a wearable? You can enter it manually."
        case .morningSteps: return "Steps sync from Apple Health. No data? Hold to confirm."
        case .morningWorkout: return "Syncs from Apple Health when you record a workout. No workout recorded? Hold to confirm."
        case .coldShower: return "Hold to confirm you took a cold shower this morning."
        case .noSnooze: return "Hold to confirm you got up without hitting snooze."
        case .morningStretch: return "Hold to confirm you did your morning stretch."
        case .meditation: return "Hold to confirm you completed your meditation."
        case .prayer: return "Hold to confirm you completed your morning prayer."
        case .reading: return "Hold to confirm you did your morning reading."
        case .walkDog: return "Hold to confirm you took your dog for a walk."
        case .healthyBreakfast: return "Take a photo of your breakfast. We'll verify it's healthy."
        case .morningJournal: return "Show your journal with today's writing. We'll verify you reflected."
        case .vitamins: return "Snap your vitamins or supplements. We'll confirm you're taking care of yourself."
        case .skincare: return "Show your skincare products or routine. We'll verify you're caring for your skin."
        case .mealPrep: return "Take a photo of your prepped meals. We'll confirm you're set for success."
        case .gratitude: return "Write at least 10 characters about what you're grateful for today."
        case .noPhoneFirst30: return "Hold to confirm you avoided your phone for 30 minutes after waking."
        case .dailyPlanning: return "Write at least 10 characters about your priorities for the day."
        case .breathingExercises: return "Hold to confirm you completed your breathing exercises."
        case .floss: return "Hold to confirm you flossed your teeth."
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
        // Validate goal against minimum (prevents invalid goals like 0 or negative)
        let proposedGoal = goal ?? habitType.defaultGoal
        self.goal = max(habitType.minimumGoal, proposedGoal)
        self.displayOrder = displayOrder
        self.activeDays = activeDays ?? Set(1...7) // Default to all days
    }

    // Custom decoder for backward compatibility (existing users get all days)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        habitType = try container.decode(HabitType.self, forKey: .habitType)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        // Validate goal against minimum when loading from storage
        let storedGoal = try container.decode(Int.self, forKey: .goal)
        goal = max(habitType.minimumGoal, storedGoal)
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
                isEnabled: [.madeBed, .sleepDuration, .walkDog, .morningSteps].contains(type),
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

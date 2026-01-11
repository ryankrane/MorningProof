import Foundation

// MARK: - Achievement Category
enum AchievementCategory: String, Codable, CaseIterable {
    case streak = "Streak Milestones"
    case cumulative = "Total Completions"
    case timing = "Early Bird"
    case comeback = "Resilience"
    case special = "Special"

    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .cumulative: return "chart.bar.fill"
        case .timing: return "sunrise.fill"
        case .comeback: return "arrow.counterclockwise"
        case .special: return "sparkles"
        }
    }

    var sortOrder: Int {
        switch self {
        case .streak: return 0
        case .cumulative: return 1
        case .timing: return 2
        case .comeback: return 3
        case .special: return 4
        }
    }
}

// MARK: - Achievement Type (determines how to check unlock)
enum AchievementType: String, Codable {
    case streak              // Based on current consecutive streak
    case totalCompletions    // Based on total completions ever
    case earlyCompletion     // Based on completing before a certain hour
    case comeback            // Based on bouncing back after streak loss
    case perfectWeek         // 7 consecutive days all habits done
    case weekendWarrior      // Complete on weekends
    case mondayMotivation    // Complete on Mondays
    case special             // Special conditions (holidays, etc.)
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let type: AchievementType
    let requirement: Int
    let secondaryRequirement: Int? // For time-based (hour) or other secondary conditions
    let isHidden: Bool
    var unlockedDate: Date?

    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        type: AchievementType,
        requirement: Int,
        secondaryRequirement: Int? = nil,
        isHidden: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.type = type
        self.requirement = requirement
        self.secondaryRequirement = secondaryRequirement
        self.isHidden = isHidden
    }

    var isUnlocked: Bool {
        unlockedDate != nil
    }

    // MARK: - All Achievements
    static let allAchievements: [Achievement] = {
        var achievements: [Achievement] = []
        achievements.append(contentsOf: streakAchievements)
        achievements.append(contentsOf: cumulativeAchievements)
        achievements.append(contentsOf: timingAchievements)
        achievements.append(contentsOf: comebackAchievements)
        achievements.append(contentsOf: specialAchievements)
        return achievements
    }()

    // MARK: - Streak Achievements (consecutive days)
    static let streakAchievements: [Achievement] = [
        Achievement(
            id: "first_bed",
            title: "First Step",
            description: "Made your bed for the first time",
            icon: "bed.double.fill",
            category: .streak,
            type: .streak,
            requirement: 1
        ),
        Achievement(
            id: "three_days",
            title: "Getting Started",
            description: "3 day streak",
            icon: "flame",
            category: .streak,
            type: .streak,
            requirement: 3
        ),
        Achievement(
            id: "one_week",
            title: "One Week Wonder",
            description: "7 day streak",
            icon: "flame.fill",
            category: .streak,
            type: .streak,
            requirement: 7
        ),
        Achievement(
            id: "two_weeks",
            title: "Habit Forming",
            description: "14 day streak",
            icon: "star.fill",
            category: .streak,
            type: .streak,
            requirement: 14
        ),
        Achievement(
            id: "three_weeks",
            title: "Committed",
            description: "21 day streak - it's a habit now!",
            icon: "star.circle.fill",
            category: .streak,
            type: .streak,
            requirement: 21
        ),
        Achievement(
            id: "one_month",
            title: "Monthly Master",
            description: "30 day streak",
            icon: "crown",
            category: .streak,
            type: .streak,
            requirement: 30
        ),
        Achievement(
            id: "sixty_days",
            title: "Unstoppable",
            description: "60 day streak",
            icon: "crown.fill",
            category: .streak,
            type: .streak,
            requirement: 60
        ),
        Achievement(
            id: "ninety_days",
            title: "Quarter Champion",
            description: "90 day streak",
            icon: "trophy",
            category: .streak,
            type: .streak,
            requirement: 90
        ),
        Achievement(
            id: "half_year",
            title: "Half Year Hero",
            description: "180 day streak",
            icon: "trophy.fill",
            category: .streak,
            type: .streak,
            requirement: 180
        ),
        Achievement(
            id: "one_year",
            title: "Legendary",
            description: "365 day streak - You're a legend!",
            icon: "medal.fill",
            category: .streak,
            type: .streak,
            requirement: 365
        ),
    ]

    // MARK: - Cumulative Achievements (total completions, not consecutive)
    static let cumulativeAchievements: [Achievement] = [
        Achievement(
            id: "total_10",
            title: "Getting Consistent",
            description: "10 total completions",
            icon: "10.circle.fill",
            category: .cumulative,
            type: .totalCompletions,
            requirement: 10
        ),
        Achievement(
            id: "total_25",
            title: "Quarter Century",
            description: "25 total completions",
            icon: "25.circle.fill",
            category: .cumulative,
            type: .totalCompletions,
            requirement: 25
        ),
        Achievement(
            id: "total_50",
            title: "Fifty Strong",
            description: "50 total completions",
            icon: "50.circle.fill",
            category: .cumulative,
            type: .totalCompletions,
            requirement: 50
        ),
        Achievement(
            id: "total_100",
            title: "Century Club",
            description: "100 total completions",
            icon: "100.circle.fill",
            category: .cumulative,
            type: .totalCompletions,
            requirement: 100
        ),
        Achievement(
            id: "total_250",
            title: "Dedicated",
            description: "250 total completions",
            icon: "chart.line.uptrend.xyaxis",
            category: .cumulative,
            type: .totalCompletions,
            requirement: 250
        ),
        Achievement(
            id: "total_500",
            title: "500 Strong",
            description: "500 total completions",
            icon: "star.leadinghalf.filled",
            category: .cumulative,
            type: .totalCompletions,
            requirement: 500
        ),
        Achievement(
            id: "total_1000",
            title: "Thousand Days",
            description: "1000 total completions - incredible!",
            icon: "diamond.fill",
            category: .cumulative,
            type: .totalCompletions,
            requirement: 1000
        ),
    ]

    // MARK: - Timing Achievements (early completions)
    static let timingAchievements: [Achievement] = [
        Achievement(
            id: "early_bird_1",
            title: "Early Bird",
            description: "Complete before 7 AM",
            icon: "sunrise",
            category: .timing,
            type: .earlyCompletion,
            requirement: 1,
            secondaryRequirement: 7 // Before 7 AM
        ),
        Achievement(
            id: "early_bird_7",
            title: "Dawn Patrol",
            description: "Complete before 7 AM, 7 times",
            icon: "sunrise.fill",
            category: .timing,
            type: .earlyCompletion,
            requirement: 7,
            secondaryRequirement: 7
        ),
        Achievement(
            id: "early_bird_30",
            title: "Rise and Shine",
            description: "Complete before 7 AM, 30 times",
            icon: "sun.max.fill",
            category: .timing,
            type: .earlyCompletion,
            requirement: 30,
            secondaryRequirement: 7
        ),
        Achievement(
            id: "super_early_1",
            title: "Before Dawn",
            description: "Complete before 6 AM",
            icon: "moon.stars",
            category: .timing,
            type: .earlyCompletion,
            requirement: 1,
            secondaryRequirement: 6 // Before 6 AM
        ),
        Achievement(
            id: "super_early_10",
            title: "Night Owl Reformed",
            description: "Complete before 6 AM, 10 times",
            icon: "moon.stars.fill",
            category: .timing,
            type: .earlyCompletion,
            requirement: 10,
            secondaryRequirement: 6
        ),
    ]

    // MARK: - Comeback Achievements (resilience after streak breaks)
    static let comebackAchievements: [Achievement] = [
        Achievement(
            id: "bounce_back",
            title: "Bounce Back",
            description: "Complete a day after losing a 7+ day streak",
            icon: "arrow.uturn.up",
            category: .comeback,
            type: .comeback,
            requirement: 7 // Lost streak was at least 7
        ),
        Achievement(
            id: "phoenix_rising",
            title: "Phoenix Rising",
            description: "Rebuild to a 14-day streak after losing one",
            icon: "flame.circle.fill",
            category: .comeback,
            type: .comeback,
            requirement: 14
        ),
        Achievement(
            id: "never_give_up",
            title: "Never Give Up",
            description: "Comeback 3 times after losing streaks",
            icon: "heart.circle.fill",
            category: .comeback,
            type: .comeback,
            requirement: 3
        ),
        Achievement(
            id: "resilient",
            title: "Resilient",
            description: "Comeback 5 times after losing streaks",
            icon: "shield.fill",
            category: .comeback,
            type: .comeback,
            requirement: 5
        ),
        Achievement(
            id: "unbreakable_spirit",
            title: "Unbreakable Spirit",
            description: "Comeback 10 times - nothing stops you!",
            icon: "bolt.shield.fill",
            category: .comeback,
            type: .comeback,
            requirement: 10
        ),
    ]

    // MARK: - Special Achievements
    static let specialAchievements: [Achievement] = [
        Achievement(
            id: "perfect_week",
            title: "Perfect Week",
            description: "Complete every day for 7 days straight",
            icon: "checkmark.seal.fill",
            category: .special,
            type: .perfectWeek,
            requirement: 7
        ),
        Achievement(
            id: "weekend_warrior_1",
            title: "Weekend Warrior",
            description: "Complete on both Saturday and Sunday",
            icon: "calendar.badge.checkmark",
            category: .special,
            type: .weekendWarrior,
            requirement: 1 // 1 complete weekend
        ),
        Achievement(
            id: "weekend_warrior_4",
            title: "Weekend Champion",
            description: "Complete 4 full weekends",
            icon: "calendar.badge.checkmark",
            category: .special,
            type: .weekendWarrior,
            requirement: 4
        ),
        Achievement(
            id: "monday_motivation_5",
            title: "Monday Motivation",
            description: "Complete on 5 Mondays",
            icon: "1.circle.fill",
            category: .special,
            type: .mondayMotivation,
            requirement: 5
        ),
        Achievement(
            id: "monday_motivation_10",
            title: "Monday Master",
            description: "Complete on 10 Mondays",
            icon: "1.square.fill",
            category: .special,
            type: .mondayMotivation,
            requirement: 10
        ),
        Achievement(
            id: "speed_demon",
            title: "Speed Demon",
            description: "Complete within 5 minutes of waking",
            icon: "hare.fill",
            category: .special,
            type: .special,
            requirement: 1,
            isHidden: true
        ),
        Achievement(
            id: "new_year",
            title: "New Year, New You",
            description: "Complete on January 1st",
            icon: "party.popper.fill",
            category: .special,
            type: .special,
            requirement: 1,
            isHidden: true
        ),
    ]

    // MARK: - Helper Methods
    static func achievementsByCategory() -> [AchievementCategory: [Achievement]] {
        Dictionary(grouping: allAchievements, by: { $0.category })
    }

    static func visibleAchievements(unlockedIds: Set<String>) -> [Achievement] {
        allAchievements.filter { !$0.isHidden || unlockedIds.contains($0.id) }
    }
}

// MARK: - Achievement Stats (tracked data for unlock checking)
struct AchievementStats: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalCompletions: Int = 0
    var earlyCompletions: [Int: Int] = [:] // hour -> count (completions before that hour)
    var comebackCount: Int = 0
    var lastLostStreak: Int = 0
    var completedWeekends: Int = 0
    var mondayCompletions: Int = 0
    var completedOnNewYear: Bool = false

    init() {}

    init(
        currentStreak: Int,
        longestStreak: Int,
        totalCompletions: Int,
        earlyCompletions: [Int: Int],
        comebackCount: Int,
        lastLostStreak: Int,
        completedWeekends: Int,
        mondayCompletions: Int,
        completedOnNewYear: Bool
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalCompletions = totalCompletions
        self.earlyCompletions = earlyCompletions
        self.comebackCount = comebackCount
        self.lastLostStreak = lastLostStreak
        self.completedWeekends = completedWeekends
        self.mondayCompletions = mondayCompletions
        self.completedOnNewYear = completedOnNewYear
    }
}

// MARK: - User Achievements
struct UserAchievements: Codable {
    var unlockedAchievements: [String: Date] // achievement id -> unlock date

    init() {
        self.unlockedAchievements = [:]
    }

    // Legacy method for backward compatibility
    mutating func checkAndUnlock(currentStreak: Int) -> Achievement? {
        let stats = AchievementStats()
        var mutableStats = stats
        mutableStats.currentStreak = currentStreak
        return checkAndUnlockAll(stats: mutableStats).first
    }

    // New comprehensive check method
    mutating func checkAndUnlockAll(stats: AchievementStats) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []

        for achievement in Achievement.allAchievements {
            if unlockedAchievements[achievement.id] == nil && shouldUnlock(achievement: achievement, stats: stats) {
                unlockedAchievements[achievement.id] = Date()
                newlyUnlocked.append(achievement)
            }
        }

        return newlyUnlocked
    }

    private func shouldUnlock(achievement: Achievement, stats: AchievementStats) -> Bool {
        switch achievement.type {
        case .streak:
            return stats.currentStreak >= achievement.requirement

        case .totalCompletions:
            return stats.totalCompletions >= achievement.requirement

        case .earlyCompletion:
            guard let hour = achievement.secondaryRequirement else { return false }
            let count = stats.earlyCompletions[hour] ?? 0
            return count >= achievement.requirement

        case .comeback:
            switch achievement.id {
            case "bounce_back":
                // Just came back after losing a 7+ day streak
                return stats.lastLostStreak >= 7 && stats.currentStreak >= 1
            case "phoenix_rising":
                // Rebuilt to 14 days after losing a streak
                return stats.comebackCount >= 1 && stats.currentStreak >= 14
            case "never_give_up", "resilient", "unbreakable_spirit":
                return stats.comebackCount >= achievement.requirement
            default:
                return false
            }

        case .perfectWeek:
            return stats.currentStreak >= 7

        case .weekendWarrior:
            return stats.completedWeekends >= achievement.requirement

        case .mondayMotivation:
            return stats.mondayCompletions >= achievement.requirement

        case .special:
            switch achievement.id {
            case "new_year":
                return stats.completedOnNewYear
            default:
                return false
            }
        }
    }

    func isUnlocked(_ achievementId: String) -> Bool {
        unlockedAchievements[achievementId] != nil
    }

    func getUnlockedDate(_ achievementId: String) -> Date? {
        unlockedAchievements[achievementId]
    }

    var unlockedIds: Set<String> {
        Set(unlockedAchievements.keys)
    }

    var nextAchievement: Achievement? {
        // Prioritize streak achievements for the "next" display
        Achievement.streakAchievements.first { !isUnlocked($0.id) }
    }

    var unlockedCount: Int {
        unlockedAchievements.count
    }

    func unlockedCountByCategory() -> [AchievementCategory: Int] {
        var counts: [AchievementCategory: Int] = [:]
        for category in AchievementCategory.allCases {
            let achievements = Achievement.allAchievements.filter { $0.category == category }
            counts[category] = achievements.filter { isUnlocked($0.id) }.count
        }
        return counts
    }
}

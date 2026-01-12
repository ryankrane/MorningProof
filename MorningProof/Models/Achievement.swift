import Foundation
import SwiftUI

// MARK: - Achievement Tier
enum AchievementTier: String, Codable, CaseIterable {
    case bronze
    case silver
    case gold
    case hidden

    var displayName: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .hidden: return "Secret"
        }
    }

    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.80)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .hidden: return Color(red: 0.5, green: 0.4, blue: 0.7)
        }
    }

    var glowColor: Color {
        color.opacity(0.6)
    }

    var sortOrder: Int {
        switch self {
        case .gold: return 0
        case .silver: return 1
        case .bronze: return 2
        case .hidden: return 3
        }
    }
}

// MARK: - Achievement Category
enum AchievementCategory: String, Codable, CaseIterable {
    case streak = "Streaks"
    case lifetime = "Lifetime"
    case earlyRiser = "Early Riser"
    case resilience = "Resilience"
    case hidden = "Secret"

    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .lifetime: return "chart.bar.fill"
        case .earlyRiser: return "sunrise.fill"
        case .resilience: return "arrow.uturn.up.circle.fill"
        case .hidden: return "sparkles"
        }
    }

    var sortOrder: Int {
        switch self {
        case .streak: return 0
        case .lifetime: return 1
        case .earlyRiser: return 2
        case .resilience: return 3
        case .hidden: return 4
        }
    }
}

// MARK: - Achievement Type
enum AchievementType: String, Codable {
    case streak              // Based on current consecutive streak
    case totalCompletions    // Based on total completions ever
    case earlyCompletion     // Based on completing before a certain hour
    case comeback            // Based on bouncing back after streak loss
    case rebuildStreak       // Rebuild to X days after losing a streak
    case perfectMonth        // Complete every day of a calendar month
    case anniversary         // Complete on app install anniversary
    case newYear             // Complete on January 1st
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let type: AchievementType
    let tier: AchievementTier
    let requirement: Int
    let secondaryRequirement: Int?
    let isHidden: Bool
    var unlockedDate: Date?

    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        type: AchievementType,
        tier: AchievementTier,
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
        self.tier = tier
        self.requirement = requirement
        self.secondaryRequirement = secondaryRequirement
        self.isHidden = isHidden
    }

    var isUnlocked: Bool {
        unlockedDate != nil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - All Achievements (18 Total)
    static let allAchievements: [Achievement] = {
        var achievements: [Achievement] = []
        achievements.append(contentsOf: streakAchievements)
        achievements.append(contentsOf: lifetimeAchievements)
        achievements.append(contentsOf: earlyRiserAchievements)
        achievements.append(contentsOf: resilienceAchievements)
        achievements.append(contentsOf: hiddenAchievements)
        return achievements
    }()

    // MARK: - Streak Achievements (5)
    static let streakAchievements: [Achievement] = [
        Achievement(
            id: "streak_7",
            title: "One Week",
            description: "Maintain a 7-day streak",
            icon: "flame",
            category: .streak,
            type: .streak,
            tier: .bronze,
            requirement: 7
        ),
        Achievement(
            id: "streak_21",
            title: "Habit Formed",
            description: "21 days - science says it's a habit now",
            icon: "flame.fill",
            category: .streak,
            type: .streak,
            tier: .silver,
            requirement: 21
        ),
        Achievement(
            id: "streak_30",
            title: "Monthly Master",
            description: "A full month of dedication",
            icon: "crown",
            category: .streak,
            type: .streak,
            tier: .silver,
            requirement: 30
        ),
        Achievement(
            id: "streak_90",
            title: "Quarterly Champion",
            description: "90 days of unbroken commitment",
            icon: "trophy",
            category: .streak,
            type: .streak,
            tier: .gold,
            requirement: 90
        ),
        Achievement(
            id: "streak_365",
            title: "Legendary",
            description: "One full year. You're a legend.",
            icon: "medal.fill",
            category: .streak,
            type: .streak,
            tier: .gold,
            requirement: 365
        ),
    ]

    // MARK: - Lifetime Achievements (4)
    static let lifetimeAchievements: [Achievement] = [
        Achievement(
            id: "total_50",
            title: "Fifty Strong",
            description: "50 total completions",
            icon: "50.circle.fill",
            category: .lifetime,
            type: .totalCompletions,
            tier: .bronze,
            requirement: 50
        ),
        Achievement(
            id: "total_100",
            title: "Century Club",
            description: "100 total completions",
            icon: "100.circle",
            category: .lifetime,
            type: .totalCompletions,
            tier: .silver,
            requirement: 100
        ),
        Achievement(
            id: "total_365",
            title: "Full Year",
            description: "365 completions - a year's worth of mornings",
            icon: "calendar.badge.checkmark",
            category: .lifetime,
            type: .totalCompletions,
            tier: .gold,
            requirement: 365
        ),
        Achievement(
            id: "total_1000",
            title: "Thousand Days",
            description: "1000 completions. Incredible dedication.",
            icon: "diamond.fill",
            category: .lifetime,
            type: .totalCompletions,
            tier: .gold,
            requirement: 1000
        ),
    ]

    // MARK: - Early Riser Achievements (3)
    static let earlyRiserAchievements: [Achievement] = [
        Achievement(
            id: "early_7",
            title: "Early Bird",
            description: "Complete before 7 AM, 7 times",
            icon: "sunrise",
            category: .earlyRiser,
            type: .earlyCompletion,
            tier: .bronze,
            requirement: 7,
            secondaryRequirement: 7
        ),
        Achievement(
            id: "early_30",
            title: "Dawn Patrol",
            description: "Complete before 7 AM, 30 times",
            icon: "sunrise.fill",
            category: .earlyRiser,
            type: .earlyCompletion,
            tier: .silver,
            requirement: 30,
            secondaryRequirement: 7
        ),
        Achievement(
            id: "early_100",
            title: "Rise Master",
            description: "100 early morning completions",
            icon: "sun.max.fill",
            category: .earlyRiser,
            type: .earlyCompletion,
            tier: .gold,
            requirement: 100,
            secondaryRequirement: 7
        ),
    ]

    // MARK: - Resilience Achievements (3)
    static let resilienceAchievements: [Achievement] = [
        Achievement(
            id: "comeback_1",
            title: "Bounce Back",
            description: "Return the day after losing a 7+ day streak",
            icon: "arrow.uturn.up",
            category: .resilience,
            type: .comeback,
            tier: .silver,
            requirement: 7
        ),
        Achievement(
            id: "comeback_rebuild",
            title: "Phoenix",
            description: "Rebuild to a 30-day streak after losing one",
            icon: "flame.circle.fill",
            category: .resilience,
            type: .rebuildStreak,
            tier: .gold,
            requirement: 30
        ),
    ]

    // MARK: - Hidden/Secret Achievements (3)
    static let hiddenAchievements: [Achievement] = [
        Achievement(
            id: "new_year",
            title: "Fresh Start",
            description: "Complete on January 1st",
            icon: "party.popper.fill",
            category: .hidden,
            type: .newYear,
            tier: .hidden,
            requirement: 1,
            isHidden: true
        ),
        Achievement(
            id: "perfect_month",
            title: "Flawless",
            description: "Complete every single day of a calendar month",
            icon: "checkmark.seal.fill",
            category: .hidden,
            type: .perfectMonth,
            tier: .hidden,
            requirement: 1,
            isHidden: true
        ),
        Achievement(
            id: "anniversary",
            title: "Anniversary",
            description: "Complete on your MorningProof anniversary",
            icon: "gift.fill",
            category: .hidden,
            type: .anniversary,
            tier: .hidden,
            requirement: 1,
            isHidden: true
        ),
    ]

    // MARK: - Helper Methods
    static func achievementsByCategory() -> [AchievementCategory: [Achievement]] {
        Dictionary(grouping: allAchievements, by: { $0.category })
    }

    static func achievementsByTier() -> [AchievementTier: [Achievement]] {
        Dictionary(grouping: allAchievements, by: { $0.tier })
    }

    static func visibleAchievements(unlockedIds: Set<String>) -> [Achievement] {
        allAchievements.filter { !$0.isHidden || unlockedIds.contains($0.id) }
    }

    static var totalCount: Int {
        allAchievements.count
    }

    static var hiddenCount: Int {
        allAchievements.filter { $0.isHidden }.count
    }
}

// MARK: - Achievement Stats
struct AchievementStats: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalCompletions: Int = 0
    var earlyCompletions: [Int: Int] = [:]  // hour -> count
    var comebackCount: Int = 0
    var lastLostStreak: Int = 0
    var hasRebuiltAfterLoss: Bool = false
    var perfectMonthsCompleted: Int = 0
    var completedOnNewYear: Bool = false
    var installDate: Date?
    var completedOnAnniversary: Bool = false

    init() {}

    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalCompletions: Int = 0,
        earlyCompletions: [Int: Int] = [:],
        comebackCount: Int = 0,
        lastLostStreak: Int = 0,
        hasRebuiltAfterLoss: Bool = false,
        perfectMonthsCompleted: Int = 0,
        completedOnNewYear: Bool = false,
        installDate: Date? = nil,
        completedOnAnniversary: Bool = false
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalCompletions = totalCompletions
        self.earlyCompletions = earlyCompletions
        self.comebackCount = comebackCount
        self.lastLostStreak = lastLostStreak
        self.hasRebuiltAfterLoss = hasRebuiltAfterLoss
        self.perfectMonthsCompleted = perfectMonthsCompleted
        self.completedOnNewYear = completedOnNewYear
        self.installDate = installDate
        self.completedOnAnniversary = completedOnAnniversary
    }
}

// MARK: - User Achievements
struct UserAchievements: Codable {
    var unlockedAchievements: [String: Date]

    init() {
        self.unlockedAchievements = [:]
    }

    mutating func checkAndUnlock(currentStreak: Int) -> Achievement? {
        var stats = AchievementStats()
        stats.currentStreak = currentStreak
        return checkAndUnlockAll(stats: stats).first
    }

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
            // Bounce back: returned after losing a 7+ day streak
            return stats.lastLostStreak >= achievement.requirement && stats.currentStreak >= 1

        case .rebuildStreak:
            // Phoenix: rebuilt to 30 days after previously losing a streak
            return stats.hasRebuiltAfterLoss && stats.currentStreak >= achievement.requirement

        case .perfectMonth:
            return stats.perfectMonthsCompleted >= achievement.requirement

        case .newYear:
            return stats.completedOnNewYear

        case .anniversary:
            return stats.completedOnAnniversary
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

    var nextStreakAchievement: Achievement? {
        Achievement.streakAchievements.first { !isUnlocked($0.id) }
    }

    var nextAchievement: Achievement? {
        // Return the next unlocked achievement with the lowest requirement
        Achievement.allAchievements
            .filter { !isUnlocked($0.id) && $0.tier != .hidden }
            .sorted { $0.requirement < $1.requirement }
            .first
    }

    var unlockedCount: Int {
        unlockedAchievements.count
    }

    var hiddenUnlockedCount: Int {
        Achievement.hiddenAchievements.filter { isUnlocked($0.id) }.count
    }

    func unlockedCountByCategory() -> [AchievementCategory: Int] {
        var counts: [AchievementCategory: Int] = [:]
        for category in AchievementCategory.allCases {
            let achievements = Achievement.allAchievements.filter { $0.category == category }
            counts[category] = achievements.filter { isUnlocked($0.id) }.count
        }
        return counts
    }

    func unlockedCountByTier() -> [AchievementTier: Int] {
        var counts: [AchievementTier: Int] = [:]
        for tier in AchievementTier.allCases {
            let achievements = Achievement.allAchievements.filter { $0.tier == tier }
            counts[tier] = achievements.filter { isUnlocked($0.id) }.count
        }
        return counts
    }

    func progress(for achievement: Achievement, stats: AchievementStats) -> Double {
        switch achievement.type {
        case .streak:
            return min(1.0, Double(stats.currentStreak) / Double(achievement.requirement))
        case .totalCompletions:
            return min(1.0, Double(stats.totalCompletions) / Double(achievement.requirement))
        case .earlyCompletion:
            guard let hour = achievement.secondaryRequirement else { return 0 }
            let count = stats.earlyCompletions[hour] ?? 0
            return min(1.0, Double(count) / Double(achievement.requirement))
        case .comeback, .rebuildStreak:
            return isUnlocked(achievement.id) ? 1.0 : 0.0
        case .perfectMonth:
            return min(1.0, Double(stats.perfectMonthsCompleted) / Double(achievement.requirement))
        case .newYear, .anniversary:
            return isUnlocked(achievement.id) ? 1.0 : 0.0
        }
    }
}

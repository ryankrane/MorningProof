import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: Int // days needed
    var unlockedDate: Date?

    var isUnlocked: Bool {
        unlockedDate != nil
    }

    static let allAchievements: [Achievement] = [
        Achievement(id: "first_bed", title: "First Step", description: "Made your bed for the first time", icon: "bed.double.fill", requirement: 1),
        Achievement(id: "three_days", title: "Getting Started", description: "3 day streak", icon: "flame", requirement: 3),
        Achievement(id: "one_week", title: "One Week Wonder", description: "7 day streak", icon: "flame.fill", requirement: 7),
        Achievement(id: "two_weeks", title: "Habit Forming", description: "14 day streak", icon: "star.fill", requirement: 14),
        Achievement(id: "three_weeks", title: "Committed", description: "21 day streak - it's a habit now!", icon: "star.circle.fill", requirement: 21),
        Achievement(id: "one_month", title: "Monthly Master", description: "30 day streak", icon: "crown", requirement: 30),
        Achievement(id: "sixty_days", title: "Unstoppable", description: "60 day streak", icon: "crown.fill", requirement: 60),
        Achievement(id: "ninety_days", title: "Quarter Champion", description: "90 day streak", icon: "trophy", requirement: 90),
        Achievement(id: "half_year", title: "Half Year Hero", description: "180 day streak", icon: "trophy.fill", requirement: 180),
        Achievement(id: "one_year", title: "Legendary", description: "365 day streak - You're a legend!", icon: "medal.fill", requirement: 365),
    ]
}

struct UserAchievements: Codable {
    var unlockedAchievements: [String: Date] // achievement id -> unlock date

    init() {
        self.unlockedAchievements = [:]
    }

    mutating func checkAndUnlock(currentStreak: Int) -> Achievement? {
        for achievement in Achievement.allAchievements {
            if currentStreak >= achievement.requirement && unlockedAchievements[achievement.id] == nil {
                unlockedAchievements[achievement.id] = Date()
                return achievement
            }
        }
        return nil
    }

    func isUnlocked(_ achievementId: String) -> Bool {
        unlockedAchievements[achievementId] != nil
    }

    func getUnlockedDate(_ achievementId: String) -> Date? {
        unlockedAchievements[achievementId]
    }

    var nextAchievement: Achievement? {
        Achievement.allAchievements.first { !isUnlocked($0.id) }
    }

    var unlockedCount: Int {
        unlockedAchievements.count
    }
}

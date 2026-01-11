import Foundation
import SwiftUI

@MainActor
class BedVerificationViewModel: ObservableObject {
    @Published var currentScreen: AppScreen = .home
    @Published var streakData: StreakData
    @Published var achievements: UserAchievements
    @Published var settings: UserSettings
    @Published var lastResult: VerificationResult?
    @Published var errorMessage: String?
    @Published var newAchievement: Achievement?
    @Published var showConfetti: Bool = false

    private let storageService = StorageService()
    private let apiService = ClaudeAPIService()

    init() {
        self.streakData = StorageService().loadStreakData()
        self.achievements = StorageService().loadAchievements()
        self.settings = StorageService().loadSettings()
    }

    func openCamera() {
        currentScreen = .camera
    }

    func goHome() {
        currentScreen = .home
        errorMessage = nil
    }

    func resetStreak() {
        streakData = StreakData()
        achievements = UserAchievements()
        storageService.saveStreakData(streakData)
        storageService.saveAchievements(achievements)
    }

    func verifyBed(image: UIImage) {
        currentScreen = .analyzing
        errorMessage = nil

        Task {
            do {
                let result = try await apiService.verifyBed(image: image)
                lastResult = result

                if result.isMade {
                    streakData = storageService.recordCompletion()

                    // Check for new achievements
                    if let unlocked = achievements.checkAndUnlock(currentStreak: streakData.currentStreak) {
                        storageService.saveAchievements(achievements)
                        newAchievement = unlocked
                        showConfetti = true
                    }
                }

                currentScreen = .result
            } catch {
                errorMessage = error.localizedDescription
                lastResult = VerificationResult(
                    isMade: false,
                    score: 0,
                    feedback: "Error analyzing image: \(error.localizedDescription)"
                )
                currentScreen = .result
            }
        }
    }

    func dismissAchievement() {
        newAchievement = nil
        showConfetti = false
    }

    func updateDeadline(hour: Int, minute: Int) {
        settings.deadlineHour = hour
        settings.deadlineMinute = minute
        storageService.saveSettings(settings)
    }

    func saveSettings() {
        storageService.saveSettings(settings)
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<21:
            return "Good evening"
        default:
            return "Hello"
        }
    }

    var nextAchievement: Achievement? {
        achievements.nextAchievement
    }

    var progressToNextAchievement: Double {
        guard let next = nextAchievement else { return 1.0 }
        let previous = Achievement.allAchievements
            .filter { achievements.isUnlocked($0.id) }
            .max(by: { $0.requirement < $1.requirement })?.requirement ?? 0

        let range = next.requirement - previous
        let progress = streakData.currentStreak - previous
        return min(Double(progress) / Double(range), 1.0)
    }
}

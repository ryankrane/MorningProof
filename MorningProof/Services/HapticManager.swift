import UIKit

class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // Light tap for UI interactions
    func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // Medium tap for confirmations
    func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    // Heavy tap for important actions
    func heavyTap() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // Success feedback for completed actions
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // Warning feedback
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    // Error feedback
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // Selection changed feedback
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    // Custom pattern for streak milestone
    func streakMilestone() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            generator.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }

    // Custom pattern for habit completion
    func habitCompleted() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }

    // Custom pattern for perfect morning
    func perfectMorning() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        let medium = UIImpactFeedbackGenerator(style: .medium)

        heavy.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            medium.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            medium.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }
}

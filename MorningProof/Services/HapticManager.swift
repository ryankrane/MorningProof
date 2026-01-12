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

    // Custom pattern for habit completion (basic)
    func habitCompleted() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }

    // Enhanced pattern for habit completion - triple-tap satisfaction
    func habitCompletedEnhanced() {
        let rigid = UIImpactFeedbackGenerator(style: .rigid)
        let medium = UIImpactFeedbackGenerator(style: .medium)

        // Phase 1: Initial "pop" - rigid for that satisfying snap
        rigid.impactOccurred(intensity: 1.0)

        // Phase 2: Quick follow-up for depth
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            medium.impactOccurred(intensity: 0.7)
        }

        // Phase 3: Success confirmation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }

    // Dramatic celebration for all habits complete
    func allHabitsCompleteCelebration() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        let rigid = UIImpactFeedbackGenerator(style: .rigid)
        let medium = UIImpactFeedbackGenerator(style: .medium)

        // Initial dramatic impact
        heavy.impactOccurred(intensity: 1.0)

        // Rising sequence (like drumroll)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            medium.impactOccurred(intensity: 0.5)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            medium.impactOccurred(intensity: 0.6)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            medium.impactOccurred(intensity: 0.7)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            rigid.impactOccurred(intensity: 0.9)
        }

        // Climactic success
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            heavy.impactOccurred(intensity: 1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }

        // Trailing celebration taps
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            medium.impactOccurred(intensity: 0.4)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            medium.impactOccurred(intensity: 0.3)
        }
    }

    // Custom pattern for perfect morning (legacy)
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

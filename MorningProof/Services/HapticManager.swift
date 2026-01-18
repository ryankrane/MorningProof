import UIKit

class HapticManager {
    static let shared = HapticManager()

    // Pre-prepared generator for low-latency rapid charging taps
    private let chargingGenerator = UIImpactFeedbackGenerator(style: .rigid)

    private init() {
        // Prepare the charging generator for immediate use
        chargingGenerator.prepare()
    }

    // MARK: - Charging Haptics

    /// Charging tap for hold-to-complete buttons with variable intensity
    /// Uses a pre-prepared rigid generator for low-latency rapid-fire taps
    /// - Parameter intensity: 0.0 to 1.0, controls haptic strength
    func chargingTap(intensity: CGFloat) {
        chargingGenerator.impactOccurred(intensity: intensity)
        // Re-prepare for next tap (keeps latency low)
        chargingGenerator.prepare()
    }

    // Light tap for UI interactions
    func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    // Alias for lightTap
    func light() {
        lightTap()
    }

    // Medium tap for confirmations
    func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    // Alias for mediumTap
    func medium() {
        mediumTap()
    }

    // Heavy tap for important actions
    func heavyTap() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // Rigid tap for sharp, satisfying feedback (like a lock clicking)
    func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
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

    // Premium burst haptic for habit completion confetti explosion
    // Syncs with visual burst - sharp initial pop with satisfying cascading falloff
    func habitBurst() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        let rigid = UIImpactFeedbackGenerator(style: .rigid)
        let medium = UIImpactFeedbackGenerator(style: .medium)

        // Prepare for immediate response
        heavy.prepare()
        rigid.prepare()

        // Phase 1: Initial BURST - heavy thud as particles explode
        heavy.impactOccurred(intensity: 1.0)

        // Phase 2: Sharp crackle follow-up (like confetti popping)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            rigid.impactOccurred(intensity: 0.9)
        }

        // Phase 3: Softer echo as particles spread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            medium.impactOccurred(intensity: 0.5)
        }

        // Phase 4: Success confirmation - the satisfying finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
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

    // Custom pattern for perfect morning celebration
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

    // Dramatic slam impact for lock-in celebration
    // Creates a heavy "thud" with cascading impacts and satisfying rumble echo
    func flameSlamImpact() {
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        let rigid = UIImpactFeedbackGenerator(style: .rigid)
        let medium = UIImpactFeedbackGenerator(style: .medium)

        // Prepare generators for immediate response
        heavy.prepare()
        rigid.prepare()
        medium.prepare()

        // Initial HEAVY slam - the main impact
        heavy.impactOccurred(intensity: 1.0)

        // Sharp follow-up for crispness
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.035) {
            rigid.impactOccurred(intensity: 1.0)
        }

        // Rumble echo - secondary thud
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            heavy.impactOccurred(intensity: 0.7)
        }

        // Settle - softer landing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            medium.impactOccurred(intensity: 0.5)
        }

        // Success confirmation - the satisfying finish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

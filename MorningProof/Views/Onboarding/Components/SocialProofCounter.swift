import SwiftUI

/// Animated counter that displays social proof numbers
/// Example: "27,432 people joined this week"
struct SocialProofCounter: View {
    let targetNumber: Int
    let prefix: String
    let suffix: String
    let icon: String?
    let iconColor: Color

    @State private var displayNumber: Int = 0
    @State private var hasAnimated = false

    init(
        targetNumber: Int,
        prefix: String = "",
        suffix: String,
        icon: String? = nil,
        iconColor: Color = MPColors.accent
    ) {
        self.targetNumber = targetNumber
        self.prefix = prefix
        self.suffix = suffix
        self.icon = icon
        self.iconColor = iconColor
    }

    var body: some View {
        HStack(spacing: MPSpacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }

            Text("\(prefix)\(displayNumber.formatted())\(suffix)")
                .font(MPFont.bodySmall())
                .foregroundColor(MPColors.textSecondary)
                .contentTransition(.numericText())
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            animateCounter()
        }
    }

    private func animateCounter() {
        let duration: Double = 1.5
        let steps = 30
        let interval = duration / Double(steps)
        let increment = targetNumber / steps

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                withAnimation(.easeOut(duration: 0.05)) {
                    displayNumber = min(increment * i, targetNumber)
                }
            }
        }
    }
}

/// Large hero-style social proof counter for welcome screens
struct HeroSocialProofCounter: View {
    let targetNumber: Int
    let suffix: String
    let icon: String

    @State private var displayNumber: Int = 0
    @State private var hasAnimated = false

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(MPColors.accent)

            Text("\(displayNumber.formatted()) \(suffix)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(MPColors.textSecondary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, MPSpacing.lg)
        .padding(.vertical, MPSpacing.md)
        .background(MPColors.surface.opacity(0.8))
        .cornerRadius(MPRadius.full)
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            animateCounter()
        }
    }

    private func animateCounter() {
        let duration: Double = 2.0
        let steps = 40
        let interval = duration / Double(steps)
        let increment = targetNumber / steps

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                withAnimation(.easeOut(duration: 0.05)) {
                    displayNumber = min(increment * i, targetNumber)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SocialProofCounter(
            targetNumber: 2847,
            suffix: " people joined this week",
            icon: "person.3.fill"
        )

        HeroSocialProofCounter(
            targetNumber: 27432,
            suffix: "people joined this week",
            icon: "person.3.fill"
        )
    }
    .padding()
}

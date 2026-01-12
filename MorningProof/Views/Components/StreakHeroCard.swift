import SwiftUI

struct StreakHeroCard: View {
    let currentStreak: Int
    let completedToday: Int
    let totalHabits: Int
    let isPerfectMorning: Bool
    @Binding var triggerPulse: Bool  // External trigger for flame pulse (when flying flame arrives)

    @State private var flameScale: CGFloat = 1.0
    @State private var streakNumberScale: CGFloat = 0.8
    @State private var showPerfectBadge = false
    @State private var glowPulse: CGFloat = 0.0
    @State private var arrivalPulse: CGFloat = 1.0  // For the big pulse when flame arrives

    // Milestone targets
    private let milestones = [7, 14, 21, 30, 60, 90, 180, 365]

    // MARK: - Glow Properties based on streak

    /// Glow radius increases with streak
    var glowRadius: CGFloat {
        guard currentStreak > 0 else { return 0 }
        switch currentStreak {
        case 1...6: return 8
        case 7...13: return 12
        case 14...29: return 16
        default: return 20
        }
    }

    /// Glow opacity increases with streak
    var glowOpacity: CGFloat {
        guard currentStreak > 0 else { return 0 }
        switch currentStreak {
        case 1...6: return 0.4
        case 7...13: return 0.5
        case 14...29: return 0.6
        default: return 0.7
        }
    }

    /// Glow color shifts from orange to gold as streak increases
    var glowColor: Color {
        guard currentStreak > 0 else { return .clear }
        switch currentStreak {
        case 1...6: return MPColors.accent // Orange
        case 7...29: return Color(red: 1.0, green: 0.7, blue: 0.2) // Orange-gold
        default: return MPColors.accentGold // Pure gold
        }
    }

    var nextMilestone: Int {
        milestones.first { $0 > currentStreak } ?? 365
    }

    var previousMilestone: Int {
        milestones.last { $0 <= currentStreak } ?? 0
    }

    var progressToNextMilestone: CGFloat {
        let range = nextMilestone - previousMilestone
        let progress = currentStreak - previousMilestone
        return CGFloat(progress) / CGFloat(range)
    }

    var body: some View {
        VStack(spacing: MPSpacing.lg) {
            // Streak display
            HStack(spacing: MPSpacing.md) {
                // Flame icon with dynamic glow animation
                Image(systemName: currentStreak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: MPIconSize.xl))
                    .foregroundStyle(flameGradient)
                    .scaleEffect(flameScale * arrivalPulse)  // Combines normal pulse with arrival pulse
                    // Always-on glow when streak > 0, with pulsing effect
                    .shadow(color: glowColor.opacity(glowOpacity + glowPulse * 0.2), radius: glowRadius + glowPulse * 4)
                    .shadow(color: glowColor.opacity(glowOpacity * 0.5 + glowPulse * 0.1), radius: glowRadius * 0.5)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: MPSpacing.xs) {
                        Text("\(currentStreak)")
                            .font(MPFont.displayMedium())
                            .foregroundColor(MPColors.textPrimary)
                            .scaleEffect(streakNumberScale)

                        Text("day streak")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    // Progress to next milestone
                    if currentStreak > 0 {
                        HStack(spacing: MPSpacing.sm) {
                            ProgressView(value: progressToNextMilestone)
                                .tint(MPColors.accent)
                                .frame(width: 100)

                            Text("\(nextMilestone) days")
                                .font(MPFont.labelTiny())
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }
                }

                Spacer()
            }

            // Perfect Morning status or progress
            HStack {
                if isPerfectMorning {
                    HStack(spacing: MPSpacing.sm) {
                        Image(systemName: "sparkles")
                            .foregroundColor(MPColors.accentGold)
                        Text("Perfect Morning!")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.accentGold)
                    }
                    .scaleEffect(showPerfectBadge ? 1.0 : 0.8)
                    .opacity(showPerfectBadge ? 1.0 : 0)
                } else {
                    HStack(spacing: MPSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(MPColors.success)
                        Text("\(completedToday)/\(totalHabits) habits completed")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textSecondary)
                    }
                }

                Spacer()
            }
        }
        .padding(MPSpacing.xl)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.xl)
        .mpShadow(.large)
        .onAppear {
            // Animate streak number scaling in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                streakNumberScale = 1.0
            }

            // Animate flame pulsing (scale)
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                flameScale = 1.1
            }

            // Animate glow pulsing (separate from scale for layered effect)
            if currentStreak > 0 {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowPulse = 1.0
                }
            }

            // Animate perfect badge if applicable
            if isPerfectMorning {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.3)) {
                    showPerfectBadge = true
                }
            }
        }
        .onChange(of: isPerfectMorning) { newValue in
            if newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showPerfectBadge = true
                }
                HapticManager.shared.success()
            }
        }
        .onChange(of: triggerPulse) { newValue in
            if newValue {
                // Big pulse when the flying flame arrives!
                withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                    arrivalPulse = 1.3
                }
                // Return to normal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        arrivalPulse = 1.0
                    }
                }
                // Reset the trigger
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    triggerPulse = false
                }
            }
        }
    }

    var flameGradient: LinearGradient {
        LinearGradient(
            colors: currentStreak > 0
                ? [MPColors.accent, MPColors.error]
                : [MPColors.textMuted, MPColors.textMuted.opacity(0.5)],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

#Preview {
    VStack(spacing: MPSpacing.xl) {
        StreakHeroCard(currentStreak: 14, completedToday: 3, totalHabits: 5, isPerfectMorning: false, triggerPulse: .constant(false))
        StreakHeroCard(currentStreak: 14, completedToday: 5, totalHabits: 5, isPerfectMorning: true, triggerPulse: .constant(false))
        StreakHeroCard(currentStreak: 0, completedToday: 0, totalHabits: 5, isPerfectMorning: false, triggerPulse: .constant(false))
    }
    .padding()
    .background(MPColors.background)
}

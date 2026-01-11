import SwiftUI

struct StreakHeroCard: View {
    let currentStreak: Int
    let completedToday: Int
    let totalHabits: Int
    let isPerfectMorning: Bool

    @State private var flameScale: CGFloat = 1.0
    @State private var streakNumberScale: CGFloat = 0.8
    @State private var showPerfectBadge = false

    // Milestone targets
    private let milestones = [7, 14, 21, 30, 60, 90, 180, 365]

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
                // Flame icon with animation
                Image(systemName: currentStreak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: MPIconSize.xl))
                    .foregroundStyle(flameGradient)
                    .scaleEffect(flameScale)
                    .shadow(color: MPColors.accent.opacity(0.5), radius: flameScale > 1 ? 10 : 0)

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

            // Animate flame pulsing
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                flameScale = 1.1
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
        StreakHeroCard(currentStreak: 14, completedToday: 3, totalHabits: 5, isPerfectMorning: false)
        StreakHeroCard(currentStreak: 14, completedToday: 5, totalHabits: 5, isPerfectMorning: true)
        StreakHeroCard(currentStreak: 0, completedToday: 0, totalHabits: 5, isPerfectMorning: false)
    }
    .padding()
    .background(MPColors.background)
}

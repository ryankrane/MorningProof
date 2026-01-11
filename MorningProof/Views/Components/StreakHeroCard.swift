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
        VStack(spacing: 16) {
            // Streak display
            HStack(spacing: 12) {
                // Flame icon with animation
                Image(systemName: currentStreak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 36))
                    .foregroundStyle(flameGradient)
                    .scaleEffect(flameScale)
                    .shadow(color: Color.orange.opacity(0.5), radius: flameScale > 1 ? 10 : 0)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(currentStreak)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
                            .scaleEffect(streakNumberScale)

                        Text("day streak")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                    }

                    // Progress to next milestone
                    if currentStreak > 0 {
                        HStack(spacing: 6) {
                            ProgressView(value: progressToNextMilestone)
                                .tint(Color.orange)
                                .frame(width: 100)

                            Text("\(nextMilestone) days")
                                .font(.caption2)
                                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                        }
                    }
                }

                Spacer()
            }

            // Perfect Morning status or progress
            HStack {
                if isPerfectMorning {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))
                        Text("Perfect Morning!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))
                    }
                    .scaleEffect(showPerfectBadge ? 1.0 : 0.8)
                    .opacity(showPerfectBadge ? 1.0 : 0)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.55, green: 0.75, blue: 0.55))
                        Text("\(completedToday)/\(totalHabits) habits completed")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    }
                }

                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 5)
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
                ? [Color.orange, Color.red]
                : [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakHeroCard(currentStreak: 14, completedToday: 3, totalHabits: 5, isPerfectMorning: false)
        StreakHeroCard(currentStreak: 14, completedToday: 5, totalHabits: 5, isPerfectMorning: true)
        StreakHeroCard(currentStreak: 0, completedToday: 0, totalHabits: 5, isPerfectMorning: false)
    }
    .padding()
    .background(Color(red: 0.98, green: 0.96, blue: 0.93))
}

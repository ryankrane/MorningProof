import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var viewModel: BedVerificationViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MPSpacing.lg) {
                        // Header stats
                        HStack(spacing: MPSpacing.xl) {
                            VStack {
                                Text("\(viewModel.achievements.unlockedCount)")
                                    .font(MPFont.displaySmall())
                                    .foregroundColor(MPColors.textPrimary)
                                Text("Unlocked")
                                    .font(MPFont.bodySmall())
                                    .foregroundColor(MPColors.textTertiary)
                            }

                            VStack {
                                Text("\(Achievement.allAchievements.count - viewModel.achievements.unlockedCount)")
                                    .font(MPFont.displaySmall())
                                    .foregroundColor(MPColors.textMuted)
                                Text("Locked")
                                    .font(MPFont.bodySmall())
                                    .foregroundColor(MPColors.textTertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MPSpacing.xxl)
                        .background(MPColors.surface)
                        .cornerRadius(MPRadius.xl)
                        .mpShadow(.medium)

                        // Achievements list
                        ForEach(Achievement.allAchievements) { achievement in
                            AchievementRow(
                                achievement: achievement,
                                isUnlocked: viewModel.achievements.isUnlocked(achievement.id),
                                unlockedDate: viewModel.achievements.getUnlockedDate(achievement.id),
                                currentStreak: viewModel.streakData.currentStreak
                            )
                        }
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.sm)
                    .padding(.bottom, MPSpacing.xxxl)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MPColors.primary)
                }
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let unlockedDate: Date?
    let currentStreak: Int

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? MPColors.accentLight : MPColors.surfaceSecondary)
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.icon)
                    .font(.system(size: MPIconSize.lg))
                    .foregroundColor(isUnlocked ? MPColors.accentGold : MPColors.textMuted)
            }

            // Info
            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text(achievement.title)
                    .font(MPFont.labelMedium())
                    .foregroundColor(isUnlocked ? MPColors.textPrimary : MPColors.textTertiary)

                Text(achievement.description)
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)

                if isUnlocked, let date = unlockedDate {
                    Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(MPFont.labelTiny())
                        .foregroundColor(MPColors.success)
                } else if !isUnlocked {
                    // Progress indicator
                    let progress = min(Double(currentStreak) / Double(achievement.requirement), 1.0)
                    HStack(spacing: MPSpacing.sm) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(MPColors.progressBg)
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(MPColors.textMuted)
                                    .frame(width: geo.size.width * progress, height: 6)
                            }
                        }
                        .frame(width: 60, height: 6)

                        Text("\(currentStreak)/\(achievement.requirement)")
                            .font(MPFont.labelTiny())
                            .foregroundColor(MPColors.textTertiary)
                    }
                }
            }

            Spacer()

            // Checkmark for unlocked
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(MPColors.success)
            }
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
}

#Preview {
    AchievementsView()
        .environmentObject(BedVerificationViewModel())
}

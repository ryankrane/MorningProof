import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var viewModel: BedVerificationViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: AchievementCategory? = nil

    private var visibleAchievements: [Achievement] {
        Achievement.visibleAchievements(unlockedIds: viewModel.achievements.unlockedIds)
    }

    private var achievementsByCategory: [AchievementCategory: [Achievement]] {
        Dictionary(grouping: visibleAchievements, by: { $0.category })
    }

    private var sortedCategories: [AchievementCategory] {
        AchievementCategory.allCases.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MPSpacing.lg) {
                        // Header stats
                        headerStats

                        // Category filter pills
                        categoryFilter

                        // Achievements by category
                        if let selected = selectedCategory {
                            // Show single category
                            if let achievements = achievementsByCategory[selected] {
                                categorySection(category: selected, achievements: achievements)
                            }
                        } else {
                            // Show all categories
                            ForEach(sortedCategories, id: \.self) { category in
                                if let achievements = achievementsByCategory[category], !achievements.isEmpty {
                                    categorySection(category: category, achievements: achievements)
                                }
                            }
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

    // MARK: - Header Stats
    private var headerStats: some View {
        HStack(spacing: MPSpacing.xl) {
            VStack {
                Text("\(viewModel.achievements.unlockedCount)")
                    .font(MPFont.displaySmall())
                    .foregroundColor(MPColors.textPrimary)
                Text("Unlocked")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }

            Divider()
                .frame(height: 40)

            VStack {
                Text("\(visibleAchievements.count - viewModel.achievements.unlockedCount)")
                    .font(MPFont.displaySmall())
                    .foregroundColor(MPColors.textMuted)
                Text("Locked")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }

            Divider()
                .frame(height: 40)

            VStack {
                Text("\(visibleAchievements.count)")
                    .font(MPFont.displaySmall())
                    .foregroundColor(MPColors.textSecondary)
                Text("Total")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.xxl)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.xl)
        .mpShadow(.medium)
    }

    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MPSpacing.sm) {
                // All button
                categoryPill(title: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = nil
                    }
                }

                ForEach(sortedCategories, id: \.self) { category in
                    let count = achievementsByCategory[category]?.count ?? 0
                    let unlockedCount = achievementsByCategory[category]?.filter { viewModel.achievements.isUnlocked($0.id) }.count ?? 0

                    if count > 0 {
                        categoryPill(
                            title: category.rawValue.components(separatedBy: " ").first ?? category.rawValue,
                            icon: category.icon,
                            badge: "\(unlockedCount)/\(count)",
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xs)
        }
    }

    private func categoryPill(title: String, icon: String, badge: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(MPFont.labelSmall())
                if let badge = badge {
                    Text(badge)
                        .font(MPFont.labelTiny())
                        .foregroundColor(isSelected ? MPColors.surface : MPColors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? MPColors.primary.opacity(0.3) : MPColors.surfaceSecondary)
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? MPColors.surface : MPColors.textSecondary)
            .padding(.horizontal, MPSpacing.md)
            .padding(.vertical, MPSpacing.sm)
            .background(isSelected ? MPColors.primary : MPColors.surface)
            .cornerRadius(MPRadius.full)
            .mpShadow(.small)
        }
    }

    // MARK: - Category Section
    private func categorySection(category: AchievementCategory, achievements: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            // Category header
            HStack(spacing: MPSpacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: MPIconSize.md))
                    .foregroundColor(MPColors.primary)

                Text(category.rawValue)
                    .font(MPFont.labelLarge())
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                let unlockedCount = achievements.filter { viewModel.achievements.isUnlocked($0.id) }.count
                Text("\(unlockedCount)/\(achievements.count)")
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
            }
            .padding(.top, MPSpacing.md)

            // Achievement rows
            ForEach(achievements) { achievement in
                AchievementRow(
                    achievement: achievement,
                    isUnlocked: viewModel.achievements.isUnlocked(achievement.id),
                    unlockedDate: viewModel.achievements.getUnlockedDate(achievement.id),
                    streakData: viewModel.streakData
                )
            }
        }
    }
}

// MARK: - Achievement Row
struct AchievementRow: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let unlockedDate: Date?
    let streakData: StreakData

    private var progressValue: Double {
        let stats = streakData.toAchievementStats()

        switch achievement.type {
        case .streak:
            return min(Double(stats.currentStreak) / Double(achievement.requirement), 1.0)
        case .totalCompletions:
            return min(Double(stats.totalCompletions) / Double(achievement.requirement), 1.0)
        case .earlyCompletion:
            guard let hour = achievement.secondaryRequirement else { return 0 }
            let count = stats.earlyCompletions[hour] ?? 0
            return min(Double(count) / Double(achievement.requirement), 1.0)
        case .comeback:
            switch achievement.id {
            case "bounce_back":
                return stats.lastLostStreak >= 7 && stats.currentStreak >= 1 ? 1.0 : 0
            case "phoenix_rising":
                if stats.comebackCount >= 1 {
                    return min(Double(stats.currentStreak) / 14.0, 1.0)
                }
                return 0
            default:
                return min(Double(stats.comebackCount) / Double(achievement.requirement), 1.0)
            }
        case .perfectWeek:
            return min(Double(stats.currentStreak) / 7.0, 1.0)
        case .weekendWarrior:
            return min(Double(stats.completedWeekends) / Double(achievement.requirement), 1.0)
        case .mondayMotivation:
            return min(Double(stats.mondayCompletions) / Double(achievement.requirement), 1.0)
        case .special:
            return 0
        }
    }

    private var progressText: String {
        let stats = streakData.toAchievementStats()

        switch achievement.type {
        case .streak:
            return "\(stats.currentStreak)/\(achievement.requirement)"
        case .totalCompletions:
            return "\(stats.totalCompletions)/\(achievement.requirement)"
        case .earlyCompletion:
            guard let hour = achievement.secondaryRequirement else { return "0/\(achievement.requirement)" }
            let count = stats.earlyCompletions[hour] ?? 0
            return "\(count)/\(achievement.requirement)"
        case .comeback:
            switch achievement.id {
            case "bounce_back", "phoenix_rising":
                return stats.comebackCount >= 1 ? "Ready" : "Keep going"
            default:
                return "\(stats.comebackCount)/\(achievement.requirement)"
            }
        case .perfectWeek:
            return "\(min(stats.currentStreak, 7))/7"
        case .weekendWarrior:
            return "\(stats.completedWeekends)/\(achievement.requirement)"
        case .mondayMotivation:
            return "\(stats.mondayCompletions)/\(achievement.requirement)"
        case .special:
            return achievement.isHidden ? "???" : "Special"
        }
    }

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? accentColor.opacity(0.2) : MPColors.surfaceSecondary)
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.icon)
                    .font(.system(size: MPIconSize.lg))
                    .foregroundColor(isUnlocked ? accentColor : MPColors.textMuted)
            }

            // Info
            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                HStack {
                    Text(achievement.title)
                        .font(MPFont.labelMedium())
                        .foregroundColor(isUnlocked ? MPColors.textPrimary : MPColors.textTertiary)

                    if achievement.isHidden && !isUnlocked {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 10))
                            .foregroundColor(MPColors.textMuted)
                    }
                }

                Text(achievement.isHidden && !isUnlocked ? "Hidden achievement" : achievement.description)
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)

                if isUnlocked, let date = unlockedDate {
                    Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(MPFont.labelTiny())
                        .foregroundColor(MPColors.success)
                } else if !isUnlocked && !achievement.isHidden {
                    // Progress indicator
                    HStack(spacing: MPSpacing.sm) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(MPColors.progressBg)
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(progressColor)
                                    .frame(width: geo.size.width * progressValue, height: 6)
                            }
                        }
                        .frame(width: 60, height: 6)

                        Text(progressText)
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

    private var accentColor: Color {
        switch achievement.category {
        case .streak: return MPColors.accentGold
        case .cumulative: return MPColors.primary
        case .timing: return Color.orange
        case .comeback: return Color.purple
        case .special: return Color.pink
        }
    }

    private var progressColor: Color {
        switch achievement.category {
        case .streak: return MPColors.accentGold.opacity(0.7)
        case .cumulative: return MPColors.primary.opacity(0.7)
        case .timing: return Color.orange.opacity(0.7)
        case .comeback: return Color.purple.opacity(0.7)
        case .special: return Color.pink.opacity(0.7)
        }
    }
}

#Preview {
    AchievementsView()
        .environmentObject(BedVerificationViewModel())
}

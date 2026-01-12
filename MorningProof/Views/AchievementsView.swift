import SwiftUI

// MARK: - Achievements Wall View
struct AchievementsView: View {
    @EnvironmentObject var viewModel: BedVerificationViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var selectedAchievement: Achievement? = nil

    private var visibleAchievements: [Achievement] {
        Achievement.visibleAchievements(unlockedIds: viewModel.achievements.unlockedIds)
    }

    private var achievementsByCategory: [AchievementCategory: [Achievement]] {
        Dictionary(grouping: allAchievementsForDisplay, by: { $0.category })
    }

    private var allAchievementsForDisplay: [Achievement] {
        if let selected = selectedCategory {
            return Achievement.allAchievements.filter { $0.category == selected }
        }
        return Achievement.allAchievements
    }

    private var sortedCategories: [AchievementCategory] {
        AchievementCategory.allCases
            .filter { $0 != .hidden }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private let columns = [
        GridItem(.flexible(), spacing: MPSpacing.md),
        GridItem(.flexible(), spacing: MPSpacing.md),
        GridItem(.flexible(), spacing: MPSpacing.md)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MPSpacing.lg) {
                        // Stats header
                        statsHeader

                        // Category filter
                        categoryFilter

                        // Achievement grid by category
                        achievementGrid
                    }
                    .padding(.horizontal, MPSpacing.lg)
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
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailSheet(
                    achievement: achievement,
                    isUnlocked: viewModel.achievements.isUnlocked(achievement.id),
                    unlockedDate: viewModel.achievements.getUnlockedDate(achievement.id),
                    progress: viewModel.achievements.progress(
                        for: achievement,
                        stats: viewModel.streakData.toAchievementStats()
                    ),
                    stats: viewModel.streakData.toAchievementStats()
                )
            }
        }
    }

    // MARK: - Stats Header
    private var statsHeader: some View {
        HStack(spacing: MPSpacing.lg) {
            // Unlocked count
            VStack(spacing: MPSpacing.xs) {
                Text("\(viewModel.achievements.unlockedCount)")
                    .font(MPFont.displaySmall())
                    .foregroundColor(MPColors.accentGold)
                Text("Unlocked")
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Hidden to find
            VStack(spacing: MPSpacing.xs) {
                let hiddenRemaining = Achievement.hiddenCount - viewModel.achievements.hiddenUnlockedCount
                Text("\(hiddenRemaining)")
                    .font(MPFont.displaySmall())
                    .foregroundColor(AchievementTier.hidden.color)
                Text("Hidden")
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Total
            VStack(spacing: MPSpacing.xs) {
                Text("\(Achievement.totalCount)")
                    .font(MPFont.displaySmall())
                    .foregroundColor(MPColors.textSecondary)
                Text("Total")
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, MPSpacing.xl)
        .padding(.horizontal, MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.xl)
        .mpShadow(.medium)
    }

    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MPSpacing.sm) {
                categoryPill(title: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = nil
                    }
                }

                ForEach(sortedCategories, id: \.self) { category in
                    let achievements = Achievement.allAchievements.filter { $0.category == category }
                    let unlockedCount = achievements.filter { viewModel.achievements.isUnlocked($0.id) }.count

                    categoryPill(
                        title: category.rawValue,
                        icon: category.icon,
                        badge: "\(unlockedCount)/\(achievements.count)",
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = selectedCategory == category ? nil : category
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

    // MARK: - Achievement Grid
    private var achievementGrid: some View {
        VStack(spacing: MPSpacing.xl) {
            if selectedCategory == nil {
                // Show all categories
                ForEach(sortedCategories, id: \.self) { category in
                    let achievements = Achievement.allAchievements.filter { $0.category == category }
                    if !achievements.isEmpty {
                        categoryGridSection(category: category, achievements: achievements)
                    }
                }

                // Hidden section (if any unlocked)
                let hiddenAchievements = Achievement.hiddenAchievements
                let unlockedHidden = hiddenAchievements.filter { viewModel.achievements.isUnlocked($0.id) }
                let remainingHidden = hiddenAchievements.count - unlockedHidden.count

                if !hiddenAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: MPSpacing.md) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(AchievementTier.hidden.color)
                            Text("Secret")
                                .font(MPFont.labelLarge())
                                .foregroundColor(MPColors.textPrimary)
                            Spacer()
                            Text("\(unlockedHidden.count)/\(hiddenAchievements.count)")
                                .font(MPFont.labelSmall())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        LazyVGrid(columns: columns, spacing: MPSpacing.md) {
                            // Show unlocked hidden achievements
                            ForEach(unlockedHidden) { achievement in
                                AchievementBadgeCard(
                                    achievement: achievement,
                                    isUnlocked: true,
                                    progress: 1.0
                                ) {
                                    selectedAchievement = achievement
                                }
                            }

                            // Show remaining as mystery cards
                            ForEach(0..<remainingHidden, id: \.self) { _ in
                                HiddenAchievementCard()
                            }
                        }
                    }
                }
            } else if let category = selectedCategory {
                // Show single category
                let achievements = Achievement.allAchievements.filter { $0.category == category }
                categoryGridSection(category: category, achievements: achievements)
            }
        }
    }

    private func categoryGridSection(category: AchievementCategory, achievements: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            // Category header
            HStack {
                Image(systemName: category.icon)
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

            // Achievement grid
            LazyVGrid(columns: columns, spacing: MPSpacing.md) {
                ForEach(achievements) { achievement in
                    let isUnlocked = viewModel.achievements.isUnlocked(achievement.id)
                    let progress = viewModel.achievements.progress(
                        for: achievement,
                        stats: viewModel.streakData.toAchievementStats()
                    )

                    AchievementBadgeCard(
                        achievement: achievement,
                        isUnlocked: isUnlocked,
                        progress: progress
                    ) {
                        selectedAchievement = achievement
                    }
                }
            }
        }
    }
}

// MARK: - Achievement Badge Card
struct AchievementBadgeCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    let onTap: () -> Void

    @State private var glowOpacity: Double = 0.4

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: MPSpacing.sm) {
                // Badge with tier ring
                ZStack {
                    // Glow effect for unlocked
                    if isUnlocked {
                        Circle()
                            .fill(achievement.tier.glowColor)
                            .frame(width: 72, height: 72)
                            .blur(radius: 10)
                            .opacity(glowOpacity)
                    }

                    // Tier ring
                    Circle()
                        .stroke(
                            isUnlocked ? achievement.tier.color : MPColors.surfaceSecondary,
                            lineWidth: isUnlocked ? 3 : 2
                        )
                        .frame(width: 64, height: 64)

                    // Background circle
                    Circle()
                        .fill(isUnlocked ? MPColors.surface : MPColors.surfaceSecondary)
                        .frame(width: 58, height: 58)

                    // Icon
                    Image(systemName: achievement.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isUnlocked ? achievement.tier.color : MPColors.textMuted)
                        .saturation(isUnlocked ? 1 : 0)
                        .opacity(isUnlocked ? 1 : 0.5)

                    // Lock overlay for locked
                    if !isUnlocked {
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 58, height: 58)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .offset(x: 18, y: 18)
                    }
                }

                // Title
                Text(achievement.title)
                    .font(MPFont.labelSmall())
                    .foregroundColor(isUnlocked ? MPColors.textPrimary : MPColors.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                // Tier badge or progress
                if isUnlocked {
                    TierBadge(tier: achievement.tier)
                } else {
                    ProgressBadge(progress: progress)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MPSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if isUnlocked {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.7
                }
            }
        }
    }
}

// MARK: - Tier Badge
struct TierBadge: View {
    let tier: AchievementTier

    var body: some View {
        Text(tier.displayName.uppercased())
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(tier.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tier.color.opacity(0.15))
            .cornerRadius(4)
    }
}

// MARK: - Progress Badge
struct ProgressBadge: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(MPColors.surfaceSecondary)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(MPColors.primary.opacity(0.6))
                    .frame(width: geo.size.width * progress, height: 4)
            }
        }
        .frame(width: 50, height: 4)
    }
}

// MARK: - Hidden Achievement Card
struct HiddenAchievementCard: View {
    @State private var pulseOpacity: Double = 0.3

    var body: some View {
        VStack(spacing: MPSpacing.sm) {
            ZStack {
                Circle()
                    .fill(AchievementTier.hidden.color.opacity(pulseOpacity))
                    .frame(width: 72, height: 72)
                    .blur(radius: 8)

                Circle()
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [5, 3])
                    )
                    .foregroundColor(AchievementTier.hidden.color.opacity(0.5))
                    .frame(width: 64, height: 64)

                Circle()
                    .fill(MPColors.surfaceSecondary)
                    .frame(width: 58, height: 58)

                Text("?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AchievementTier.hidden.color.opacity(0.6))
            }

            Text("???")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textMuted)

            Text("SECRET")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(AchievementTier.hidden.color.opacity(0.6))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AchievementTier.hidden.color.opacity(0.1))
                .cornerRadius(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.sm)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.5
            }
        }
    }
}

// MARK: - Achievement Detail Sheet
struct AchievementDetailSheet: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let unlockedDate: Date?
    let progress: Double
    let stats: AchievementStats

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        // Large badge
                        ZStack {
                            if isUnlocked {
                                Circle()
                                    .fill(achievement.tier.glowColor)
                                    .frame(width: 160, height: 160)
                                    .blur(radius: 30)
                            }

                            Circle()
                                .stroke(
                                    isUnlocked ? achievement.tier.color : MPColors.surfaceSecondary,
                                    lineWidth: isUnlocked ? 4 : 2
                                )
                                .frame(width: 120, height: 120)

                            Circle()
                                .fill(isUnlocked ? MPColors.surface : MPColors.surfaceSecondary)
                                .frame(width: 110, height: 110)

                            Image(systemName: achievement.isHidden && !isUnlocked ? "questionmark" : achievement.icon)
                                .font(.system(size: 48))
                                .foregroundColor(isUnlocked ? achievement.tier.color : MPColors.textMuted)
                                .saturation(isUnlocked ? 1 : 0)
                        }
                        .padding(.top, MPSpacing.xl)

                        // Title and tier
                        VStack(spacing: MPSpacing.sm) {
                            Text(achievement.isHidden && !isUnlocked ? "???" : achievement.title)
                                .font(MPFont.displaySmall())
                                .foregroundColor(MPColors.textPrimary)

                            if isUnlocked {
                                HStack(spacing: MPSpacing.sm) {
                                    Image(systemName: tierIcon)
                                        .foregroundColor(achievement.tier.color)
                                    Text(achievement.tier.displayName.uppercased())
                                        .font(MPFont.labelMedium())
                                        .foregroundColor(achievement.tier.color)
                                }
                                .padding(.horizontal, MPSpacing.md)
                                .padding(.vertical, MPSpacing.sm)
                                .background(achievement.tier.color.opacity(0.15))
                                .cornerRadius(MPRadius.md)
                            }
                        }

                        // Description
                        Text(achievement.isHidden && !isUnlocked ? "Keep going to discover this secret!" : achievement.description)
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MPSpacing.xl)

                        // Status card
                        VStack(spacing: MPSpacing.md) {
                            if isUnlocked, let date = unlockedDate {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(MPColors.success)
                                    Text("Unlocked \(date.formatted(date: .long, time: .omitted))")
                                        .font(MPFont.bodySmall())
                                        .foregroundColor(MPColors.textSecondary)
                                }
                            } else if !achievement.isHidden {
                                // Progress bar
                                VStack(spacing: MPSpacing.sm) {
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(MPColors.surfaceSecondary)
                                                .frame(height: 12)

                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(MPColors.primary)
                                                .frame(width: geo.size.width * progress, height: 12)
                                        }
                                    }
                                    .frame(height: 12)

                                    Text(progressText)
                                        .font(MPFont.labelSmall())
                                        .foregroundColor(MPColors.textTertiary)
                                }
                            }
                        }
                        .padding(MPSpacing.lg)
                        .frame(maxWidth: .infinity)
                        .background(MPColors.surface)
                        .cornerRadius(MPRadius.lg)
                        .padding(.horizontal, MPSpacing.lg)

                        Spacer(minLength: MPSpacing.xxxl)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MPColors.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var tierIcon: String {
        switch achievement.tier {
        case .bronze: return "medal"
        case .silver: return "medal.fill"
        case .gold: return "crown.fill"
        case .hidden: return "sparkles"
        }
    }

    private var progressText: String {
        switch achievement.type {
        case .streak:
            return "\(stats.currentStreak)/\(achievement.requirement) days"
        case .totalCompletions:
            return "\(stats.totalCompletions)/\(achievement.requirement) completions"
        case .earlyCompletion:
            let count = stats.earlyCompletions[7] ?? 0
            return "\(count)/\(achievement.requirement) early mornings"
        case .comeback:
            return stats.lastLostStreak >= 7 ? "Ready to unlock!" : "Break a 7+ day streak, then come back"
        case .rebuildStreak:
            if stats.hasRebuiltAfterLoss {
                return "\(stats.currentStreak)/\(achievement.requirement) days"
            }
            return "Rebuild after losing a streak"
        case .perfectMonth, .newYear, .anniversary:
            return "Special condition"
        }
    }
}

#Preview {
    AchievementsView()
        .environmentObject(BedVerificationViewModel())
}

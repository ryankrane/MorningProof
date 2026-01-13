import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: BedVerificationViewModel
    @State private var showAchievements = false
    @State private var showSettings = false
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background
            MPColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.xl) {
                    // Header
                    headerSection

                    // Main streak card
                    streakCard

                    // Progress to next achievement
                    if let next = viewModel.nextAchievement {
                        nextAchievementCard(next)
                    }

                    // Calendar
                    calendarCard

                    // Achievements button
                    achievementsButton

                    // Camera button
                    if !viewModel.streakData.hasCompletedToday {
                        cameraButton
                    }

                    Spacer(minLength: MPSpacing.xxxl)
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.top, MPSpacing.md)
            }

            // Tier-colored confetti overlay
            if viewModel.showConfetti, let achievement = viewModel.newAchievement {
                TierConfettiView(tier: achievement.tier)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Achievement unlock celebration popup
            if let achievement = viewModel.newAchievement {
                AchievementUnlockCelebrationView(
                    achievement: achievement,
                    onDismiss: { viewModel.dismissAchievement() }
                )
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(viewModel)
        }
    }

    // MARK: - Header

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text(greetingWithName)
                    .font(MPFont.headingMedium())
                    .foregroundColor(MPColors.textPrimary)

                if !viewModel.streakData.hasCompletedToday {
                    Text(deadlineText)
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textTertiary)
                }
            }

            Spacer()

            MPIconButton(icon: "gearshape.fill", size: MPIconSize.md) {
                showSettings = true
            }
        }
        .padding(.top, MPSpacing.sm)
    }

    var greetingWithName: String {
        if viewModel.settings.userName.isEmpty {
            return viewModel.greeting
        } else {
            return "\(viewModel.greeting), \(viewModel.settings.userName)"
        }
    }

    var deadlineText: String {
        let interval = viewModel.settings.timeUntilDeadline
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m until deadline"
        } else if minutes > 0 {
            return "\(minutes)m until deadline"
        } else {
            return "Deadline passed!"
        }
    }

    // MARK: - Streak Card

    var streakCard: some View {
        VStack(spacing: MPSpacing.lg) {
            if viewModel.streakData.hasCompletedToday {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: MPIconSize.hero))
                    .foregroundColor(MPColors.success)

                Text("Done for today!")
                    .font(MPFont.labelLarge())
                    .foregroundColor(MPColors.textPrimary)
            } else {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: MPIconSize.hero))
                    .foregroundColor(MPColors.primaryLight)

                Text("Make your bed")
                    .font(MPFont.labelLarge())
                    .foregroundColor(MPColors.textPrimary)
            }

            // Streak number with flame
            HStack(spacing: MPSpacing.sm) {
                Image(systemName: streakIcon)
                    .font(.system(size: MPIconSize.xl))
                    .foregroundColor(streakColor)

                Text("\(viewModel.streakData.currentStreak)")
                    .font(MPFont.displayMedium())
                    .foregroundColor(MPColors.textPrimary)

                Text("days")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textTertiary)
                    .padding(.top, MPSpacing.md)
            }

            // Stats row
            HStack(spacing: MPSpacing.xxl) {
                HomeStatPill(value: viewModel.streakData.longestStreak, label: "Best")
                HomeStatPill(value: viewModel.streakData.totalCompletions, label: "Total")
                HomeStatPill(value: viewModel.achievements.unlockedCount, label: "Awards")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.xxl)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.xl)
        .mpShadow(.large)
    }

    var streakIcon: String {
        switch viewModel.streakData.currentStreak {
        case 0: return "flame"
        case 1...6: return "flame.fill"
        case 7...13: return "flame.fill"
        case 14...29: return "star.fill"
        case 30...89: return "crown.fill"
        default: return "trophy.fill"
        }
    }

    var streakColor: Color {
        switch viewModel.streakData.currentStreak {
        case 0: return MPColors.textMuted
        case 1...6: return MPColors.accent
        case 7...13: return Color(red: 0.95, green: 0.5, blue: 0.2)
        case 14...29: return MPColors.warning
        case 30...89: return MPColors.accentGold
        default: return Color(red: 0.9, green: 0.7, blue: 0.1)
        }
    }

    // MARK: - Next Achievement Card

    func nextAchievementCard(_ achievement: Achievement) -> some View {
        MPCard(padding: MPSpacing.lg) {
            VStack(spacing: MPSpacing.md) {
                HStack {
                    Text("Next Achievement")
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textSecondary)
                    Spacer()
                    Text("\(viewModel.streakData.currentStreak)/\(achievement.requirement) days")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

                HStack(spacing: MPSpacing.md) {
                    MPIconBadge(icon: achievement.icon, size: .medium, style: .neutral)

                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text(achievement.title)
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: MPRadius.xs)
                                    .fill(MPColors.progressBg)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: MPRadius.xs)
                                    .fill(MPColors.primary)
                                    .frame(width: geo.size.width * viewModel.progressToNextAchievement, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
    }

    // MARK: - Calendar Card

    var calendarCard: some View {
        MPCard(padding: MPSpacing.lg) {
            VStack(spacing: MPSpacing.md) {
                HStack {
                    Text(monthYearString)
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)
                    Spacer()
                }

                CalendarGridView(streakData: viewModel.streakData)
            }
        }
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    // MARK: - Achievements Button

    var achievementsButton: some View {
        MPInteractiveCard(padding: MPSpacing.lg, action: { showAchievements = true }) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(MPColors.accentGold)
                Text("View All Achievements")
                    .font(MPFont.labelMedium())
                Spacer()
                Text("\(viewModel.achievements.unlockedCount)/\(Achievement.allAchievements.count)")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textTertiary)
                Image(systemName: "chevron.right")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }
            .foregroundColor(MPColors.textPrimary)
        }
    }

    // MARK: - Camera Button

    var cameraButton: some View {
        MPButton(title: "Verify Bed", style: .primary, icon: "camera.fill") {
            viewModel.openCamera()
        }
        .padding(.top, MPSpacing.sm)
    }

}

// MARK: - Supporting Views

private struct HomeStatPill: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: MPSpacing.xs) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(MPColors.textPrimary)
            Text(label)
                .font(MPFont.labelTiny())
                .foregroundColor(MPColors.textTertiary)
        }
    }
}

struct CalendarGridView: View {
    let streakData: StreakData

    var body: some View {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
              let daysRange = calendar.range(of: .day, in: .month, for: today) else {
            return AnyView(EmptyView())
        }
        let daysInMonth = daysRange.count
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offset = firstWeekday - 1

        return AnyView(VStack(spacing: MPSpacing.sm) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(MPFont.labelTiny())
                        .foregroundColor(MPColors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: MPSpacing.xs), count: 7), spacing: MPSpacing.sm) {
                // Empty cells for offset
                ForEach(0..<offset, id: \.self) { _ in
                    Text("")
                        .frame(height: 28)
                }

                // Day cells
                ForEach(1...daysInMonth, id: \.self) { day in
                    if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                        let isToday = calendar.isDateInToday(date)
                        let isCompleted = streakData.wasCompletedOn(date: date)
                        let isFuture = date > today

                        ZStack {
                            if isCompleted {
                                Circle()
                                    .fill(MPColors.success)
                                    .frame(width: 28, height: 28)
                            } else if isToday {
                                Circle()
                                    .stroke(MPColors.primary, lineWidth: 2)
                                    .frame(width: 28, height: 28)
                            }

                            Text("\(day)")
                                .font(MPFont.bodySmall())
                                .fontWeight(isToday ? .bold : .regular)
                                .foregroundColor(
                                    isCompleted ? .white :
                                        isFuture ? MPColors.textMuted :
                                        MPColors.textPrimary
                                )
                        }
                        .frame(height: 28)
                    }
                }
            }
        })
    }
}

#Preview {
    HomeView()
        .environmentObject(BedVerificationViewModel())
}

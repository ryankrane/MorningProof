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

            // Confetti overlay
            if viewModel.showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Achievement popup
            if let achievement = viewModel.newAchievement {
                achievementPopup(achievement)
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
                StatPill(value: viewModel.streakData.longestStreak, label: "Best")
                StatPill(value: viewModel.streakData.totalCompletions, label: "Total")
                StatPill(value: viewModel.achievements.unlockedCount, label: "Awards")
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

    // MARK: - Achievement Popup

    func achievementPopup(_ achievement: Achievement) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissAchievement()
                }

            VStack(spacing: MPSpacing.xl) {
                ZStack {
                    Circle()
                        .fill(MPColors.accentLight)
                        .frame(width: 100, height: 100)

                    Image(systemName: achievement.icon)
                        .font(.system(size: MPIconSize.xxl))
                        .foregroundColor(MPColors.accentGold)
                }

                Text("Achievement Unlocked!")
                    .font(MPFont.labelLarge())
                    .foregroundColor(MPColors.textTertiary)

                Text(achievement.title)
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)

                Text(achievement.description)
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)

                MPButton(title: "Awesome!", style: .primary, size: .medium) {
                    viewModel.dismissAchievement()
                }
            }
            .padding(MPSpacing.xxl)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.xl)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, MPSpacing.xxxl + MPSpacing.sm)
        }
    }
}

// MARK: - Supporting Views

struct StatPill: View {
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
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)!.count
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let offset = firstWeekday - 1

        VStack(spacing: MPSpacing.sm) {
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
                    let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)!
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
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
            }
        }
    }

    func createParticles(in size: CGSize) {
        let colors: [Color] = [
            MPColors.accent,
            MPColors.success,
            MPColors.accentGold,
            MPColors.primary,
            MPColors.error
        ]

        for i in 0..<50 {
            let particle = ConfettiParticle(
                id: i,
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                opacity: 1.0
            )
            particles.append(particle)
        }

        // Animate particles
        for i in 0..<particles.count {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 2...3)

            withAnimation(.easeOut(duration: duration).delay(delay)) {
                particles[i].position.y = size.height + 50
                particles[i].position.x += CGFloat.random(in: -100...100)
            }

            withAnimation(.easeIn(duration: 0.5).delay(delay + duration - 0.5)) {
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

#Preview {
    HomeView()
        .environmentObject(BedVerificationViewModel())
}

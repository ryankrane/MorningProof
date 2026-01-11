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
            Color(red: 0.98, green: 0.96, blue: 0.93)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
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

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
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
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingWithName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                if !viewModel.streakData.hasCompletedToday {
                    Text(deadlineText)
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                }
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.body)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
        .padding(.top, 8)
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
        VStack(spacing: 16) {
            if viewModel.streakData.hasCompletedToday {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 0.55, green: 0.75, blue: 0.55))

                Text("Done for today!")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
            } else {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color(red: 0.75, green: 0.65, blue: 0.55))

                Text("Make your bed")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
            }

            // Streak number with flame
            HStack(spacing: 8) {
                Image(systemName: streakIcon)
                    .font(.system(size: 28))
                    .foregroundColor(streakColor)

                Text("\(viewModel.streakData.currentStreak)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                Text("days")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                    .padding(.top, 12)
            }

            // Stats row
            HStack(spacing: 24) {
                StatPill(value: viewModel.streakData.longestStreak, label: "Best")
                StatPill(value: viewModel.streakData.totalCompletions, label: "Total")
                StatPill(value: viewModel.achievements.unlockedCount, label: "Awards")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
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
        case 0: return Color(red: 0.7, green: 0.65, blue: 0.6)
        case 1...6: return Color(red: 0.95, green: 0.6, blue: 0.3)
        case 7...13: return Color(red: 0.95, green: 0.5, blue: 0.2)
        case 14...29: return Color(red: 0.95, green: 0.75, blue: 0.2)
        case 30...89: return Color(red: 0.85, green: 0.65, blue: 0.2)
        default: return Color(red: 0.9, green: 0.7, blue: 0.1)
        }
    }

    // MARK: - Next Achievement Card

    func nextAchievementCard(_ achievement: Achievement) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Next Achievement")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                Spacer()
                Text("\(viewModel.streakData.currentStreak)/\(achievement.requirement) days")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
            }

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.95, green: 0.93, blue: 0.9))
                        .frame(width: 44, height: 44)
                    Image(systemName: achievement.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.7, green: 0.6, blue: 0.5))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(achievement.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0.92, green: 0.9, blue: 0.87))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(red: 0.55, green: 0.45, blue: 0.35))
                                .frame(width: geo.size.width * viewModel.progressToNextAchievement, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
    }

    // MARK: - Calendar Card

    var calendarCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(monthYearString)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
                Spacer()
            }

            CalendarGridView(streakData: viewModel.streakData)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    // MARK: - Achievements Button

    var achievementsButton: some View {
        Button {
            showAchievements = true
        } label: {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))
                Text("View All Achievements")
                    .fontWeight(.medium)
                Spacer()
                Text("\(viewModel.achievements.unlockedCount)/\(Achievement.allAchievements.count)")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
            }
            .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
        }
    }

    // MARK: - Camera Button

    var cameraButton: some View {
        Button {
            viewModel.openCamera()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "camera.fill")
                Text("Verify Bed")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color(red: 0.55, green: 0.45, blue: 0.35))
            .cornerRadius(16)
        }
        .padding(.top, 8)
    }

    // MARK: - Achievement Popup

    func achievementPopup(_ achievement: Achievement) -> some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissAchievement()
                }

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.95, blue: 0.85))
                        .frame(width: 100, height: 100)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 44))
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))
                }

                Text("Achievement Unlocked!")
                    .font(.headline)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))

                Text(achievement.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.dismissAchievement()
                } label: {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.55, green: 0.45, blue: 0.35))
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Supporting Views

struct StatPill: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
            Text(label)
                .font(.caption2)
                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
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

        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
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
                                .fill(Color(red: 0.55, green: 0.75, blue: 0.55))
                                .frame(width: 28, height: 28)
                        } else if isToday {
                            Circle()
                                .stroke(Color(red: 0.55, green: 0.45, blue: 0.35), lineWidth: 2)
                                .frame(width: 28, height: 28)
                        }

                        Text("\(day)")
                            .font(.caption)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundColor(
                                isCompleted ? .white :
                                    isFuture ? Color(red: 0.8, green: 0.75, blue: 0.7) :
                                    Color(red: 0.35, green: 0.28, blue: 0.22)
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
            Color(red: 0.95, green: 0.6, blue: 0.3),
            Color(red: 0.55, green: 0.75, blue: 0.55),
            Color(red: 0.85, green: 0.65, blue: 0.2),
            Color(red: 0.55, green: 0.45, blue: 0.35),
            Color(red: 0.9, green: 0.5, blue: 0.5)
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

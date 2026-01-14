import SwiftUI

// MARK: - Achievement Model

struct Achievement: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: Int
    let gradientColors: [Color]
    var isUnlocked: Bool
    var progress: Int

    var progressPercent: Double {
        min(Double(progress) / Double(requirement), 1.0)
    }
}

enum AchievementCategory: String, CaseIterable {
    case streaks = "Streaks"
    case lifetime = "Lifetime"
}

// MARK: - Achievement Data

enum AchievementData {
    static func all(currentStreak: Int, totalDays: Int) -> [Achievement] {
        [
            // Streaks
            Achievement(
                name: "One Week",
                description: "Maintain a 7-day streak",
                icon: "flame.fill",
                category: .streaks,
                requirement: 7,
                gradientColors: [Color(hex: "FF6B35"), Color(hex: "F7931E")],
                isUnlocked: currentStreak >= 7,
                progress: currentStreak
            ),
            Achievement(
                name: "Habit Formed",
                description: "Maintain a 21-day streak",
                icon: "flame.fill",
                category: .streaks,
                requirement: 21,
                gradientColors: [Color(hex: "FF4757"), Color(hex: "FF6B81")],
                isUnlocked: currentStreak >= 21,
                progress: currentStreak
            ),
            Achievement(
                name: "Monthly Master",
                description: "Maintain a 30-day streak",
                icon: "crown.fill",
                category: .streaks,
                requirement: 30,
                gradientColors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                isUnlocked: currentStreak >= 30,
                progress: currentStreak
            ),
            Achievement(
                name: "Quarterly Champion",
                description: "Maintain a 90-day streak",
                icon: "trophy.fill",
                category: .streaks,
                requirement: 90,
                gradientColors: [Color(hex: "9B59B6"), Color(hex: "8E44AD")],
                isUnlocked: currentStreak >= 90,
                progress: currentStreak
            ),
            Achievement(
                name: "Legendary",
                description: "Maintain a 365-day streak",
                icon: "star.fill",
                category: .streaks,
                requirement: 365,
                gradientColors: [Color(hex: "00D2FF"), Color(hex: "3A7BD5")],
                isUnlocked: currentStreak >= 365,
                progress: currentStreak
            ),
            // Lifetime
            Achievement(
                name: "Fifty Strong",
                description: "Complete 50 total days",
                icon: "50.circle.fill",
                category: .lifetime,
                requirement: 50,
                gradientColors: [Color(hex: "11998E"), Color(hex: "38EF7D")],
                isUnlocked: totalDays >= 50,
                progress: totalDays
            ),
            Achievement(
                name: "Century Club",
                description: "Complete 100 total days",
                icon: "medal.fill",
                category: .lifetime,
                requirement: 100,
                gradientColors: [Color(hex: "ED213A"), Color(hex: "93291E")],
                isUnlocked: totalDays >= 100,
                progress: totalDays
            ),
            Achievement(
                name: "Full Year",
                description: "Complete 365 total days",
                icon: "calendar.badge.checkmark",
                category: .lifetime,
                requirement: 365,
                gradientColors: [Color(hex: "4776E6"), Color(hex: "8E54E9")],
                isUnlocked: totalDays >= 365,
                progress: totalDays
            ),
            Achievement(
                name: "Thousand Days",
                description: "Complete 1000 total days",
                icon: "diamond.fill",
                category: .lifetime,
                requirement: 1000,
                gradientColors: [Color(hex: "F953C6"), Color(hex: "B91D73")],
                isUnlocked: totalDays >= 1000,
                progress: totalDays
            )
        ]
    }
}

// MARK: - Main Achievements View

struct AchievementsView: View {
    @ObservedObject var manager: MorningProofManager
    @State private var selectedAchievement: Achievement?
    @State private var showDetail = false
    @Environment(\.dismiss) private var dismiss

    private var achievements: [Achievement] {
        AchievementData.all(
            currentStreak: manager.settings.currentStreak,
            totalDays: manager.settings.totalPerfectMornings
        )
    }

    private var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var body: some View {
        ZStack {
            // Premium dark gradient background
            LinearGradient(
                colors: [
                    Color(hex: "0D0D0D"),
                    Color(hex: "1A1A1A"),
                    Color(hex: "0D0D0D")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle noise texture overlay
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.03))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                AchievementsHeader(
                    unlockedCount: unlockedCount,
                    totalCount: achievements.count,
                    onClose: { dismiss() }
                )

                // Achievement Grid
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: MPSpacing.xl) {
                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            let categoryAchievements = achievements.filter { $0.category == category }

                            // Subtle category divider
                            CategoryDivider(title: category.rawValue)
                                .padding(.top, category == .streaks ? 0 : MPSpacing.lg)

                            // 3-column grid
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: MPSpacing.lg),
                                    GridItem(.flexible(), spacing: MPSpacing.lg),
                                    GridItem(.flexible(), spacing: MPSpacing.lg)
                                ],
                                spacing: MPSpacing.xl
                            ) {
                                ForEach(categoryAchievements) { achievement in
                                    AchievementBadge(achievement: achievement)
                                        .onTapGesture {
                                            selectedAchievement = achievement
                                            showDetail = true
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MPSpacing.lg)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showDetail) {
            if let achievement = selectedAchievement {
                AchievementDetailSheet(achievement: achievement)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Header

struct AchievementsHeader: View {
    let unlockedCount: Int
    let totalCount: Int
    let onClose: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Achievements")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(unlockedCount) of \(totalCount) Unlocked")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Invisible spacer for balance
            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, MPSpacing.lg)
        .padding(.vertical, MPSpacing.md)
    }
}

// MARK: - Category Divider

struct CategoryDivider: View {
    let title: String

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.4))
                .tracking(1.5)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.vertical, MPSpacing.sm)
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let achievement: Achievement
    @State private var isAnimating = false
    @State private var shimmerOffset: CGFloat = -1

    private let badgeSize: CGFloat = 90

    var body: some View {
        VStack(spacing: MPSpacing.sm) {
            ZStack {
                // Background circle
                Circle()
                    .fill(achievement.isUnlocked ? unlockedBackground : lockedBackground)
                    .frame(width: badgeSize, height: badgeSize)

                // Outer glow for unlocked
                if achievement.isUnlocked {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    achievement.gradientColors[0].opacity(0.4),
                                    achievement.gradientColors[0].opacity(0.1),
                                    .clear
                                ],
                                center: .center,
                                startRadius: badgeSize / 2 - 5,
                                endRadius: badgeSize / 2 + 20
                            )
                        )
                        .frame(width: badgeSize + 40, height: badgeSize + 40)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .opacity(isAnimating ? 0.6 : 1.0)
                }

                // Inner gradient circle for unlocked
                if achievement.isUnlocked {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: achievement.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: badgeSize - 6, height: badgeSize - 6)

                    // Shimmer overlay
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.3),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: badgeSize - 6, height: badgeSize - 6)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white, .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: shimmerOffset * badgeSize)
                        )
                }

                // Frosted glass for locked
                if !achievement.isUnlocked {
                    Circle()
                        .fill(.ultraThinMaterial.opacity(0.5))
                        .frame(width: badgeSize - 6, height: badgeSize - 6)
                }

                // Icon
                Group {
                    if achievement.icon == "50.circle.fill" {
                        Text("50")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    } else {
                        Image(systemName: achievement.icon)
                            .font(.system(size: 32, weight: .medium))
                    }
                }
                .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.3))
                .shadow(color: achievement.isUnlocked ? .black.opacity(0.3) : .clear, radius: 2, y: 1)

                // Lock overlay for locked achievements
                if !achievement.isUnlocked {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .frame(width: badgeSize, height: badgeSize)
                    .offset(x: 8, y: 8)
                }
            }
            .frame(width: badgeSize + 40, height: badgeSize + 40)

            // Achievement name
            Text(achievement.name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.4))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .onAppear {
            if achievement.isUnlocked {
                // Subtle pulse animation
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
                // Shimmer animation
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false).delay(Double.random(in: 0...2))) {
                    shimmerOffset = 2
                }
            }
        }
    }

    private var unlockedBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(0.15),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var lockedBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.white.opacity(0.08),
                Color.white.opacity(0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    @State private var animateProgress = false

    var body: some View {
        VStack(spacing: MPSpacing.xl) {
            // Large badge display
            ZStack {
                if achievement.isUnlocked {
                    // Animated rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                achievement.gradientColors[0].opacity(0.2 - Double(index) * 0.05),
                                lineWidth: 1
                            )
                            .frame(width: CGFloat(140 + index * 30), height: CGFloat(140 + index * 30))
                    }
                }

                Circle()
                    .fill(
                        achievement.isUnlocked ?
                        LinearGradient(
                            colors: achievement.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: achievement.isUnlocked ? achievement.gradientColors[0].opacity(0.5) : .clear, radius: 20)

                Group {
                    if achievement.icon == "50.circle.fill" {
                        Text("50")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                    } else {
                        Image(systemName: achievement.icon)
                            .font(.system(size: 48, weight: .medium))
                    }
                }
                .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.4))
            }
            .padding(.top, MPSpacing.xl)

            // Achievement info
            VStack(spacing: MPSpacing.sm) {
                Text(achievement.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(achievement.description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
            }

            // Progress bar
            VStack(spacing: MPSpacing.sm) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: achievement.isUnlocked ? achievement.gradientColors : [Color.gray.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: animateProgress ? geometry.size.width * achievement.progressPercent : 0, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(achievement.progress)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("/ \(achievement.requirement)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))

                    Spacer()

                    if achievement.isUnlocked {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Unlocked")
                                .foregroundColor(.green)
                        }
                        .font(.system(size: 13, weight: .semibold))
                    } else {
                        Text("\(achievement.requirement - achievement.progress) to go")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()
        }
        .padding(.horizontal, MPSpacing.lg)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateProgress = true
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    AchievementsView(manager: MorningProofManager.shared)
}

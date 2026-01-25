import SwiftUI

// MARK: - Achievement Model

struct AchievementItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: AchievementItemCategory
    let requirement: Int
    let gradientColors: [Color]
    var isUnlocked: Bool
    var progress: Int
    var isHidden: Bool = false

    var progressPercent: Double {
        min(Double(progress) / Double(requirement), 1.0)
    }
}

enum AchievementItemCategory: String, CaseIterable {
    case streaks = "Streaks"
    case lifetime = "Lifetime"
    case secret = "Secret"

    var icon: String {
        switch self {
        case .streaks: return "flame.fill"
        case .lifetime: return "chart.bar.fill"
        case .secret: return "sparkles"
        }
    }
}

// MARK: - Achievement Data

enum AchievementData {
    static func all(
        currentStreak: Int,
        totalDays: Int,
        completedOnNewYear: Bool = false,
        perfectMonthsCompleted: Int = 0,
        completedOnAnniversary: Bool = false
    ) -> [AchievementItem] {
        [
            // MARK: - Streaks (6 achievements = 2 full rows)
            AchievementItem(
                name: "One Week",
                description: "Maintain a 7-day streak",
                icon: "flame.fill",
                category: .streaks,
                requirement: 7,
                gradientColors: [Color(hex: "FF6B35"), Color(hex: "F7931E")],
                isUnlocked: currentStreak >= 7,
                progress: currentStreak
            ),
            AchievementItem(
                name: "Habit Formed",
                description: "Maintain a 21-day streak",
                icon: "flame.fill",
                category: .streaks,
                requirement: 21,
                gradientColors: [Color(hex: "FF4757"), Color(hex: "FF6B81")],
                isUnlocked: currentStreak >= 21,
                progress: currentStreak
            ),
            AchievementItem(
                name: "Monthly Master",
                description: "Maintain a 30-day streak",
                icon: "crown.fill",
                category: .streaks,
                requirement: 30,
                gradientColors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                isUnlocked: currentStreak >= 30,
                progress: currentStreak
            ),
            AchievementItem(
                name: "Two Months Strong",
                description: "Maintain a 60-day streak",
                icon: "star.fill",
                category: .streaks,
                requirement: 60,
                gradientColors: [Color(hex: "A855F7"), Color(hex: "7C3AED")],
                isUnlocked: currentStreak >= 60,
                progress: currentStreak
            ),
            AchievementItem(
                name: "Quarterly Champion",
                description: "Maintain a 90-day streak",
                icon: "trophy.fill",
                category: .streaks,
                requirement: 90,
                gradientColors: [Color(hex: "9B59B6"), Color(hex: "8E44AD")],
                isUnlocked: currentStreak >= 90,
                progress: currentStreak
            ),
            AchievementItem(
                name: "Legendary",
                description: "Maintain a 365-day streak",
                icon: "sparkle",
                category: .streaks,
                requirement: 365,
                gradientColors: [Color(hex: "00D2FF"), Color(hex: "3A7BD5")],
                isUnlocked: currentStreak >= 365,
                progress: currentStreak
            ),
            // MARK: - Lifetime (6 achievements = 2 full rows)
            AchievementItem(
                name: "First Steps",
                description: "Complete 25 total days",
                icon: "figure.walk",
                category: .lifetime,
                requirement: 25,
                gradientColors: [Color(hex: "06B6D4"), Color(hex: "0891B2")],
                isUnlocked: totalDays >= 25,
                progress: totalDays
            ),
            AchievementItem(
                name: "Fifty Strong",
                description: "Complete 50 total days",
                icon: "50.circle.fill",
                category: .lifetime,
                requirement: 50,
                gradientColors: [Color(hex: "11998E"), Color(hex: "38EF7D")],
                isUnlocked: totalDays >= 50,
                progress: totalDays
            ),
            AchievementItem(
                name: "Century Club",
                description: "Complete 100 total days",
                icon: "medal.fill",
                category: .lifetime,
                requirement: 100,
                gradientColors: [Color(hex: "ED213A"), Color(hex: "93291E")],
                isUnlocked: totalDays >= 100,
                progress: totalDays
            ),
            AchievementItem(
                name: "Full Year",
                description: "Complete 365 total days",
                icon: "calendar.badge.checkmark",
                category: .lifetime,
                requirement: 365,
                gradientColors: [Color(hex: "4776E6"), Color(hex: "8E54E9")],
                isUnlocked: totalDays >= 365,
                progress: totalDays
            ),
            AchievementItem(
                name: "High Five Hundred",
                description: "Complete 500 total days",
                icon: "hand.raised.fill",
                category: .lifetime,
                requirement: 500,
                gradientColors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                isUnlocked: totalDays >= 500,
                progress: totalDays
            ),
            AchievementItem(
                name: "Thousand Days",
                description: "Complete 1000 total days",
                icon: "diamond.fill",
                category: .lifetime,
                requirement: 1000,
                gradientColors: [Color(hex: "F953C6"), Color(hex: "B91D73")],
                isUnlocked: totalDays >= 1000,
                progress: totalDays
            ),
            // MARK: - Secret (3 achievements = 1 full row)
            AchievementItem(
                name: "Fresh Start",
                description: "Complete on January 1st",
                icon: "party.popper.fill",
                category: .secret,
                requirement: 1,
                gradientColors: [Color(hex: "8B5CF6"), Color(hex: "6D28D9")],
                isUnlocked: completedOnNewYear,
                progress: completedOnNewYear ? 1 : 0,
                isHidden: true
            ),
            AchievementItem(
                name: "Flawless",
                description: "Complete every day of a calendar month",
                icon: "checkmark.seal.fill",
                category: .secret,
                requirement: 1,
                gradientColors: [Color(hex: "8B5CF6"), Color(hex: "6D28D9")],
                isUnlocked: perfectMonthsCompleted >= 1,
                progress: perfectMonthsCompleted >= 1 ? 1 : 0,
                isHidden: true
            ),
            AchievementItem(
                name: "Anniversary",
                description: "Complete on your Morning Proof anniversary",
                icon: "gift.fill",
                category: .secret,
                requirement: 1,
                gradientColors: [Color(hex: "8B5CF6"), Color(hex: "6D28D9")],
                isUnlocked: completedOnAnniversary,
                progress: completedOnAnniversary ? 1 : 0,
                isHidden: true
            )
        ]
    }
}

// MARK: - Main Achievements View

struct AchievementsView: View {
    @ObservedObject private var manager = MorningProofManager.shared
    @State private var selectedAchievement: AchievementItem?
    @State private var showDetail = false
    @Environment(\.dismiss) private var dismiss

    private let storageService = StorageService()

    private var achievements: [AchievementItem] {
        let streakData = storageService.loadStreakData()
        return AchievementData.all(
            currentStreak: manager.settings.currentStreak,
            totalDays: manager.settings.totalPerfectMornings,
            completedOnNewYear: streakData.completedOnNewYear,
            perfectMonthsCompleted: streakData.perfectMonthsCompleted,
            completedOnAnniversary: streakData.completedOnAnniversary
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
                        ForEach(AchievementItemCategory.allCases, id: \.self) { category in
                            let categoryAchievements = achievements.filter { $0.category == category }

                            // Subtle category divider
                            CategoryDivider(category: category)
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
        .overlay {
            // Achievement detail overlay popup (like info popups)
            if let achievement = selectedAchievement, showDetail {
                ZStack {
                    // Dimmed background - tap to dismiss
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showDetail = false
                            selectedAchievement = nil
                        }

                    // Achievement detail card with liquid glass effect
                    AchievementDetailCard(achievement: achievement) {
                        showDetail = false
                        selectedAchievement = nil
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showDetail)
        .swipeBack { dismiss() }
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
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            Text("Achievements")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            // Invisible spacer for balance
            Color.clear
                .frame(width: 60, height: 36)
        }
        .padding(.horizontal, MPSpacing.lg)
        .padding(.vertical, MPSpacing.md)
    }
}

// MARK: - Category Divider

struct CategoryDivider: View {
    let category: AchievementItemCategory

    private var categoryColor: Color {
        switch category {
        case .streaks:
            return Color(hex: "FF6B35") // Fire orange
        case .lifetime:
            return Color(hex: "06B6D4") // Teal/cyan
        case .secret:
            return Color(hex: "8B5CF6") // Purple
        }
    }

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, categoryColor.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(categoryColor)
                Text(category.rawValue.uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(categoryColor)
                    .tracking(1.5)
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [categoryColor.opacity(0.3), .clear],
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
    let achievement: AchievementItem
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

                // Icon - show mystery icon for hidden locked achievements
                Group {
                    if achievement.isHidden && !achievement.isUnlocked {
                        // Mystery icon for hidden locked achievements
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                    } else if achievement.icon == "50.circle.fill" {
                        Text("50")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    } else {
                        Image(systemName: achievement.icon)
                            .font(.system(size: 32, weight: .medium))
                    }
                }
                .foregroundColor(achievement.isUnlocked ? .white : (achievement.isHidden ? Color(hex: "8B5CF6").opacity(0.6) : .white.opacity(0.3)))
                .shadow(color: achievement.isUnlocked ? .black.opacity(0.3) : .clear, radius: 2, y: 1)

                // Lock overlay for locked achievements (but NOT for hidden achievements)
                if !achievement.isUnlocked && !achievement.isHidden {
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

            // Achievement name - show "???" for hidden locked achievements
            Text(achievement.isHidden && !achievement.isUnlocked ? "???" : achievement.name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(achievement.isUnlocked ? .white : (achievement.isHidden ? Color(hex: "8B5CF6").opacity(0.6) : .white.opacity(0.4)))
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

    private var unlockedBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.15),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var lockedBackground: LinearGradient {
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

// MARK: - Achievement Detail Card (Overlay Popup)

struct AchievementDetailCard: View {
    let achievement: AchievementItem
    let onDismiss: () -> Void
    @State private var animateProgress = false

    var body: some View {
        VStack(spacing: MPSpacing.lg) {
            // Large badge display
            ZStack {
                if achievement.isUnlocked {
                    // Animated rings with glass effect
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                achievement.gradientColors[0].opacity(0.3 - Double(index) * 0.08),
                                lineWidth: 1.5
                            )
                            .frame(width: CGFloat(100 + index * 25), height: CGFloat(100 + index * 25))
                    }
                }

                // Outer glow
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
                                startRadius: 30,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 10)
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
                            colors: achievement.isHidden ?
                                [Color(hex: "8B5CF6").opacity(0.3), Color(hex: "6D28D9").opacity(0.15)] :
                                [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: achievement.isUnlocked ? achievement.gradientColors[0].opacity(0.6) : .clear, radius: 15)

                // Icon - show mystery for hidden locked
                Group {
                    if achievement.isHidden && !achievement.isUnlocked {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 36, weight: .medium))
                    } else if achievement.icon == "50.circle.fill" {
                        Text("50")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                    } else {
                        Image(systemName: achievement.icon)
                            .font(.system(size: 36, weight: .medium))
                    }
                }
                .foregroundColor(achievement.isUnlocked ? .white : (achievement.isHidden ? Color(hex: "8B5CF6") : .white.opacity(0.4)))
            }

            // Achievement info
            VStack(spacing: MPSpacing.xs) {
                if achievement.isHidden && !achievement.isUnlocked {
                    Text("Secret Achievement")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Keep completing your mornings to discover this hidden achievement...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                } else {
                    Text(achievement.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(achievement.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }

            // Progress bar with glass styling (hide for hidden locked achievements)
            if !(achievement.isHidden && !achievement.isUnlocked) {
                VStack(spacing: MPSpacing.sm) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Glass background track
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.ultraThinMaterial.opacity(0.3))
                                .frame(height: 10)

                            // Progress fill
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    LinearGradient(
                                        colors: achievement.isUnlocked ? achievement.gradientColors : [Color.gray.opacity(0.5)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: animateProgress ? geometry.size.width * achievement.progressPercent : 0, height: 10)
                                .shadow(color: achievement.isUnlocked ? achievement.gradientColors[0].opacity(0.5) : .clear, radius: 4)
                        }
                    }
                    .frame(height: 10)

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
            }
        }
        .padding(MPSpacing.xl)
        .background(
            // Liquid glass background
            ZStack {
                // Base glass layer
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)

                // Gradient overlay for depth
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.black.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Subtle border
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.3), radius: 30, y: 10)
        .padding(.horizontal, MPSpacing.xl)
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
    AchievementsView()
}

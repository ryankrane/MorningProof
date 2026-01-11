import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var viewModel: BedVerificationViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.98, green: 0.96, blue: 0.93)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Header stats
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(viewModel.achievements.unlockedCount)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
                                Text("Unlocked")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                            }

                            VStack {
                                Text("\(Achievement.allAchievements.count - viewModel.achievements.unlockedCount)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.7, green: 0.65, blue: 0.6))
                                Text("Locked")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)

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
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
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
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ?
                          Color(red: 1.0, green: 0.95, blue: 0.85) :
                            Color(red: 0.95, green: 0.93, blue: 0.9))
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isUnlocked ?
                                     Color(red: 0.85, green: 0.65, blue: 0.2) :
                                        Color(red: 0.75, green: 0.7, blue: 0.65))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ?
                                     Color(red: 0.35, green: 0.28, blue: 0.22) :
                                        Color(red: 0.6, green: 0.55, blue: 0.5))

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))

                if isUnlocked, let date = unlockedDate {
                    Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(Color(red: 0.55, green: 0.75, blue: 0.55))
                } else if !isUnlocked {
                    // Progress indicator
                    let progress = min(Double(currentStreak) / Double(achievement.requirement), 1.0)
                    HStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(red: 0.92, green: 0.9, blue: 0.87))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(red: 0.75, green: 0.7, blue: 0.65))
                                    .frame(width: geo.size.width * progress, height: 6)
                            }
                        }
                        .frame(width: 60, height: 6)

                        Text("\(currentStreak)/\(achievement.requirement)")
                            .font(.caption2)
                            .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                    }
                }
            }

            Spacer()

            // Checkmark for unlocked
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color(red: 0.55, green: 0.75, blue: 0.55))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 3)
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
}

#Preview {
    AchievementsView()
        .environmentObject(BedVerificationViewModel())
}

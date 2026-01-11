import WidgetKit
import SwiftUI

// MARK: - Widget Background Extension
extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        self.containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
}

// MARK: - Timeline Entry
struct StreakEntry: TimelineEntry {
    let date: Date
    let currentStreak: Int
    let longestStreak: Int
    let completedHabits: Int
    let totalHabits: Int
}

// MARK: - Timeline Provider
struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(
            date: Date(),
            currentStreak: 7,
            longestStreak: 14,
            completedHabits: 3,
            totalHabits: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let data = SharedDataManager.loadWidgetData()
        let entry = StreakEntry(
            date: Date(),
            currentStreak: data.currentStreak,
            longestStreak: data.longestStreak,
            completedHabits: data.completedHabits,
            totalHabits: data.totalHabits
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let data = SharedDataManager.loadWidgetData()
        let entry = StreakEntry(
            date: Date(),
            currentStreak: data.currentStreak,
            longestStreak: data.longestStreak,
            completedHabits: data.completedHabits,
            totalHabits: data.totalHabits
        )

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct StreakWidgetView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    var smallView: some View {
        VStack(spacing: 8) {
            // Streak icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 50)

                Image(systemName: streakIcon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }

            // Streak count
            Text("\(entry.currentStreak)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text("day streak")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground()
    }

    var mediumView: some View {
        HStack(spacing: 16) {
            // Streak section
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)

                    Image(systemName: streakIcon)
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }

                Text("\(entry.currentStreak)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("day streak")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()
                .frame(height: 60)

            // Progress section
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Progress")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Text("\(entry.completedHabits)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("/ \(entry.totalHabits)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("habits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor)
                            .frame(width: geo.size.width * progressRatio, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .widgetBackground()
    }

    var streakIcon: String {
        if entry.currentStreak >= 30 {
            return "trophy.fill"
        } else if entry.currentStreak >= 14 {
            return "crown.fill"
        } else if entry.currentStreak >= 7 {
            return "star.fill"
        } else {
            return "flame.fill"
        }
    }

    var progressRatio: CGFloat {
        guard entry.totalHabits > 0 else { return 0 }
        return CGFloat(entry.completedHabits) / CGFloat(entry.totalHabits)
    }

    var progressColor: Color {
        if progressRatio >= 1.0 {
            return .green
        } else if progressRatio >= 0.5 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Widget Configuration
struct StreakWidget: Widget {
    let kind: String = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Track your morning routine streak")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Previews require iOS 17+
#if swift(>=5.9)
@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry(date: Date(), currentStreak: 7, longestStreak: 14, completedHabits: 3, totalHabits: 5)
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    StreakWidget()
} timeline: {
    StreakEntry(date: Date(), currentStreak: 7, longestStreak: 14, completedHabits: 3, totalHabits: 5)
}
#endif

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct HabitsEntry: TimelineEntry {
    let date: Date
    let habitStatuses: [SharedDataManager.HabitStatus]
    let cutoffTime: Date?
    let completedCount: Int
    let totalCount: Int
}

// MARK: - Timeline Provider
struct HabitsProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitsEntry {
        let data = SharedDataManager.WidgetData.placeholder
        return HabitsEntry(
            date: Date(),
            habitStatuses: data.habitStatuses,
            cutoffTime: data.cutoffTime,
            completedCount: data.completedHabits,
            totalCount: data.totalHabits
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HabitsEntry) -> Void) {
        let data = SharedDataManager.loadWidgetData()
        let entry = HabitsEntry(
            date: Date(),
            habitStatuses: data.habitStatuses,
            cutoffTime: data.cutoffTime,
            completedCount: data.completedHabits,
            totalCount: data.totalHabits
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitsEntry>) -> Void) {
        let data = SharedDataManager.loadWidgetData()
        let entry = HabitsEntry(
            date: Date(),
            habitStatuses: data.habitStatuses,
            cutoffTime: data.cutoffTime,
            completedCount: data.completedHabits,
            totalCount: data.totalHabits
        )

        // Update every 5 minutes for countdown accuracy
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct HabitsWidgetView: View {
    var entry: HabitsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }

    var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with countdown
            HStack {
                Text("Morning Habits")
                    .font(.headline)

                Spacer()

                if let cutoff = entry.cutoffTime, cutoff > Date() {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(timeRemaining)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(timeRemainingColor)
                }
            }

            // Progress indicator
            HStack(spacing: 4) {
                Text("\(entry.completedCount)/\(entry.totalCount)")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("complete")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if entry.completedCount == entry.totalCount && entry.totalCount > 0 {
                    Label("Perfect!", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            // Habit list (show first 4)
            HStack(spacing: 12) {
                ForEach(entry.habitStatuses.prefix(4), id: \.name) { habit in
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(habit.isCompleted ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                                .frame(width: 36, height: 36)

                            Image(systemName: habit.icon)
                                .font(.system(size: 16))
                                .foregroundColor(habit.isCompleted ? .green : .gray)
                        }

                        Text(habit.name.prefix(6))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .widgetBackground()
    }

    var largeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Morning Habits")
                        .font(.headline)
                    Text("\(entry.completedCount) of \(entry.totalCount) complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let cutoff = entry.cutoffTime, cutoff > Date() {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timeRemaining)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(timeRemainingColor)
                        Text("remaining")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Full habit list
            VStack(spacing: 8) {
                ForEach(entry.habitStatuses, id: \.name) { habit in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(habit.isCompleted ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                                .frame(width: 32, height: 32)

                            Image(systemName: habit.icon)
                                .font(.system(size: 14))
                                .foregroundColor(habit.isCompleted ? .green : .gray)
                        }

                        Text(habit.name)
                            .font(.subheadline)
                            .foregroundColor(habit.isCompleted ? .primary : .secondary)

                        Spacer()

                        if habit.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .widgetBackground()
    }

    var timeRemaining: String {
        guard let cutoff = entry.cutoffTime else { return "" }
        let interval = cutoff.timeIntervalSince(Date())
        if interval <= 0 { return "Time's up!" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var timeRemainingColor: Color {
        guard let cutoff = entry.cutoffTime else { return .secondary }
        let interval = cutoff.timeIntervalSince(Date())

        if interval <= 0 {
            return .red
        } else if interval <= 900 { // 15 minutes
            return .red
        } else if interval <= 1800 { // 30 minutes
            return .orange
        } else {
            return .secondary
        }
    }
}

// MARK: - Widget Configuration
struct HabitsWidget: Widget {
    let kind: String = "HabitsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitsProvider()) { entry in
            HabitsWidgetView(entry: entry)
        }
        .configurationDisplayName("Habits")
        .description("Track your morning habits and deadline")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// Previews require iOS 17+
#if swift(>=5.9)
@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    HabitsWidget()
} timeline: {
    HabitsEntry(
        date: Date(),
        habitStatuses: SharedDataManager.WidgetData.placeholder.habitStatuses,
        cutoffTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
        completedCount: 3,
        totalCount: 5
    )
}

@available(iOS 17.0, *)
#Preview(as: .systemLarge) {
    HabitsWidget()
} timeline: {
    HabitsEntry(
        date: Date(),
        habitStatuses: SharedDataManager.WidgetData.placeholder.habitStatuses,
        cutoffTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
        completedCount: 3,
        totalCount: 5
    )
}
#endif

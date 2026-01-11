import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes
@available(iOS 16.1, *)
struct MorningRoutineAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var completedHabits: Int
        var totalHabits: Int
        var lastCompletedHabit: String?
        var currentStreakDays: Int
    }

    var cutoffTime: Date
    var startTime: Date
}

// MARK: - Live Activity Widget
@available(iOS 16.1, *)
struct MorningRoutineLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MorningRoutineAttributes.self) { context in
            // Lock Screen / Banner view
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(context.state.currentStreakDays)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 4) {
                        Text("\(context.state.completedHabits)/\(context.state.totalHabits)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Morning Routine")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(progressColor(context.state))
                                    .frame(width: geo.size.width * progressRatio(context.state), height: 8)
                            }
                        }
                        .frame(height: 8)

                        // Time remaining
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(context.attributes.cutoffTime, style: .timer)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("remaining")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } compactLeading: {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(context.state.currentStreakDays)")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            } compactTrailing: {
                Text("\(context.state.completedHabits)/\(context.state.totalHabits)")
                    .font(.caption)
                    .fontWeight(.bold)
            } minimal: {
                Image(systemName: "sun.horizon.fill")
                    .foregroundColor(.orange)
            }
        }
    }

    private func progressRatio(_ state: MorningRoutineAttributes.ContentState) -> CGFloat {
        guard state.totalHabits > 0 else { return 0 }
        return CGFloat(state.completedHabits) / CGFloat(state.totalHabits)
    }

    private func progressColor(_ state: MorningRoutineAttributes.ContentState) -> Color {
        let ratio = progressRatio(state)
        if ratio >= 1.0 {
            return .green
        } else if ratio >= 0.5 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - Lock Screen View
@available(iOS 16.1, *)
struct LockScreenView: View {
    let context: ActivityViewContext<MorningRoutineAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Morning Routine")
                        .font(.headline)
                    Text("\(context.state.completedHabits) of \(context.state.totalHabits) complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Streak badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(context.state.currentStreakDays)")
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(12)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressColor)
                        .frame(width: geo.size.width * progressRatio, height: 12)
                }
            }
            .frame(height: 12)

            // Footer with time
            HStack {
                if let lastHabit = context.state.lastCompletedHabit {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(lastHabit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Countdown timer
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(context.attributes.cutoffTime, style: .timer)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(timeColor)
                }
            }
        }
        .padding()
        .activityBackgroundTint(Color(UIColor.systemBackground))
    }

    private var progressRatio: CGFloat {
        guard context.state.totalHabits > 0 else { return 0 }
        return CGFloat(context.state.completedHabits) / CGFloat(context.state.totalHabits)
    }

    private var progressColor: Color {
        if progressRatio >= 1.0 {
            return .green
        } else if progressRatio >= 0.5 {
            return .orange
        } else {
            return .blue
        }
    }

    private var timeColor: Color {
        let interval = context.attributes.cutoffTime.timeIntervalSince(Date())
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

// Previews require iOS 17+
#if swift(>=5.9)
@available(iOS 17.0, *)
#Preview("Lock Screen", as: .content, using: MorningRoutineAttributes(
    cutoffTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())!,
    startTime: Date()
)) {
    MorningRoutineLiveActivity()
} contentStates: {
    MorningRoutineAttributes.ContentState(
        completedHabits: 3,
        totalHabits: 5,
        lastCompletedHabit: "Made Bed",
        currentStreakDays: 7
    )
}
#endif

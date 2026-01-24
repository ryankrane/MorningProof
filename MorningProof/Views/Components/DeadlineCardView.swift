import SwiftUI

/// A clean, settings-style row for deadline selection
struct DeadlineCardView: View {
    @Binding var cutoffMinutes: Int
    @State private var showTimePicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text("DEADLINE")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textTertiary)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            Button {
                showTimePicker = true
            } label: {
                HStack {
                    Text("Complete by")
                        .font(.system(size: 17))
                        .foregroundColor(MPColors.textPrimary)

                    Spacer()

                    Text(TimeOptions.formatTime(cutoffMinutes))
                        .font(.system(size: 17))
                        .foregroundColor(MPColors.primary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MPColors.textMuted)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, MPSpacing.lg)
                .background(MPColors.surface)
                .cornerRadius(MPRadius.lg)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showTimePicker) {
            TimeWheelPicker(
                selectedMinutes: $cutoffMinutes,
                title: "Morning Deadline",
                subtitle: "Finish your routine by this time each day",
                timeOptions: TimeOptions.cutoffTime
            )
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var minutes = 540 // 9:00 AM

        var body: some View {
            DeadlineCardView(cutoffMinutes: $minutes)
                .padding()
                .background(MPColors.background)
        }
    }
    return PreviewWrapper()
}

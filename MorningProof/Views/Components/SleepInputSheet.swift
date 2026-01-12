import SwiftUI

struct SleepInputSheet: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    // Slider value in hours (4.0 to 12.0, step 0.25 = 15 min)
    @State private var sleepHours: Double = 8.0
    @State private var showConfetti = false

    private let minHours: Double = 4.0
    private let maxHours: Double = 12.0
    private let sleepGoal: Double = 7.0

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                VStack(spacing: MPSpacing.xxxl) {
                    Spacer()

                    // Header
                    VStack(spacing: MPSpacing.md) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: MPIconSize.hero))
                            .foregroundColor(MPColors.primaryLight)

                        Text("Hours Slept Last Night")
                            .font(MPFont.headingSmall())
                            .foregroundColor(MPColors.textPrimary)
                    }

                    // Large time display
                    VStack(spacing: MPSpacing.sm) {
                        Text(formattedSleepTime)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(sleepColor)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.15), value: sleepHours)

                        // Goal indicator
                        HStack(spacing: MPSpacing.xs) {
                            Image(systemName: sleepHours >= sleepGoal ? "checkmark.circle.fill" : "target")
                                .foregroundColor(sleepHours >= sleepGoal ? MPColors.success : MPColors.textTertiary)
                            Text("Goal: \(Int(sleepGoal))h")
                                .font(MPFont.bodyMedium())
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MPSpacing.xxl)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.xl)
                    .mpShadow(.medium)
                    .padding(.horizontal, MPSpacing.xl)

                    // Slider
                    VStack(spacing: MPSpacing.lg) {
                        HStack {
                            Text("\(Int(minHours))h")
                                .font(MPFont.labelSmall())
                                .foregroundColor(MPColors.textTertiary)

                            Slider(
                                value: $sleepHours,
                                in: minHours...maxHours,
                                step: 0.25
                            )
                            .tint(sleepColor)

                            Text("\(Int(maxHours))h")
                                .font(MPFont.labelSmall())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        // Quick select buttons
                        HStack(spacing: MPSpacing.md) {
                            ForEach([6.0, 7.0, 8.0, 9.0], id: \.self) { hours in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        sleepHours = hours
                                    }
                                } label: {
                                    Text("\(Int(hours))h")
                                        .font(MPFont.labelMedium())
                                        .foregroundColor(sleepHours == hours ? .white : MPColors.textSecondary)
                                        .frame(width: 50, height: 36)
                                        .background(sleepHours == hours ? MPColors.primary : MPColors.surfaceSecondary)
                                        .cornerRadius(MPRadius.sm)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MPSpacing.xl)

                    Spacer()

                    // Save button
                    MPButton(title: "Save", style: .primary) {
                        manager.updateManualSleep(hours: sleepHours)
                        HapticManager.shared.habitCompleted()

                        // Show confetti if goal is met
                        if sleepHours >= sleepGoal {
                            showConfetti = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                dismiss()
                            }
                        } else {
                            dismiss()
                        }
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.bottom, MPSpacing.xxxl)

                    // Confetti overlay
                    if showConfetti {
                        MiniConfettiView()
                            .allowsHitTesting(false)
                    }
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MPColors.textTertiary)
                }
            }
        }
    }

    private var formattedSleepTime: String {
        let hours = Int(sleepHours)
        let minutes = Int((sleepHours - Double(hours)) * 60)
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }

    private var sleepColor: Color {
        if sleepHours >= 7 && sleepHours <= 9 {
            return MPColors.success
        } else if sleepHours >= 6 {
            return MPColors.warning
        } else {
            return MPColors.error
        }
    }
}

#Preview {
    SleepInputSheet(manager: MorningProofManager.shared)
}

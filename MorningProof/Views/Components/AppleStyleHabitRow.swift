//
//  AppleStyleHabitRow.swift
//  MorningProof
//
//  Apple-inspired habit row component
//  Design philosophy: Status indicator, not celebration
//

import SwiftUI

// Import required types from the project
// HabitType, CustomHabit are in Models/Habit.swift
// MPColors is in Theme/Theme.swift

struct AppleStyleHabitRow: View {
    let habitType: HabitType
    let isCompleted: Bool
    let progress: CGFloat
    let subtitle: String
    let onTap: () -> Void
    let showActionIndicator: Bool

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Left: Status indicator (checkmark or icon)
                statusIndicator
                    .frame(width: 28, height: 28)

                // Middle: Habit info
                VStack(alignment: .leading, spacing: 2) {
                    Text(habitType.displayName)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(isCompleted ? MPColors.textSecondary : MPColors.textPrimary)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(MPColors.textTertiary)
                    }
                }

                Spacer()

                // Right: Action indicator or subtle progress
                trailingContent
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(MPColors.surface)
            .contentShape(Rectangle()) // Makes entire row tappable
        }
        .buttonStyle(AppleRowButtonStyle())
    }

    // MARK: - Status Indicator (Left Side)

    @ViewBuilder
    private var statusIndicator: some View {
        if isCompleted {
            // Completed: System green checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(MPColors.success)
                .symbolRenderingMode(.hierarchical)
        } else {
            // Incomplete: Habit icon in neutral circle
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                Image(systemName: habitType.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MPColors.textSecondary)
            }
        }
    }

    // MARK: - Trailing Content (Right Side)

    @ViewBuilder
    private var trailingContent: some View {
        if isCompleted {
            // Completed: No indicator (clean)
            EmptyView()
        } else if showActionIndicator {
            // Actionable: Chevron or camera icon
            Image(systemName: habitType.verificationTier == .aiVerified ? "camera.fill" : "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray3))
        } else if progress > 0 {
            // In progress: Subtle progress ring
            progressRing
        }
    }

    @ViewBuilder
    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(MPColors.accent, lineWidth: 2)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 24, height: 24)
    }
}

// MARK: - Button Style

struct AppleRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                MPColors.surface
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Habit Row Variant

struct AppleStyleCustomHabitRow: View {
    let habit: CustomHabit
    let isCompleted: Bool
    let progress: CGFloat
    let subtitle: String
    let onTap: () -> Void
    let showActionIndicator: Bool

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                statusIndicator
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(isCompleted ? MPColors.textSecondary : MPColors.textPrimary)

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(MPColors.textTertiary)
                    }
                }

                Spacer()

                trailingContent
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(MPColors.surface)
            .contentShape(Rectangle())
        }
        .buttonStyle(AppleRowButtonStyle())
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(MPColors.success)
                .symbolRenderingMode(.hierarchical)
        } else {
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                Image(systemName: habit.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MPColors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var trailingContent: some View {
        if isCompleted {
            EmptyView()
        } else if showActionIndicator {
            Image(systemName: habit.verificationTier == .aiVerified ? "camera.fill" : "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray3))
        } else if progress > 0 {
            progressRing
        }
    }

    @ViewBuilder
    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 2)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(MPColors.accent, lineWidth: 2)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 24, height: 24)
    }
}

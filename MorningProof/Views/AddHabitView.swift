import SwiftUI

/// A browser view showing all available habits grouped by verification type
/// Users can enable habits or create custom ones
struct AddHabitView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    @State private var showCreateCustomHabit = false
    @State private var preselectedVerificationType: CustomVerificationType? = nil

    // Group predefined habits by tier
    private var aiVerifiedHabits: [HabitType] {
        HabitType.allCases.filter { $0.tier == .aiVerified }
    }

    private var healthHabits: [HabitType] {
        HabitType.allCases.filter { $0.tier == .autoTracked }
    }

    private var selfReportedHabits: [HabitType] {
        HabitType.allCases.filter { $0.tier == .honorSystem }
    }

    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MPSpacing.xl) {
                    // Create custom habit button (at top for visibility)
                    createCustomHabitButton

                    // AI Verified section
                    habitSection(
                        title: "AI VERIFIED",
                        subtitle: "Photo or video verified",
                        icon: "sparkles",
                        habits: aiVerifiedHabits,
                        customHabits: manager.customHabits.filter { $0.verificationType == .aiVerified },
                        customType: .aiVerified
                    )

                    // Apple Health section
                    habitSection(
                        title: "APPLE HEALTH",
                        subtitle: "Auto-synced from Health",
                        icon: "heart.fill",
                        habits: healthHabits,
                        customHabits: [],
                        customType: nil
                    )

                    // Self-Reported section
                    habitSection(
                        title: "SELF-REPORTED",
                        subtitle: "Hold to confirm",
                        icon: "hand.tap.fill",
                        habits: selfReportedHabits,
                        customHabits: manager.customHabits.filter { $0.verificationType == .honorSystem },
                        customType: .honorSystem
                    )

                    Spacer(minLength: MPSpacing.xxxl)
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.top, MPSpacing.lg)
            }
        }
        .navigationTitle("Manage Habits")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showCreateCustomHabit = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(MPColors.primary)
                }
            }
        }
        .sheet(isPresented: $showCreateCustomHabit) {
            CustomHabitCreationSheet(manager: manager, preselectedVerificationType: preselectedVerificationType)
        }
        .onChange(of: showCreateCustomHabit) { _, isPresented in
            if !isPresented {
                preselectedVerificationType = nil
            }
        }
    }

    // MARK: - Habit Section

    private func habitSection(
        title: String,
        subtitle: String,
        icon: String,
        habits: [HabitType],
        customHabits: [CustomHabit],
        customType: CustomVerificationType?
    ) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            // Section header
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: MPSpacing.sm) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MPColors.textTertiary)
                    Text(title)
                        .font(MPFont.labelSmall())
                        .foregroundColor(MPColors.textTertiary)
                        .tracking(0.5)
                }
                Text(subtitle)
                    .font(MPFont.labelTiny())
                    .foregroundColor(MPColors.textMuted)
            }
            .padding(.leading, MPSpacing.xs)

            // Habits list
            VStack(spacing: 0) {
                // Predefined habits
                ForEach(habits) { habitType in
                    addHabitRow(habitType: habitType)

                    if habitType != habits.last || !customHabits.isEmpty {
                        Divider().padding(.leading, 60)
                    }
                }

                // Custom habits in this category
                ForEach(customHabits) { customHabit in
                    addCustomHabitRow(customHabit: customHabit)

                    if customHabit.id != customHabits.last?.id {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
        }
    }

    // MARK: - Add Habit Row (Predefined)

    private func addHabitRow(habitType: HabitType) -> some View {
        let config = manager.habitConfigs.first { $0.habitType == habitType }
        let isEnabled = config?.isEnabled ?? false

        return HStack(spacing: MPSpacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(isEnabled ? MPColors.success.opacity(0.12) : MPColors.primary.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: habitType.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isEnabled ? MPColors.success : MPColors.primary)
            }

            // Name
            Text(habitType.displayName)
                .font(MPFont.labelMedium())
                .foregroundColor(MPColors.textPrimary)

            Spacer()

            // Toggle button (tap to enable/disable)
            Button {
                manager.updateHabitConfig(habitType, isEnabled: !isEnabled)
            } label: {
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 24))
                    .foregroundColor(isEnabled ? MPColors.success : MPColors.primary)
            }
        }
        .padding(.vertical, MPSpacing.md)
        .padding(.horizontal, MPSpacing.lg)
        .contentShape(Rectangle())
    }

    // MARK: - Add Custom Habit Row

    private func addCustomHabitRow(customHabit: CustomHabit) -> some View {
        let config = manager.customHabitConfigs.first { $0.customHabitId == customHabit.id }
        let isEnabled = config?.isEnabled ?? true

        return HStack(spacing: MPSpacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(isEnabled ? MPColors.success.opacity(0.12) : MPColors.primary.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: customHabit.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isEnabled ? MPColors.success : MPColors.primary)
            }

            // Name with "Custom" label
            VStack(alignment: .leading, spacing: 2) {
                Text(customHabit.name)
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textPrimary)
                Text("Custom")
                    .font(MPFont.labelTiny())
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()

            // Toggle button (tap to enable/disable)
            Button {
                manager.toggleCustomHabit(customHabit.id, isEnabled: !isEnabled)
            } label: {
                Image(systemName: isEnabled ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 24))
                    .foregroundColor(isEnabled ? MPColors.success : MPColors.primary)
            }
        }
        .padding(.vertical, MPSpacing.md)
        .padding(.horizontal, MPSpacing.lg)
        .contentShape(Rectangle())
    }

    // MARK: - Create Custom Habit Button

    private var createCustomHabitButton: some View {
        Button {
            showCreateCustomHabit = true
        } label: {
            HStack(spacing: MPSpacing.sm) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                Text("Create Custom Habit")
                    .font(MPFont.labelMedium())
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: MPButtonHeight.md)
            .background(MPColors.primary)
            .cornerRadius(MPRadius.lg)
        }
    }
}

#Preview {
    NavigationStack {
        AddHabitView(manager: MorningProofManager.shared)
    }
}

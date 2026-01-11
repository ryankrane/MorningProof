import SwiftUI

struct MorningProofSettingsView: View {
    @ObservedObject var manager: MorningProofManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var userName: String = ""
    @State private var wakeTimeHour: Int = 7
    @State private var wakeTimeMinute: Int = 0
    @State private var cutoffHour: Int = 9
    @State private var showResetConfirmation = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xxl) {
                        // Subscription Section
                        subscriptionSection

                        // Profile Section
                        settingsSection(title: "Profile") {
                            VStack(alignment: .leading, spacing: MPSpacing.md) {
                                Text("Your Name")
                                    .font(MPFont.bodyMedium())
                                    .foregroundColor(MPColors.textTertiary)

                                TextField("Enter your name", text: $userName)
                                    .textFieldStyle(.plain)
                                    .padding(MPSpacing.lg)
                                    .background(MPColors.background)
                                    .cornerRadius(MPRadius.sm)
                            }
                        }

                        // Time Settings
                        settingsSection(title: "Schedule") {
                            VStack(spacing: MPSpacing.lg) {
                                HStack {
                                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                                        Text("Wake Time")
                                            .font(MPFont.labelMedium())
                                            .foregroundColor(MPColors.textPrimary)
                                        Text("When you plan to wake up")
                                            .font(MPFont.bodySmall())
                                            .foregroundColor(MPColors.textTertiary)
                                    }

                                    Spacer()

                                    timePicker(hour: $wakeTimeHour, minute: $wakeTimeMinute)
                                }

                                Divider()

                                HStack {
                                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                                        Text("Morning Cutoff")
                                            .font(MPFont.labelMedium())
                                            .foregroundColor(MPColors.textPrimary)
                                        Text("Deadline to complete habits")
                                            .font(MPFont.bodySmall())
                                            .foregroundColor(MPColors.textTertiary)
                                    }

                                    Spacer()

                                    Picker("Cutoff", selection: $cutoffHour) {
                                        ForEach(6..<13) { hour in
                                            Text("\(hour):00 AM").tag(hour)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(MPColors.primary)
                                }
                            }
                        }

                        // Habits Section
                        settingsSection(title: "Habits") {
                            VStack(spacing: 0) {
                    ForEach(manager.habitConfigs) { config in
                        habitToggleRow(config: config)

                        if config.id != manager.habitConfigs.last?.id {
                            Divider()
                                .padding(.leading, 50)
                        }
                    }
                }
                        }

                        // Danger Zone
                        settingsSection(title: "Data") {
                            Button {
                                showResetConfirmation = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Reset All Data")
                                }
                                .font(MPFont.bodyMedium())
                                .foregroundColor(MPColors.error)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, MPSpacing.md)
                            }
                        }

                        // App Info
                        VStack(spacing: MPSpacing.xs) {
                            Text("Morning Proof")
                                .font(MPFont.labelSmall())
                                .foregroundColor(MPColors.textTertiary)
                            Text("Version 1.0")
                                .font(MPFont.labelTiny())
                                .foregroundColor(MPColors.textMuted)
                        }
                        .padding(.top, MPSpacing.xl)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.xl)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(MPColors.primary)
                }
            }
            .onAppear {
                loadSettings()
            }
            .alert("Reset All Data?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    manager.resetAllData()
                    dismiss()
                }
            } message: {
                Text("This will delete all your habits, streaks, and settings. This cannot be undone.")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(subscriptionManager: subscriptionManager)
            }
        }
    }

    // MARK: - Subscription Section

    var subscriptionSection: some View {
        VStack(spacing: MPSpacing.md) {
            if subscriptionManager.isPremium {
                // Premium status
                HStack {
                    ZStack {
                        Circle()
                            .fill(MPColors.accentGradient)
                            .frame(width: 44, height: 44)

                        Image(systemName: "crown.fill")
                            .font(.system(size: MPIconSize.sm))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: MPSpacing.sm) {
                            Text("Premium")
                                .font(MPFont.labelLarge())
                                .foregroundColor(MPColors.textPrimary)

                            if subscriptionManager.isInTrial {
                                Text("\(subscriptionManager.trialDaysRemaining) days left")
                                    .font(MPFont.bodySmall())
                                    .fontWeight(.medium)
                                    .foregroundColor(MPColors.accent)
                                    .padding(.horizontal, MPSpacing.sm)
                                    .padding(.vertical, 3)
                                    .background(MPColors.accentLight)
                                    .cornerRadius(MPRadius.sm)
                            }
                        }

                        Text(subscriptionManager.isInTrial ? "Free trial active" : "All features unlocked")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()
                }
                .padding(MPSpacing.lg)
                .background(MPColors.surface)
                .cornerRadius(MPRadius.lg)
                .mpShadow(.small)
            } else {
                // Upgrade prompt
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(MPColors.surfaceSecondary)
                                .frame(width: 44, height: 44)

                            Image(systemName: "crown")
                                .font(.system(size: MPIconSize.sm))
                                .foregroundColor(MPColors.textTertiary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Premium")
                                .font(MPFont.labelLarge())
                                .foregroundColor(MPColors.textPrimary)

                            Text("Unlimited habits, AI verifications & more")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }
                    .padding(MPSpacing.lg)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)
                    .mpShadow(.small)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text(title.uppercased())
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textTertiary)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            VStack {
                content()
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
        }
    }

    func timePicker(hour: Binding<Int>, minute: Binding<Int>) -> some View {
        HStack(spacing: MPSpacing.xs) {
            Picker("Hour", selection: hour) {
                ForEach(4..<12) { h in
                    Text("\(h)").tag(h)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 50)

            Text(":")
                .foregroundColor(MPColors.textSecondary)

            Picker("Minute", selection: minute) {
                ForEach([0, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 50)

            Text("AM")
                .font(MPFont.bodySmall())
                .foregroundColor(MPColors.textTertiary)
        }
        .tint(MPColors.primary)
    }

    func habitToggleRow(config: HabitConfig) -> some View {
        HStack(spacing: MPSpacing.lg) {
            Image(systemName: config.habitType.icon)
                .font(.system(size: MPIconSize.sm))
                .foregroundColor(MPColors.textTertiary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(config.habitType.displayName)
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textPrimary)

                Text(config.habitType.tier.description)
                    .font(MPFont.labelTiny())
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { config.isEnabled },
                set: { newValue in
                    manager.updateHabitConfig(config.habitType, isEnabled: newValue)
                }
            ))
            .tint(MPColors.primary)
        }
        .padding(.vertical, MPSpacing.sm)
    }

    func loadSettings() {
        userName = manager.settings.userName
        wakeTimeHour = manager.settings.wakeTimeHour
        wakeTimeMinute = manager.settings.wakeTimeMinute
        cutoffHour = manager.settings.morningCutoffHour
    }

    func saveSettings() {
        manager.settings.userName = userName
        manager.settings.wakeTimeHour = wakeTimeHour
        manager.settings.wakeTimeMinute = wakeTimeMinute
        manager.settings.morningCutoffHour = cutoffHour
        manager.saveCurrentState()
    }
}

#Preview {
    MorningProofSettingsView(manager: MorningProofManager.shared)
}

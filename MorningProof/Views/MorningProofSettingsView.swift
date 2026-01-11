import SwiftUI

struct MorningProofSettingsView: View {
    @ObservedObject var manager: MorningProofManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var userName: String = ""
    @State private var cutoffMinutes: Int = 540  // 9:00 AM
    @State private var showResetConfirmation = false
    @State private var showPaywall = false
    @State private var showAppLockingSheet = false

    // Notification settings
    @State private var notificationsEnabled = true
    @State private var morningReminderTime: Int = 420
    @State private var countdownWarning15 = true
    @State private var countdownWarning5 = true
    @State private var countdownWarning1 = true

    // App Locking settings
    @State private var appLockingEnabled = false
    @State private var lockGracePeriod: Int = 5

    // Accountability settings
    @State private var strictModeEnabled = false
    @State private var allowStreakRecovery = true

    // Goals settings
    @State private var weeklyPerfectMorningsGoal: Int = 5
    @State private var customSleepGoal: Double = 7.0
    @State private var customStepGoal: Int = 500

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

                                TextField("", text: $userName, prompt: Text("Enter your name").foregroundColor(MPColors.textSecondary))
                                    .textFieldStyle(.plain)
                                    .foregroundColor(MPColors.textPrimary)
                                    .padding(MPSpacing.lg)
                                    .background(MPColors.background)
                                    .cornerRadius(MPRadius.sm)
                            }
                        }

                        // Time Settings
                        settingsSection(title: "Schedule") {
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

                                Picker("Cutoff", selection: $cutoffMinutes) {
                                    ForEach(MorningProofSettings.cutoffTimeOptions, id: \.minutes) { option in
                                        Text(option.label).tag(option.minutes)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(MPColors.primary)
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

                        // Notifications Section
                        notificationsSection

                        // App Locking Section
                        appLockingSection

                        // Accountability Section
                        accountabilitySection

                        // Goals Section
                        goalsSection

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
        cutoffMinutes = manager.settings.morningCutoffMinutes

        // Notifications
        notificationsEnabled = manager.settings.notificationsEnabled
        morningReminderTime = manager.settings.morningReminderTime
        countdownWarning15 = manager.settings.countdownWarnings.contains(15)
        countdownWarning5 = manager.settings.countdownWarnings.contains(5)
        countdownWarning1 = manager.settings.countdownWarnings.contains(1)

        // App Locking
        appLockingEnabled = manager.settings.appLockingEnabled
        lockGracePeriod = manager.settings.lockGracePeriod

        // Accountability
        strictModeEnabled = manager.settings.strictModeEnabled
        allowStreakRecovery = manager.settings.allowStreakRecovery

        // Goals
        weeklyPerfectMorningsGoal = manager.settings.weeklyPerfectMorningsGoal
        customSleepGoal = manager.settings.customSleepGoal
        customStepGoal = manager.settings.customStepGoal
    }

    func saveSettings() {
        manager.settings.userName = userName
        manager.settings.morningCutoffMinutes = cutoffMinutes

        // Notifications
        manager.settings.notificationsEnabled = notificationsEnabled
        manager.settings.morningReminderTime = morningReminderTime

        var warnings: [Int] = []
        if countdownWarning15 { warnings.append(15) }
        if countdownWarning5 { warnings.append(5) }
        if countdownWarning1 { warnings.append(1) }
        manager.settings.countdownWarnings = warnings

        // App Locking
        manager.settings.appLockingEnabled = appLockingEnabled
        manager.settings.lockGracePeriod = lockGracePeriod

        // Accountability
        manager.settings.strictModeEnabled = strictModeEnabled
        manager.settings.allowStreakRecovery = allowStreakRecovery

        // Goals
        manager.settings.weeklyPerfectMorningsGoal = weeklyPerfectMorningsGoal
        manager.settings.customSleepGoal = customSleepGoal
        manager.settings.customStepGoal = customStepGoal

        manager.saveCurrentState()

        // Update notification schedule
        Task {
            await notificationManager.updateNotificationSchedule(settings: manager.settings)
        }
    }

    // MARK: - Notifications Section

    var notificationsSection: some View {
        settingsSection(title: "Notifications") {
            VStack(spacing: MPSpacing.lg) {
                // Enable toggle
                HStack {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text("Enable Notifications")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)
                        Text("Get reminders and countdown alerts")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $notificationsEnabled)
                        .tint(MPColors.primary)
                        .onChange(of: notificationsEnabled) { newValue in
                            if newValue {
                                Task {
                                    _ = await notificationManager.requestPermission()
                                }
                            }
                        }
                }

                if notificationsEnabled {
                    Divider()

                    // Morning reminder time
                    HStack {
                        VStack(alignment: .leading, spacing: MPSpacing.xs) {
                            Text("Morning Reminder")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.textPrimary)
                            Text("Wake up notification")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        Spacer()

                        Picker("Time", selection: $morningReminderTime) {
                            ForEach(NotificationManager.reminderTimeOptions, id: \.minutes) { option in
                                Text(option.label).tag(option.minutes)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(MPColors.primary)
                    }

                    Divider()

                    // Countdown warnings
                    VStack(alignment: .leading, spacing: MPSpacing.md) {
                        Text("Countdown Warnings")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)

                        HStack(spacing: MPSpacing.md) {
                            warningToggle(minutes: 15, isOn: $countdownWarning15)
                            warningToggle(minutes: 5, isOn: $countdownWarning5)
                            warningToggle(minutes: 1, isOn: $countdownWarning1)
                        }
                    }
                }
            }
        }
    }

    func warningToggle(minutes: Int, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Text("\(minutes) min")
                .font(MPFont.labelSmall())
                .foregroundColor(isOn.wrappedValue ? .white : MPColors.textSecondary)
                .padding(.horizontal, MPSpacing.md)
                .padding(.vertical, MPSpacing.sm)
                .background(isOn.wrappedValue ? MPColors.primary : MPColors.surfaceSecondary)
                .cornerRadius(MPRadius.full)
        }
    }

    // MARK: - App Locking Section

    var appLockingSection: some View {
        settingsSection(title: "App Locking") {
            VStack(spacing: MPSpacing.lg) {
                // Enable toggle
                HStack {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        HStack(spacing: MPSpacing.sm) {
                            Text("Lock Apps")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.textPrimary)

                            Text("COMING SOON")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(MPColors.accent)
                                .cornerRadius(MPRadius.xs)
                        }
                        Text("Block distracting apps until habits are complete")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $appLockingEnabled)
                        .tint(MPColors.primary)
                }

                if appLockingEnabled {
                    Divider()

                    // Select apps button
                    Button {
                        showAppLockingSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "apps.iphone")
                                .foregroundColor(MPColors.primary)
                            Text("Select Apps to Lock")
                                .font(MPFont.bodyMedium())
                                .foregroundColor(MPColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }

                    Divider()

                    // Grace period
                    HStack {
                        VStack(alignment: .leading, spacing: MPSpacing.xs) {
                            Text("Grace Period")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.textPrimary)
                            Text("Time after cutoff before locking")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        Spacer()

                        Picker("Grace", selection: $lockGracePeriod) {
                            ForEach(NotificationManager.gracePeriodOptions, id: \.minutes) { option in
                                Text(option.label).tag(option.minutes)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(MPColors.primary)
                    }

                    // Info note
                    HStack(spacing: MPSpacing.sm) {
                        Image(systemName: "info.circle")
                            .foregroundColor(MPColors.textTertiary)
                        Text("Requires iOS 16+ and Screen Time permission")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }
                    .padding(.top, MPSpacing.xs)
                }
            }
        }
        .sheet(isPresented: $showAppLockingSheet) {
            AppLockingSettingsView()
        }
    }

    // MARK: - Accountability Section

    var accountabilitySection: some View {
        settingsSection(title: "Accountability") {
            VStack(spacing: MPSpacing.lg) {
                // Strict mode
                HStack {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text("Strict Mode")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)
                        Text("Prevent editing past completions")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $strictModeEnabled)
                        .tint(MPColors.primary)
                }

                Divider()

                // Streak recovery
                HStack {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text("Allow Streak Recovery")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)
                        Text("Option to recover lost streaks")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $allowStreakRecovery)
                        .tint(MPColors.primary)
                }
            }
        }
    }

    // MARK: - Goals Section

    var goalsSection: some View {
        settingsSection(title: "Goals") {
            VStack(spacing: MPSpacing.lg) {
                // Weekly perfect mornings
                HStack {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text("Weekly Goal")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)
                        Text("Perfect mornings per week")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()

                    Stepper("\(weeklyPerfectMorningsGoal)/7", value: $weeklyPerfectMorningsGoal, in: 1...7)
                        .labelsHidden()
                        .fixedSize()

                    Text("\(weeklyPerfectMorningsGoal)/7")
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.primary)
                        .frame(width: 40)
                }

                Divider()

                // Sleep goal
                HStack {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text("Sleep Goal")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)
                        Text("Target hours of sleep")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()

                    Text(String(format: "%.1fh", customSleepGoal))
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.primary)
                        .frame(width: 50)

                    Slider(value: $customSleepGoal, in: 5...10, step: 0.5)
                        .tint(MPColors.primary)
                        .frame(width: 100)
                }

                Divider()

                // Step goal
                HStack {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text("Step Goal")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)
                        Text("Morning steps target")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()

                    Stepper("", value: $customStepGoal, in: 100...5000, step: 100)
                        .labelsHidden()
                        .fixedSize()

                    Text("\(customStepGoal)")
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.primary)
                        .frame(width: 50)
                }
            }
        }
    }
}

#Preview {
    MorningProofSettingsView(manager: MorningProofManager.shared)
}

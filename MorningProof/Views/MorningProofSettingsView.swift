import SwiftUI

struct MorningProofSettingsView: View {
    @ObservedObject var manager: MorningProofManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject var themeManager: ThemeManager
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
    @State private var blockingStartMinutes: Int = 0


    // Goals settings
    @State private var weeklyPerfectMorningsGoal: Int = 5
    @State private var customSleepGoal: Double = 7.0
    @State private var customStepGoal: Int = 500

    // Test celebration
    @State private var showTestCelebration = false

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xxl) {
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

                        // Appearance Section
                        settingsSection(title: "Appearance") {
                            VStack(spacing: MPSpacing.lg) {
                                HStack {
                                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                                        Text("Theme")
                                            .font(MPFont.labelMedium())
                                            .foregroundColor(MPColors.textPrimary)
                                        Text("Choose your preferred appearance")
                                            .font(MPFont.bodySmall())
                                            .foregroundColor(MPColors.textTertiary)
                                    }

                                    Spacer()
                                }

                                HStack(spacing: MPSpacing.md) {
                                    ForEach(AppThemeMode.allCases, id: \.rawValue) { mode in
                                        Button {
                                            themeManager.themeMode = mode
                                        } label: {
                                            VStack(spacing: MPSpacing.sm) {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: MPRadius.md)
                                                        .fill(themeManager.themeMode == mode ? MPColors.primary : MPColors.surfaceSecondary)
                                                        .frame(width: 56, height: 56)

                                                    Image(systemName: mode.icon)
                                                        .font(.system(size: MPIconSize.lg))
                                                        .foregroundColor(themeManager.themeMode == mode ? .white : MPColors.textTertiary)
                                                }

                                                Text(mode.displayName)
                                                    .font(MPFont.labelSmall())
                                                    .foregroundColor(themeManager.themeMode == mode ? MPColors.primary : MPColors.textSecondary)
                                            }
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        if mode != AppThemeMode.allCases.last {
                                            Spacer()
                                        }
                                    }
                                }
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

                        // Goals Section
                        goalsSection

                        // Danger Zone
                        settingsSection(title: "Data") {
                            VStack(spacing: MPSpacing.md) {
                                // Test Celebration button
                                Button {
                                    showTestCelebration = true
                                } label: {
                                    HStack {
                                        Image(systemName: "flame.fill")
                                        Text("Test Celebration")
                                    }
                                    .font(MPFont.bodyMedium())
                                    .foregroundColor(MPColors.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, MPSpacing.md)
                                }

                                Divider()

                                // Reset Data button
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

                // Test celebration overlay
                if showTestCelebration {
                    LockInCelebrationView(
                        isShowing: $showTestCelebration,
                        buttonPosition: CGPoint(x: 200, y: 600),
                        streakFlamePosition: CGPoint(x: 60, y: 150),
                        onFlameArrived: {}
                    )
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
        blockingStartMinutes = manager.settings.blockingStartMinutes

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
        manager.settings.blockingStartMinutes = blockingStartMinutes

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
                        .onChange(of: notificationsEnabled) { _, newValue in
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
                        Text("Lock Apps")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)
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

                    // Configure button - opens full settings
                    Button {
                        showAppLockingSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(MPColors.primary)

                            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                                Text("Configure App Locking")
                                    .font(MPFont.bodyMedium())
                                    .foregroundColor(MPColors.textPrimary)

                                if blockingStartMinutes > 0 {
                                    Text("Starts at \(formatTime(blockingStartMinutes))")
                                        .font(MPFont.bodySmall())
                                        .foregroundColor(MPColors.textTertiary)
                                } else {
                                    Text("Tap to set up")
                                        .font(MPFont.bodySmall())
                                        .foregroundColor(MPColors.warning)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAppLockingSheet) {
            AppLockingSettingsView()
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

    // MARK: - Helpers

    private func formatTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}

#Preview {
    MorningProofSettingsView(manager: MorningProofManager.shared)
        .environmentObject(ThemeManager.shared)
}

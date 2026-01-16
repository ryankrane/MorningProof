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

    // Inline name editing
    @State private var isEditingName = false
    @FocusState private var nameFieldFocused: Bool

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

    // Time picker sheets
    @State private var showCutoffTimePicker = false
    @State private var showReminderTimePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        // MARK: - Header with Greeting & Theme
                        headerSection

                        // MARK: - Morning Routine (Schedule + Habits combined)
                        morningRoutineSection

                        // MARK: - Notifications
                        notificationsSection

                        // MARK: - App Locking
                        appLockingSection

                        // MARK: - Goals
                        goalsSection

                        // MARK: - About
                        aboutSection
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.lg)
                    .padding(.bottom, 40)
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

    // MARK: - Header Section

    var headerSection: some View {
        VStack(spacing: MPSpacing.lg) {
            // Greeting with inline name editing
            HStack {
                if isEditingName {
                    HStack(spacing: MPSpacing.sm) {
                        Text(greetingPrefix)
                            .font(MPFont.headingMedium())
                            .foregroundColor(MPColors.textPrimary)

                        TextField("Your name", text: $userName)
                            .font(MPFont.headingMedium())
                            .foregroundColor(MPColors.primary)
                            .focused($nameFieldFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                isEditingName = false
                            }
                    }

                    Spacer()

                    Button {
                        isEditingName = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: MPIconSize.lg))
                            .foregroundColor(MPColors.primary)
                    }
                } else {
                    Button {
                        isEditingName = true
                        nameFieldFocused = true
                    } label: {
                        HStack(spacing: MPSpacing.sm) {
                            Text(greeting)
                                .font(MPFont.headingMedium())
                                .foregroundColor(MPColors.textPrimary)

                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: MPIconSize.md))
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }
            }
            .padding(.horizontal, MPSpacing.xs)

            // Compact theme picker
            themePickerSegmented
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }

    var greetingPrefix: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning,"
        } else if hour < 17 {
            return "Good afternoon,"
        } else {
            return "Good evening,"
        }
    }

    var greeting: String {
        let name = userName.isEmpty ? "there" : userName
        return "\(greetingPrefix) \(name)"
    }

    var themePickerSegmented: some View {
        HStack(spacing: 0) {
            ForEach(AppThemeMode.allCases, id: \.rawValue) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        themeManager.themeMode = mode
                    }
                } label: {
                    HStack(spacing: MPSpacing.sm) {
                        Image(systemName: mode.icon)
                            .font(.system(size: MPIconSize.sm))
                        Text(mode.displayName)
                            .font(MPFont.labelSmall())
                    }
                    .foregroundColor(themeManager.themeMode == mode ? .white : MPColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MPSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: MPRadius.sm)
                            .fill(themeManager.themeMode == mode ? MPColors.primary : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(MPSpacing.xs)
        .background(MPColors.surfaceSecondary)
        .cornerRadius(MPRadius.md)
    }

    // MARK: - Morning Routine Section (Combined Schedule + Habits)

    var morningRoutineSection: some View {
        settingsSection(title: "Morning Routine", icon: "sunrise.fill") {
            VStack(spacing: 0) {
                // Cutoff time
                Button {
                    showCutoffTimePicker = true
                } label: {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: MPIconSize.sm))
                            .foregroundColor(MPColors.primary)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cutoff Time")
                                .font(MPFont.bodyMedium())
                                .foregroundColor(MPColors.textPrimary)
                            Text("Complete habits by this time")
                                .font(MPFont.labelTiny())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        Spacer()

                        Text(TimeOptions.formatTime(cutoffMinutes))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(MPColors.primary)
                            .padding(.horizontal, MPSpacing.md)
                            .padding(.vertical, MPSpacing.sm)
                            .background(MPColors.primaryLight)
                            .cornerRadius(MPRadius.md)
                    }
                }
                .padding(.vertical, MPSpacing.sm)
                .sheet(isPresented: $showCutoffTimePicker) {
                    TimeWheelPicker(
                        selectedMinutes: $cutoffMinutes,
                        title: "Morning Cutoff Time",
                        subtitle: "Complete your habits by this time to lock in your day",
                        timeOptions: TimeOptions.cutoffTime
                    )
                    .presentationDetents([.medium])
                }

                Divider()
                    .padding(.leading, 46)

                // Habits
                ForEach(manager.habitConfigs) { config in
                    habitToggleRow(config: config)

                    if config.id != manager.habitConfigs.last?.id {
                        Divider()
                            .padding(.leading, 46)
                    }
                }
            }
        }
    }

    func settingsSection<Content: View>(title: String, icon: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            HStack(spacing: MPSpacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MPColors.textTertiary)
                }
                Text(title.uppercased())
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textTertiary)
                    .tracking(0.5)
            }
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
                .foregroundColor(config.isEnabled ? MPColors.primary : MPColors.textTertiary)
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
        settingsSection(title: "Notifications", icon: "bell.fill") {
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
                    Button {
                        showReminderTimePicker = true
                    } label: {
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

                            Text(TimeOptions.formatTime(morningReminderTime))
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundColor(MPColors.primary)
                                .padding(.horizontal, MPSpacing.md)
                                .padding(.vertical, MPSpacing.sm)
                                .background(MPColors.primaryLight)
                                .cornerRadius(MPRadius.md)
                        }
                    }
                    .sheet(isPresented: $showReminderTimePicker) {
                        TimeWheelPicker(
                            selectedMinutes: $morningReminderTime,
                            title: "Morning Reminder",
                            subtitle: "When should we remind you to start your morning routine?",
                            timeOptions: TimeOptions.reminderTime
                        )
                        .presentationDetents([.medium])
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
        settingsSection(title: "App Locking", icon: "lock.fill") {
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
        settingsSection(title: "Goals", icon: "target") {
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

    // MARK: - About Section

    var aboutSection: some View {
        settingsSection(title: "About", icon: "info.circle.fill") {
            VStack(spacing: 0) {
                // App info row
                HStack {
                    Image(systemName: "app.fill")
                        .font(.system(size: MPIconSize.sm))
                        .foregroundColor(MPColors.primary)
                        .frame(width: 30)

                    Text("Morning Proof")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textPrimary)

                    Spacer()

                    Text("Version 1.0")
                        .font(MPFont.labelSmall())
                        .foregroundColor(MPColors.textTertiary)
                }
                .padding(.vertical, MPSpacing.sm)

                Divider()
                    .padding(.leading, 46)

                // Privacy Policy link
                Link(destination: URL(string: "https://ryankrane.github.io/morningproof-legal/privacy.html")!) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: MPIconSize.sm))
                            .foregroundColor(MPColors.primary)
                            .frame(width: 30)

                        Text("Privacy Policy")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(MPColors.textTertiary)
                    }
                    .padding(.vertical, MPSpacing.sm)
                }

                Divider()
                    .padding(.leading, 46)

                // Terms of Service link
                Link(destination: URL(string: "https://ryankrane.github.io/morningproof-legal/terms.html")!) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: MPIconSize.sm))
                            .foregroundColor(MPColors.primary)
                            .frame(width: 30)

                        Text("Terms of Service")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(MPColors.textTertiary)
                    }
                    .padding(.vertical, MPSpacing.sm)
                }

                Divider()
                    .padding(.leading, 46)

                // Test Celebration button
                Button {
                    showTestCelebration = true
                } label: {
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.system(size: MPIconSize.sm))
                            .foregroundColor(MPColors.accent)
                            .frame(width: 30)

                        Text("Test Celebration")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(MPColors.textTertiary)
                    }
                    .padding(.vertical, MPSpacing.sm)
                }
                .buttonStyle(PlainButtonStyle())

                Divider()
                    .padding(.leading, 46)

                // Reset Data button
                Button {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: MPIconSize.sm))
                            .foregroundColor(MPColors.error)
                            .frame(width: 30)

                        Text("Reset All Data")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.error)

                        Spacer()
                    }
                    .padding(.vertical, MPSpacing.sm)
                }
                .buttonStyle(PlainButtonStyle())
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

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

    // App Locking settings
    @State private var appLockingEnabled = false
    @State private var blockingStartMinutes: Int = 0

    // Goals settings
    @State private var customSleepGoal: Double = 7.0
    @State private var customStepGoal: Int = 500

    // Test celebration
    @State private var showTestCelebration = false

    // Picker sheets
    @State private var showCutoffTimePicker = false
    @State private var showReminderTimePicker = false
    @State private var showSleepGoalPicker = false
    @State private var showStepGoalPicker = false
    @State private var showMorningRoutineSheet = false

    // Info alert
    @State private var showingInfoAlert = false
    @State private var infoAlertTitle = ""
    @State private var infoAlertMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        // MARK: - Header with Greeting & Theme
                        headerSection

                        // MARK: - Morning Routine (clickable summary)
                        morningRoutineSection

                        // MARK: - App Locking (TEMPORARILY DISABLED - waiting for Family Controls approval)
                        // appLockingSection

                        // MARK: - Notifications
                        notificationsSection

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
            .alert(infoAlertTitle, isPresented: $showingInfoAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(infoAlertMessage)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(subscriptionManager: subscriptionManager)
            }
            .sheet(isPresented: $showMorningRoutineSheet) {
                MorningRoutineSettingsSheet(manager: manager)
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

    // MARK: - Morning Routine Section (Clickable Summary)

    private var enabledHabitCount: Int {
        manager.habitConfigs.filter { $0.isEnabled }.count
    }

    var morningRoutineSection: some View {
        settingsSection(title: "Morning Routine", icon: "sunrise.fill", infoText: "Configure your daily habits, goals, and completion deadline") {
            Button {
                showMorningRoutineSheet = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text("Complete by \(TimeOptions.formatTime(cutoffMinutes))")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textPrimary)

                        Text("\(enabledHabitCount) habits enabled")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
            }
        }
    }

    func settingsSection<Content: View>(title: String, icon: String? = nil, infoText: String? = nil, @ViewBuilder content: () -> Content) -> some View {
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

                if let infoText = infoText {
                    Button {
                        infoAlertTitle = title
                        infoAlertMessage = infoText
                        showingInfoAlert = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(MPColors.textTertiary)
                    }
                }
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

        // App Locking
        appLockingEnabled = manager.settings.appLockingEnabled
        blockingStartMinutes = manager.settings.blockingStartMinutes

        // Goals
        customSleepGoal = manager.settings.customSleepGoal
        customStepGoal = manager.settings.customStepGoal
    }

    func saveSettings() {
        manager.settings.userName = userName
        manager.settings.morningCutoffMinutes = cutoffMinutes

        // Notifications
        manager.settings.notificationsEnabled = notificationsEnabled
        manager.settings.morningReminderTime = morningReminderTime
        // Always enable 15-minute countdown warning when notifications are on
        manager.settings.countdownWarnings = notificationsEnabled ? [15] : []

        // App Locking
        manager.settings.appLockingEnabled = appLockingEnabled
        manager.settings.blockingStartMinutes = blockingStartMinutes

        // Goals
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
        settingsSection(title: "Notifications", icon: "bell.fill", infoText: "Get reminded to complete your habits each morning") {
            VStack(spacing: MPSpacing.lg) {
                // Enable toggle
                HStack {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text("Enable Notifications")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)
                        Text("Get daily reminders and deadline alerts")
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
                                Text("Daily reminder to start your habits")
                                    .font(MPFont.bodySmall())
                                    .foregroundColor(MPColors.textTertiary)
                            }

                            Spacer()

                            Text(TimeOptions.formatTime(morningReminderTime))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, MPSpacing.md)
                                .padding(.vertical, MPSpacing.sm)
                                .background(MPColors.primary)
                                .cornerRadius(MPRadius.md)
                        }
                    }
                    .sheet(isPresented: $showReminderTimePicker) {
                        TimeWheelPicker(
                            selectedMinutes: $morningReminderTime,
                            title: "Morning Reminder",
                            subtitle: "When should we remind you to start your habits?",
                            timeOptions: TimeOptions.reminderTime
                        )
                        .presentationDetents([.medium])
                    }
                }
            }
        }
    }

    // MARK: - App Locking Section

    var appLockingSection: some View {
        settingsSection(title: "App Locking", icon: "lock.fill", infoText: "Block distracting apps until you complete your morning routine") {
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

    // MARK: - About Section

    var aboutSection: some View {
        settingsSection(title: "About", icon: "info.circle.fill") {
            VStack(spacing: 0) {
                // App info row
                aboutRow(
                    icon: "hammer.fill",
                    iconColor: MPColors.primary,
                    title: "Morning Proof",
                    trailing: AnyView(
                        Text("Version 1.0")
                            .font(MPFont.labelSmall())
                            .foregroundColor(MPColors.textTertiary)
                    )
                )

                Divider()
                    .padding(.leading, 46)

                // Privacy Policy link
                Link(destination: URL(string: "https://ryankrane.github.io/morningproof-legal/privacy.html")!) {
                    aboutRow(
                        icon: "hand.raised.fill",
                        iconColor: MPColors.primary,
                        title: "Privacy Policy",
                        trailing: AnyView(
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(MPColors.textTertiary)
                        )
                    )
                }

                Divider()
                    .padding(.leading, 46)

                // Terms of Service link
                Link(destination: URL(string: "https://ryankrane.github.io/morningproof-legal/terms.html")!) {
                    aboutRow(
                        icon: "doc.text.fill",
                        iconColor: MPColors.primary,
                        title: "Terms of Service",
                        trailing: AnyView(
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(MPColors.textTertiary)
                        )
                    )
                }

                Divider()
                    .padding(.leading, 46)

                // Test Celebration button
                Button {
                    showTestCelebration = true
                } label: {
                    aboutRow(
                        icon: "flame.fill",
                        iconColor: MPColors.accent,
                        title: "Test Celebration",
                        trailing: AnyView(
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(MPColors.textTertiary)
                        )
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Divider()
                    .padding(.leading, 46)

                // Reset Data button
                Button {
                    showResetConfirmation = true
                } label: {
                    aboutRow(
                        icon: "arrow.counterclockwise",
                        iconColor: MPColors.error,
                        title: "Reset All Data",
                        titleColor: MPColors.error,
                        trailing: AnyView(EmptyView())
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, -MPSpacing.xs)
        }
    }

    private func aboutRow(icon: String, iconColor: Color, title: String, titleColor: Color? = nil, trailing: AnyView) -> some View {
        HStack(spacing: MPSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 30, alignment: .center)

            Text(title)
                .font(MPFont.bodyMedium())
                .foregroundColor(titleColor ?? MPColors.textPrimary)

            Spacer()

            trailing
        }
        .padding(.vertical, MPSpacing.sm)
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

import SwiftUI
import MessageUI

struct MorningProofSettingsView: View {
    @ObservedObject var manager: MorningProofManager
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var userName: String = ""
    @State private var showResetConfirmation = false
    @State private var showResetTodayConfirmation = false

    // Inline name editing
    @State private var isEditingName = false
    @FocusState private var nameFieldFocused: Bool

    // Notification settings
    @State private var notificationsEnabled = true
    @State private var morningReminderTime: Int = 420

    // Goals settings
    @State private var customSleepGoal: Double = 7.0
    @State private var customStepGoal: Int = 500

    // Support features
    @State private var showMailComposer = false
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MPSpacing.xxl) {
                    // Profile Section
                    profileSection

                    // All Settings - Single Card
                    VStack(spacing: 0) {
                        NavigationLink {
                            ManageSubscriptionView()
                        } label: {
                            SettingsRowContent(
                                icon: "creditcard.fill",
                                iconColor: MPColors.primary,
                                title: "Manage Subscription",
                                trailing: .value(subscriptionManager.isPremium ? "Premium" : "Free")
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 60)

                        NavigationLink {
                            NotificationSettingsView(
                                notificationsEnabled: $notificationsEnabled,
                                morningReminderTime: $morningReminderTime
                            )
                        } label: {
                            SettingsRowContent(
                                icon: "bell.fill",
                                iconColor: .red,
                                title: "Notifications",
                                trailing: .value(notificationsEnabled ? "On" : "Off")
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 60)

                        NavigationLink {
                            AppearanceSettingsView()
                                .environmentObject(themeManager)
                        } label: {
                            SettingsRowContent(
                                icon: "paintbrush.fill",
                                iconColor: .orange,
                                title: "Appearance",
                                trailing: .value(themeManager.themeMode.displayName)
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 60)

                        NavigationLink {
                            HealthDataSettingsView()
                        } label: {
                            SettingsRowContent(
                                icon: "heart.fill",
                                iconColor: MPColors.healthRed,
                                title: "Health Data",
                                trailing: .chevron
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 60)

                        SettingsRow(
                            icon: "envelope.fill",
                            iconColor: MPColors.primary,
                            title: "Send Feedback",
                            trailing: .chevron
                        ) {
                            if MFMailComposeViewController.canSendMail() {
                                showMailComposer = true
                            } else {
                                if let url = URL(string: "mailto:support@morningproofapp.com?subject=Morning%20Proof%20Feedback") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }

                        Divider().padding(.leading, 60)

                        SettingsRow(
                            icon: "star.fill",
                            iconColor: .yellow,
                            title: "Leave a Review",
                            trailing: .external
                        ) {
                            if let url = URL(string: "https://apps.apple.com/app/id6757691737?action=write-review") {
                                UIApplication.shared.open(url)
                            }
                        }

                        Divider().padding(.leading, 60)

                        SettingsRow(
                            icon: "square.and.arrow.up.fill",
                            iconColor: MPColors.primary,
                            title: "Share with Friends",
                            trailing: .chevron
                        ) {
                            showShareSheet = true
                        }

                        Divider().padding(.leading, 60)

                        SettingsRow(
                            icon: "hand.raised.fill",
                            iconColor: .gray,
                            title: "Privacy Policy",
                            trailing: .external
                        ) {
                            if let url = URL(string: "https://ryankrane.github.io/morningproof-legal/privacy.html") {
                                UIApplication.shared.open(url)
                            }
                        }

                        Divider().padding(.leading, 60)

                        SettingsRow(
                            icon: "doc.text.fill",
                            iconColor: .gray,
                            title: "Terms of Service",
                            trailing: .external
                        ) {
                            if let url = URL(string: "https://ryankrane.github.io/morningproof-legal/terms.html") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)

                    // Danger Zone - Separate Card
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "arrow.counterclockwise",
                            iconColor: MPColors.warning,
                            title: "Clear Today's Progress",
                            titleColor: MPColors.warning,
                            trailing: .none
                        ) {
                            showResetTodayConfirmation = true
                        }

                        Divider().padding(.leading, 60)

                        SettingsRow(
                            icon: "trash.fill",
                            iconColor: MPColors.error,
                            title: "Delete Account & Data",
                            titleColor: MPColors.error,
                            trailing: .none
                        ) {
                            showResetConfirmation = true
                        }
                    }
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)

                    // Version Footer
                    Text("Version \(appVersion)")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textMuted)
                        .padding(.top, MPSpacing.md)
                        .padding(.bottom, MPSpacing.xxxl)
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.top, MPSpacing.md)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadSettings()
        }
        .onDisappear {
            saveSettings()
        }
        .alert("Clear Today's Progress?", isPresented: $showResetTodayConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                manager.resetTodaysProgress()
            }
        } message: {
            Text("This will clear all habit completions for today. Your settings and streak history will be preserved.")
        }
        .alert("Delete Account & Data?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                manager.resetAllData()
                AuthenticationManager.shared.signOut()
                dismiss()
            }
        } message: {
            Text("This will permanently delete your account and all data including habits, streaks, and settings. This cannot be undone.")
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                subject: "Morning Proof Feedback",
                body: feedbackEmailBody,
                recipient: "support@morningproofapp.com"
            )
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [
                "Check out Morning Proof - build better morning habits with photo verification!",
                URL(string: "https://apps.apple.com/app/id6757691737")!
            ])
        }
    }

    // MARK: - Profile Section

    var profileSection: some View {
        VStack(spacing: 0) {
            // Profile row with avatar and name
            HStack(spacing: MPSpacing.lg) {
                // Avatar circle
                ZStack {
                    Circle()
                        .fill(MPColors.primary.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Text(userInitials)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(MPColors.primary)
                }

                if isEditingName {
                    TextField("Your name", text: $userName)
                        .font(MPFont.labelLarge())
                        .foregroundColor(MPColors.textPrimary)
                        .focused($nameFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            isEditingName = false
                        }

                    Spacer()

                    Button {
                        isEditingName = false
                    } label: {
                        Text("Done")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.primary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text(userName.isEmpty ? "Add your name" : userName)
                            .font(MPFont.labelLarge())
                            .foregroundColor(userName.isEmpty ? MPColors.textTertiary : MPColors.textPrimary)

                        if subscriptionManager.isPremium {
                            HStack(spacing: MPSpacing.xs) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10))
                                Text("Premium")
                                    .font(MPFont.labelTiny())
                            }
                            .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.25))
                        }
                    }

                    Spacer()

                    Button {
                        isEditingName = true
                        nameFieldFocused = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MPColors.textTertiary)
                            .frame(width: 32, height: 32)
                            .background(MPColors.surfaceSecondary)
                            .cornerRadius(MPRadius.sm)
                    }
                }
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
        }
    }

    var userInitials: String {
        let name = userName.isEmpty ? "?" : userName
        return String(name.prefix(1)).uppercased()
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var feedbackEmailBody: String {
        let device = UIDevice.current
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return """


        ---
        Device: \(device.model)
        iOS: \(device.systemVersion)
        App: \(version) (\(build))
        """
    }

    // MARK: - Settings Management

    func loadSettings() {
        userName = manager.settings.userName

        // Notifications
        notificationsEnabled = manager.settings.notificationsEnabled
        morningReminderTime = manager.settings.morningReminderTime

        // Goals
        customSleepGoal = manager.settings.customSleepGoal
        customStepGoal = manager.settings.customStepGoal
    }

    func saveSettings() {
        manager.settings.userName = userName

        // Notifications
        manager.settings.notificationsEnabled = notificationsEnabled
        manager.settings.morningReminderTime = morningReminderTime
        manager.settings.countdownWarnings = notificationsEnabled ? [15] : []

        // Goals
        manager.settings.customSleepGoal = customSleepGoal
        manager.settings.customStepGoal = customStepGoal

        manager.saveCurrentState()

        // Update notification schedule
        Task {
            await notificationManager.updateNotificationSchedule(settings: manager.settings)
        }
    }
}

// MARK: - Settings Section Component

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MPColors.textTertiary)
                .padding(.leading, MPSpacing.sm)

            VStack(spacing: 0) {
                content
            }
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
        }
    }
}

// MARK: - Settings Row Component

enum SettingsTrailing {
    case chevron
    case external
    case value(String)
    case toggle(Binding<Bool>)
    case loading
    case none
}

struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var titleColor: Color? = nil
    let trailing: SettingsTrailing
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsRowContent(
                icon: icon,
                iconColor: iconColor,
                title: title,
                titleColor: titleColor,
                trailing: trailing
            )
        }
        .buttonStyle(.plain)
    }
}

struct SettingsRowContent: View {
    let icon: String
    let iconColor: Color
    let title: String
    var titleColor: Color? = nil
    let trailing: SettingsTrailing

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)

            Text(title)
                .font(MPFont.bodyMedium())
                .foregroundColor(titleColor ?? MPColors.textPrimary)

            Spacer()

            trailingView
        }
        .padding(.horizontal, MPSpacing.lg)
        .padding(.vertical, MPSpacing.md + 2)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    var trailingView: some View {
        switch trailing {
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(MPColors.textMuted)

        case .external:
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MPColors.textMuted)

        case .value(let text):
            HStack(spacing: MPSpacing.sm) {
                Text(text)
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textTertiary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(MPColors.textMuted)
            }

        case .toggle(let binding):
            Toggle("", isOn: binding)
                .tint(MPColors.primary)
                .labelsHidden()

        case .loading:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: MPColors.textTertiary))
                .scaleEffect(0.8)

        case .none:
            EmptyView()
        }
    }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @Binding var notificationsEnabled: Bool
    @Binding var morningReminderTime: Int
    @ObservedObject private var notificationManager = NotificationManager.shared

    @State private var showTimePicker = false
    @State private var showPermissionDeniedAlert = false

    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MPSpacing.xxl) {
                    SettingsSection(title: "Reminders") {
                        // Enable toggle
                        HStack(spacing: MPSpacing.lg) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                                .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable Notifications")
                                    .font(MPFont.bodyMedium())
                                    .foregroundColor(MPColors.textPrimary)

                                Text("Daily reminders and deadline alerts")
                                    .font(MPFont.bodySmall())
                                    .foregroundColor(MPColors.textTertiary)
                            }

                            Spacer()

                            Toggle("", isOn: $notificationsEnabled)
                                .tint(MPColors.primary)
                                .labelsHidden()
                                .onChange(of: notificationsEnabled) { _, newValue in
                                    if newValue {
                                        Task {
                                            let granted = await notificationManager.requestPermission()
                                            if !granted {
                                                await notificationManager.checkAuthorizationStatus()
                                                await MainActor.run {
                                                    notificationsEnabled = false
                                                    showPermissionDeniedAlert = true
                                                }
                                            }
                                        }
                                    }
                                }
                        }
                        .padding(.horizontal, MPSpacing.lg)
                        .padding(.vertical, MPSpacing.md + 2)

                        if notificationsEnabled {
                            Divider()
                                .padding(.leading, 60)

                            // Reminder time
                            Button {
                                showTimePicker = true
                            } label: {
                                HStack(spacing: MPSpacing.lg) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.blue)
                                        .frame(width: 28, height: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Morning Reminder")
                                            .font(MPFont.bodyMedium())
                                            .foregroundColor(MPColors.textPrimary)

                                        Text("When to remind you each day")
                                            .font(MPFont.bodySmall())
                                            .foregroundColor(MPColors.textTertiary)
                                    }

                                    Spacer()

                                    Text(TimeOptions.formatTime(morningReminderTime))
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(MPColors.primary)
                                }
                                .padding(.horizontal, MPSpacing.lg)
                                .padding(.vertical, MPSpacing.md + 2)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Info card
                    HStack(spacing: MPSpacing.md) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(MPColors.primary)

                        Text("You'll also receive a reminder 15 minutes before your daily deadline.")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textSecondary)
                    }
                    .padding(MPSpacing.lg)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.top, MPSpacing.lg)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTimePicker) {
            TimeWheelPicker(
                selectedMinutes: $morningReminderTime,
                title: "Morning Reminder",
                subtitle: "When should we remind you to start your habits?",
                timeOptions: TimeOptions.reminderTime
            )
            .presentationDetents([.medium])
        }
        .alert("Notifications Disabled", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive reminders, please enable notifications for Morning Proof in your device's Settings.")
        }
    }
}

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MPSpacing.xxl) {
                    SettingsSection(title: "Theme") {
                        ForEach(AppThemeMode.allCases, id: \.rawValue) { mode in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    themeManager.themeMode = mode
                                }
                            } label: {
                                HStack(spacing: MPSpacing.lg) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(themeIconColor(for: mode))
                                        .frame(width: 28, height: 28)

                                    Text(mode.displayName)
                                        .font(MPFont.bodyMedium())
                                        .foregroundColor(MPColors.textPrimary)

                                    Spacer()

                                    if themeManager.themeMode == mode {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(MPColors.primary)
                                    }
                                }
                                .padding(.horizontal, MPSpacing.lg)
                                .padding(.vertical, MPSpacing.md + 2)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if mode != AppThemeMode.allCases.last {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.top, MPSpacing.lg)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    func themeIconColor(for mode: AppThemeMode) -> Color {
        switch mode {
        case .system: return .purple
        case .light: return .orange
        case .dark: return .indigo
        }
    }
}

// MARK: - Health Data Settings View

struct HealthDataSettingsView: View {
    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MPSpacing.xxl) {
                    // Info card
                    HStack(alignment: .top, spacing: MPSpacing.md) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: MPSpacing.xs) {
                            Text("Health Integration")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.textPrimary)

                            Text("Morning Proof reads your health data to automatically track habits. We never write or modify your data.")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.textSecondary)
                        }
                    }
                    .padding(MPSpacing.lg)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)

                    SettingsSection(title: "Data We Read") {
                        healthDataRow(
                            icon: "moon.zzz.fill",
                            iconColor: .purple,
                            title: "Sleep Analysis",
                            description: "Last night's sleep duration"
                        )

                        Divider().padding(.leading, 60)

                        healthDataRow(
                            icon: "figure.walk",
                            iconColor: .green,
                            title: "Step Count",
                            description: "Morning steps before deadline"
                        )

                        Divider().padding(.leading, 60)

                        healthDataRow(
                            icon: "flame.fill",
                            iconColor: .orange,
                            title: "Workouts",
                            description: "Morning workout detection"
                        )

                        Divider().padding(.leading, 60)

                        healthDataRow(
                            icon: "bolt.fill",
                            iconColor: .yellow,
                            title: "Active Energy",
                            description: "Calories during workouts"
                        )
                    }

                    // Manage button
                    Button {
                        if let url = URL(string: "x-apple-health://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.pink)

                            Text("Manage in Health App")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.primary)

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(MPColors.textTertiary)
                        }
                        .padding(MPSpacing.lg)
                        .background(MPColors.surface)
                        .cornerRadius(MPRadius.lg)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.top, MPSpacing.lg)
            }
        }
        .navigationTitle("Health Data")
        .navigationBarTitleDisplayMode(.inline)
    }

    func healthDataRow(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(spacing: MPSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()
        }
        .padding(.horizontal, MPSpacing.lg)
        .padding(.vertical, MPSpacing.md)
    }
}

// MARK: - Manage Subscription View

struct ManageSubscriptionView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isRestoringPurchases = false
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: MPSpacing.xl) {
                    // Current Plan Card
                    VStack(spacing: MPSpacing.lg) {
                        HStack {
                            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                                Text("Current Plan")
                                    .font(MPFont.bodySmall())
                                    .foregroundColor(MPColors.textTertiary)

                                Text(subscriptionManager.isPremium ? "Premium" : "Free")
                                    .font(MPFont.headingMedium())
                                    .foregroundColor(MPColors.textPrimary)
                            }

                            Spacer()

                            // Status badge
                            Text(subscriptionManager.isPremium ? "Active" : "Basic")
                                .font(MPFont.labelSmall())
                                .foregroundColor(.white)
                                .padding(.horizontal, MPSpacing.md)
                                .padding(.vertical, MPSpacing.sm)
                                .background(subscriptionManager.isPremium ? MPColors.success : MPColors.textTertiary)
                                .cornerRadius(MPRadius.md)
                        }

                        if !subscriptionManager.isPremium {
                            // Upgrade button for free users
                            Button {
                                showPaywall = true
                            } label: {
                                Text("Upgrade to Premium")
                                    .font(MPFont.labelMedium())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, MPSpacing.md)
                                    .background(MPColors.primary)
                                    .cornerRadius(MPRadius.md)
                            }
                        }
                    }
                    .padding(MPSpacing.lg)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)

                    // Actions
                    VStack(spacing: 0) {
                        if subscriptionManager.isPremium {
                            // Manage in Settings (opens iOS subscription settings)
                            Button {
                                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Text("Manage in Settings")
                                        .font(MPFont.bodyMedium())
                                        .foregroundColor(MPColors.textPrimary)

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(MPColors.textTertiary)
                                }
                                .padding(.horizontal, MPSpacing.lg)
                                .padding(.vertical, MPSpacing.lg)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, MPSpacing.lg)
                        }

                        // Restore Purchases
                        Button {
                            Task {
                                isRestoringPurchases = true
                                await subscriptionManager.restorePurchases()
                                isRestoringPurchases = false
                                if subscriptionManager.isPremium {
                                    restoreAlertMessage = "Your premium subscription has been restored."
                                } else {
                                    restoreAlertMessage = "No previous purchases found."
                                }
                                showRestoreAlert = true
                            }
                        } label: {
                            HStack {
                                Text("Restore Purchases")
                                    .font(MPFont.bodyMedium())
                                    .foregroundColor(MPColors.primary)

                                Spacer()

                                if isRestoringPurchases {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: MPColors.textTertiary))
                                        .scaleEffect(0.8)
                                }
                            }
                            .padding(.horizontal, MPSpacing.lg)
                            .padding(.vertical, MPSpacing.lg)
                        }
                        .buttonStyle(.plain)
                        .disabled(isRestoringPurchases)
                    }
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)

                    // Legal text
                    VStack(alignment: .leading, spacing: MPSpacing.sm) {
                        Text("Your subscription will automatically renew unless cancelled at least 24 hours before the end of the current period.")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)

                        Text("Subscriptions are managed through your Apple ID. You can change or cancel your subscription at any time in your device's Settings.")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }
                    .padding(MPSpacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(MPColors.surface.opacity(0.5))
                    .cornerRadius(MPRadius.lg)
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.top, MPSpacing.lg)
            }
        }
        .navigationTitle("Manage Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreAlertMessage)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(subscriptionManager: subscriptionManager)
        }
    }
}

#Preview {
    NavigationStack {
        MorningProofSettingsView(manager: MorningProofManager.shared)
            .environmentObject(ThemeManager.shared)
    }
}

// MARK: - Mail Compose View

struct MailComposeView: UIViewControllerRepresentable {
    let subject: String
    let body: String
    let recipient: String
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([recipient])
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView

        init(_ parent: MailComposeView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

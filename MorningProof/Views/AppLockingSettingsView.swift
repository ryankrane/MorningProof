import SwiftUI
import FamilyControls

struct AppLockingSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var screenTimeManager = ScreenTimeManager.shared
    @ObservedObject private var manager = MorningProofManager.shared

    @State private var isPickerPresented = false
    @State private var showAuthorizationError = false
    @State private var isRequestingAuth = false
    @State private var blockingStartMinutes: Int = 0  // 0 = not configured

    private var isAuthorized: Bool {
        screenTimeManager.authorizationStatus == .approved
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        // Debug: Show auth state at top
                        Text("Auth Check: \(isAuthorized ? "AUTHORIZED" : "NOT AUTHORIZED")")
                            .font(.caption)
                            .foregroundColor(isAuthorized ? .green : .red)
                            .padding(4)
                            .background(isAuthorized ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .cornerRadius(4)

                        // Header explanation
                        headerSection

                        // Authorization status
                        if !isAuthorized {
                            authorizationSection
                        } else {
                            // App selection (only if authorized)
                            appSelectionSection

                            // Blocking start time
                            blockingStartTimeSection

                            // Enable toggle
                            enableSection

                            // How it works
                            howItWorksSection

                            // Debug section (temporary)
                            debugSection
                        }
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.top, MPSpacing.lg)
                    .padding(.bottom, MPSpacing.xxxl)
                }
            }
            .navigationTitle("App Locking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(MPColors.primary)
                }
            }
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: $screenTimeManager.selectedApps
            )
            .onChange(of: screenTimeManager.selectedApps) { _, newValue in
                screenTimeManager.saveSelectedApps(newValue)
            }
            .alert("Authorization Failed", isPresented: $showAuthorizationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Screen Time access is required to block apps. Please enable it in Settings > Screen Time.")
            }
            .onAppear {
                blockingStartMinutes = manager.settings.blockingStartMinutes
            }
        }
    }

    // MARK: - Header Section

    var headerSection: some View {
        VStack(spacing: MPSpacing.md) {
            ZStack {
                Circle()
                    .fill(MPColors.surfaceSecondary)
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(MPColors.primary)
            }

            Text("Focus Until Complete")
                .font(MPFont.headingSmall())
                .foregroundColor(MPColors.textPrimary)

            Text("Block distracting apps until you complete your morning routine")
                .font(MPFont.bodyMedium())
                .foregroundColor(MPColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, MPSpacing.lg)
    }

    // MARK: - Authorization Section

    var authorizationSection: some View {
        VStack(spacing: MPSpacing.lg) {
            // Status banner
            HStack(spacing: MPSpacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(MPColors.warning)

                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text("Screen Time Access Required")
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)

                    Text("To block apps, Morning Proof needs permission to access Screen Time.")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }
            }
            .padding(MPSpacing.lg)
            .background(MPColors.warningLight)
            .cornerRadius(MPRadius.lg)

            // Authorize button
            Button {
                requestAuthorization()
            } label: {
                HStack {
                    if isRequestingAuth {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "hand.raised.fill")
                        Text("Enable Screen Time Access")
                    }
                }
                .font(MPFont.labelMedium())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MPSpacing.lg)
                .background(MPColors.primary)
                .cornerRadius(MPRadius.lg)
            }
            .disabled(isRequestingAuth)
        }
    }

    // MARK: - App Selection Section

    var appSelectionSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text("APPS TO BLOCK")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textTertiary)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text("Select Apps")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)

                        let appCount = screenTimeManager.selectedApps.applicationTokens.count
                        let categoryCount = screenTimeManager.selectedApps.categoryTokens.count

                        if appCount > 0 || categoryCount > 0 {
                            Text("\(appCount) app\(appCount == 1 ? "" : "s")\(categoryCount > 0 ? ", \(categoryCount) categor\(categoryCount == 1 ? "y" : "ies")" : "") selected")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.success)
                        } else {
                            Text("Tap to choose apps to block")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundColor(MPColors.textTertiary)
                }
                .padding(MPSpacing.lg)
                .background(MPColors.surface)
                .cornerRadius(MPRadius.lg)
                .mpShadow(.small)
            }
        }
    }

    // MARK: - Blocking Start Time Section

    @State private var showTimePicker = false

    var blockingStartTimeSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text("BLOCKING SCHEDULE")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textTertiary)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            VStack(spacing: 0) {
                Button {
                    showTimePicker = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: MPSpacing.xs) {
                            Text("Block Apps Starting At")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.textPrimary)

                            Text("When should blocking begin each day?")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        Spacer()

                        if blockingStartMinutes > 0 {
                            Text(TimeOptions.formatTime(blockingStartMinutes))
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundColor(MPColors.primary)
                                .padding(.horizontal, MPSpacing.md)
                                .padding(.vertical, MPSpacing.sm)
                                .background(MPColors.primaryLight)
                                .cornerRadius(MPRadius.md)
                        } else {
                            Text("Not Set")
                                .font(.system(size: 17, weight: .medium, design: .rounded))
                                .foregroundColor(MPColors.textTertiary)
                                .padding(.horizontal, MPSpacing.md)
                                .padding(.vertical, MPSpacing.sm)
                                .background(MPColors.surfaceSecondary)
                                .cornerRadius(MPRadius.md)
                        }
                    }
                }
                .padding(MPSpacing.lg)

                if blockingStartMinutes == 0 {
                    Divider()

                    HStack(spacing: MPSpacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(MPColors.warning)

                        Text("Set a start time to enable app blocking")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.warning)
                    }
                    .padding(MPSpacing.lg)
                }
            }
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
        }
        .sheet(isPresented: $showTimePicker) {
            TimeWheelPicker(
                selectedMinutes: Binding(
                    get: { blockingStartMinutes > 0 ? blockingStartMinutes : 360 },  // Default to 6 AM if not set
                    set: { newValue in
                        blockingStartMinutes = newValue
                        manager.settings.blockingStartMinutes = newValue
                        AppLockingDataStore.blockingStartMinutes = newValue
                        manager.saveCurrentState()

                        // Restart schedule if already enabled
                        if manager.settings.appLockingEnabled && screenTimeManager.hasSelectedApps && newValue > 0 {
                            do {
                                try screenTimeManager.startMorningBlockingSchedule(
                                    startMinutes: newValue,
                                    cutoffMinutes: manager.settings.morningCutoffMinutes
                                )
                            } catch {
                                // Failed to restart schedule
                            }
                        }
                    }
                ),
                title: "Block Apps Starting At",
                subtitle: "Apps will be blocked until you complete your morning habits",
                timeOptions: TimeOptions.blockingStartTime
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Enable Section

    var enableSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text("SETTINGS")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textTertiary)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            VStack(spacing: 0) {
                // Enable toggle
                HStack {
                    VStack(alignment: .leading, spacing: MPSpacing.xs) {
                        Text("Enable App Locking")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textPrimary)

                        Text("Block selected apps until habits are done")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { manager.settings.appLockingEnabled },
                        set: { newValue in
                            manager.settings.appLockingEnabled = newValue
                            AppLockingDataStore.appLockingEnabled = newValue

                            if newValue && screenTimeManager.hasSelectedApps && blockingStartMinutes > 0 {
                                // Start monitoring
                                do {
                                    try screenTimeManager.startMorningBlockingSchedule(
                                        startMinutes: blockingStartMinutes,
                                        cutoffMinutes: manager.settings.morningCutoffMinutes
                                    )
                                } catch {
                                    // Failed to start monitoring
                                    manager.settings.appLockingEnabled = false
                                }
                            } else if !newValue {
                                // Stop monitoring
                                screenTimeManager.stopMonitoring()
                                screenTimeManager.removeShields()
                            }

                            manager.saveCurrentState()
                        }
                    ))
                    .tint(MPColors.primary)
                }
                .padding(MPSpacing.lg)

                if manager.settings.appLockingEnabled && (!screenTimeManager.hasSelectedApps || blockingStartMinutes == 0) {
                    Divider()

                    HStack(spacing: MPSpacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(MPColors.warning)

                        Text(!screenTimeManager.hasSelectedApps ? "Select apps above to enable blocking" : "Set a blocking start time above")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.warning)
                    }
                    .padding(MPSpacing.lg)
                }
            }
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
        }
    }

    // MARK: - How It Works Section

    var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text("HOW IT WORKS")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textTertiary)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            VStack(alignment: .leading, spacing: MPSpacing.lg) {
                howItWorksRow(
                    number: "1",
                    title: "Select Apps & Time",
                    description: "Choose apps to block and when blocking starts each day"
                )

                howItWorksRow(
                    number: "2",
                    title: "Apps Block Automatically",
                    description: "At your start time, selected apps are blocked"
                )

                howItWorksRow(
                    number: "3",
                    title: "Complete Your Habits",
                    description: "Apps stay locked until you finish and lock in your day"
                )

                howItWorksRow(
                    number: "4",
                    title: "Unlock on Completion",
                    description: "Lock in your day to instantly unlock all blocked apps"
                )
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
        }
    }

    func howItWorksRow(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: MPSpacing.md) {
            ZStack {
                Circle()
                    .fill(MPColors.primaryLight)
                    .frame(width: 28, height: 28)

                Text(number)
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.primary)
            }

            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text(title)
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }
        }
    }

    // MARK: - Debug Section

    var debugSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text("DEBUG INFO")
                .font(MPFont.labelSmall())
                .foregroundColor(.red)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                debugRow("Authorization", "\(screenTimeManager.authorizationStatus)")
                debugRow("Is Authorized", screenTimeManager.isAuthorized ? "YES" : "NO")
                debugRow("Selected Apps", "\(screenTimeManager.selectedApps.applicationTokens.count)")
                debugRow("Selected Categories", "\(screenTimeManager.selectedApps.categoryTokens.count)")
                debugRow("Has Selected Apps", screenTimeManager.hasSelectedApps ? "YES" : "NO")
                debugRow("Is Monitoring", screenTimeManager.isMonitoring ? "YES" : "NO")

                Divider().padding(.vertical, MPSpacing.xs)

                debugRow("App Locking Enabled (DataStore)", AppLockingDataStore.appLockingEnabled ? "YES" : "NO")
                debugRow("Blocking Start Minutes", "\(AppLockingDataStore.blockingStartMinutes)")
                debugRow("Has Locked In Today", AppLockingDataStore.hasLockedInToday ? "YES" : "NO")
                debugRow("Should Apply Shields", AppLockingDataStore.shouldApplyShields() ? "YES" : "NO")

                Divider().padding(.vertical, MPSpacing.xs)

                let now = Date()
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: now)
                let currentMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
                debugRow("Current Time (minutes)", "\(currentMinutes)")

                Button("Reset Lock State (Testing)") {
                    // Reset lock state only - doesn't touch Screen Time authorization
                    AppLockingDataStore.isDayLockedIn = false
                    AppLockingDataStore.wasEmergencyUnlock = false
                    AppLockingDataStore.lastLockInDate = nil

                    // Also reset in main manager
                    manager.todayLog.isDayLockedIn = false
                    manager.saveCurrentState()
                }
                .font(MPFont.labelSmall())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MPSpacing.sm)
                .background(Color.orange)
                .cornerRadius(MPRadius.md)
                .padding(.top, MPSpacing.sm)
            }
            .padding(MPSpacing.lg)
            .background(Color.red.opacity(0.1))
            .cornerRadius(MPRadius.lg)
        }
    }

    func debugRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(MPFont.bodySmall())
                .foregroundColor(MPColors.textSecondary)
            Spacer()
            Text(value)
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textPrimary)
        }
    }

    // MARK: - Actions

    private func requestAuthorization() {
        isRequestingAuth = true

        Task {
            do {
                try await screenTimeManager.requestAuthorization()
            } catch {
                showAuthorizationError = true
            }
            isRequestingAuth = false
        }
    }
}

#Preview {
    AppLockingSettingsView()
}

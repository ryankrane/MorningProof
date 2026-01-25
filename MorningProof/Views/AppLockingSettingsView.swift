import SwiftUI

// MARK: - App Locking Settings View (Family Controls)

#if true
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
                        // Header explanation
                        headerSection

                        // Authorization status
                        if !isAuthorized {
                            authorizationSection
                        } else {
                            // Enable toggle - prominent at top
                            enableSection

                            // Configuration (only show details if enabled)
                            if manager.settings.appLockingEnabled {
                                configurationSection
                            }

                            // How it works - always visible
                            howItWorksSection
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
                // Refresh authorization status in case user enabled it in Settings
                screenTimeManager.refreshAuthorizationStatus()
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
                    title: "Start Blocking At",
                    subtitle: "Apps will be blocked until you complete your morning habits",
                    timeOptions: TimeOptions.blockingStartTime
                )
                .presentationDetents([.medium])
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

    @State private var showTimePicker = false

    // MARK: - Enable Section (Prominent toggle at top)

    var enableSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: MPSpacing.xs) {
                    Text("Enable App Locking")
                        .font(MPFont.labelLarge())
                        .foregroundColor(MPColors.textPrimary)

                    Text("Block distracting apps until habits are done")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { manager.settings.appLockingEnabled },
                    set: { newValue in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            manager.settings.appLockingEnabled = newValue
                        }
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

            // Setup reminder when enabled but not configured
            if manager.settings.appLockingEnabled && (!screenTimeManager.hasSelectedApps || blockingStartMinutes == 0) {
                Divider()

                HStack(spacing: MPSpacing.sm) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(MPColors.primary)

                    Text("Configure apps and schedule below")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.primary)
                }
                .padding(MPSpacing.lg)
            }
        }
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .stroke(manager.settings.appLockingEnabled ? MPColors.primary.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .mpShadow(.small)
    }

    // MARK: - Configuration Section (Apps + Schedule combined)

    var configurationSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text("CONFIGURATION")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textTertiary)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            VStack(spacing: 0) {
                // App selection
                Button {
                    isPickerPresented = true
                } label: {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(MPColors.primary)
                                .frame(width: 36, height: 36)
                            Image(systemName: "apps.iphone")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apps to Block")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.textPrimary)

                            let appCount = screenTimeManager.selectedApps.applicationTokens.count
                            let categoryCount = screenTimeManager.selectedApps.categoryTokens.count

                            if appCount > 0 || categoryCount > 0 {
                                Text("\(appCount) app\(appCount == 1 ? "" : "s")\(categoryCount > 0 ? ", \(categoryCount) categor\(categoryCount == 1 ? "y" : "ies")" : "")")
                                    .font(MPFont.bodySmall())
                                    .foregroundColor(MPColors.success)
                            } else {
                                Text("Tap to select")
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
                }

                Divider()
                    .padding(.leading, 60)

                // Blocking start time
                Button {
                    showTimePicker = true
                } label: {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(MPColors.primary)
                                .frame(width: 36, height: 36)
                            Image(systemName: "clock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Start Blocking At")
                                .font(MPFont.labelMedium())
                                .foregroundColor(MPColors.textPrimary)

                            Text("When blocking begins each day")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        Spacer()

                        if blockingStartMinutes > 0 {
                            Text(TimeOptions.formatTime(blockingStartMinutes))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, MPSpacing.sm)
                                .padding(.vertical, 4)
                                .background(MPColors.primary)
                                .cornerRadius(MPRadius.sm)
                        } else {
                            Text("Set time")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.textTertiary)
                        }
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
                    description: "Choose apps to block and when blocking starts"
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
                    .fill(MPColors.primary)
                    .frame(width: 28, height: 28)

                Text(number)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
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

#else

// MARK: - Stub View (Feature Disabled)

/// Stub AppLockingSettingsView while Family Controls approval is pending.
/// This view should never be shown since the app locking section is hidden.
struct AppLockingSettingsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)

                Text("App Locking Coming Soon")
                    .font(.headline)

                Text("This feature is currently being reviewed by Apple and will be available in a future update.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("App Locking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#endif

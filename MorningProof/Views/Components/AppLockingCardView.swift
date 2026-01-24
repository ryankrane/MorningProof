import SwiftUI
import FamilyControls

struct AppLockingCardView: View {
    @ObservedObject private var manager = MorningProofManager.shared
    @ObservedObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var showSettings = false

    private var isAuthorized: Bool {
        screenTimeManager.authorizationStatus == .approved
    }

    private var isConfigured: Bool {
        manager.settings.blockingStartMinutes > 0 && screenTimeManager.hasSelectedApps
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            Text("APP LOCKING")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textTertiary)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            Button {
                showSettings = true
            } label: {
                HStack(spacing: MPSpacing.md) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundColor(MPColors.primary.opacity(0.85))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Focus Mode")
                            .font(.system(size: 17))
                            .foregroundColor(MPColors.textPrimary)

                        statusText
                    }

                    Spacer()

                    if isAuthorized && isConfigured {
                        // Quick toggle only shown when fully configured
                        Toggle("", isOn: enabledBinding)
                            .tint(MPColors.primary)
                            .labelsHidden()
                    } else {
                        // Chevron to indicate settings need to be opened
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(MPColors.textTertiary)
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, MPSpacing.lg)
                .background(MPColors.surface)
                .cornerRadius(MPRadius.lg)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showSettings) {
            AppLockingSettingsView()
        }
    }

    // MARK: - Status Text

    private var statusText: some View {
        Group {
            if !isAuthorized {
                Text("Tap to set up")
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textTertiary)
            } else if !isConfigured {
                Text("Tap to configure")
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.warning)
            } else if manager.settings.appLockingEnabled {
                Text("Starts at \(formatTime(manager.settings.blockingStartMinutes))")
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.success)
            } else {
                Text("Disabled")
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textTertiary)
            }
        }
    }

    // MARK: - Toggle Binding

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { manager.settings.appLockingEnabled },
            set: { newValue in
                manager.settings.appLockingEnabled = newValue
                AppLockingDataStore.appLockingEnabled = newValue

                if newValue && screenTimeManager.hasSelectedApps && manager.settings.blockingStartMinutes > 0 {
                    // Start monitoring
                    do {
                        try screenTimeManager.startMorningBlockingSchedule(
                            startMinutes: manager.settings.blockingStartMinutes,
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
        )
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
    ZStack {
        MPColors.background
            .ignoresSafeArea()

        VStack {
            AppLockingCardView()
                .padding(.horizontal, MPSpacing.xl)
        }
    }
}

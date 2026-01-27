import SwiftUI

// MARK: - Phase 5: Personalization (Step 12)

// MARK: - Step 12: Permissions

struct PermissionsStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    @State private var isRequestingHealth = false
    @State private var isRequestingNotifications = false
    @State private var isRequestingScreenTime = false
    @State private var screenTimeEnabled = false
    private var healthKit: HealthKitManager { HealthKitManager.shared }
    private var notificationManager: NotificationManager { NotificationManager.shared }
    @StateObject private var screenTimeManager = ScreenTimeManager.shared

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                VStack(spacing: MPSpacing.md) {
                    Text("Complete Your Setup")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("These unlock the full experience")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textSecondary)
                }
                .padding(.top, max(100, geometry.safeAreaInsets.top + 80))

                Spacer()
                    .frame(minHeight: 20)

                VStack(spacing: MPSpacing.lg) {
                    // Health permission card
                    PermissionCard(
                        icon: "heart.fill",
                        iconColor: MPColors.error,
                        title: "Apple Health",
                        description: "Skip manual check-ins - we pull your data automatically",
                        isEnabled: data.healthConnected,
                        isLoading: isRequestingHealth
                    ) {
                        requestHealthAccess()
                    }

                    // Notification permission card
                    PermissionCard(
                        icon: "bell.badge.fill",
                        iconColor: MPColors.primary,
                        title: "Notifications",
                        description: "Never forget your routine or break your streak",
                        isEnabled: data.notificationsEnabled,
                        isLoading: isRequestingNotifications
                    ) {
                        requestNotifications()
                    }

                    // App Locking permission card
                    PermissionCard(
                        icon: "lock.shield.fill",
                        iconColor: MPColors.accentGold,
                        title: "App Locking",
                        description: "Lock distractions until your habits are done",
                        isEnabled: screenTimeEnabled,
                        isLoading: isRequestingScreenTime
                    ) {
                        requestScreenTimeAccess()
                    }
                }
                .padding(.horizontal, MPSpacing.xl)

                Spacer()
                    .frame(minHeight: 20)

                VStack(spacing: MPSpacing.md) {
                    MPButton(title: "All Set", style: .primary) {
                        onContinue()
                    }

                    Text("You can change these anytime in Settings")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.textTertiary)
                }
                .padding(.horizontal, MPSpacing.xxxl)
                .padding(.bottom, max(30, geometry.safeAreaInsets.bottom + 20))
            }
        }
        .onAppear {
            // Check if Screen Time was already authorized in earlier step
            screenTimeEnabled = screenTimeManager.isAuthorized
        }
    }

    private func requestHealthAccess() {
        isRequestingHealth = true
        Task {
            let authorized = await healthKit.requestAuthorization()
            await MainActor.run {
                isRequestingHealth = false
                data.healthConnected = authorized
            }
        }
    }

    private func requestNotifications() {
        isRequestingNotifications = true
        Task {
            let granted = await notificationManager.requestPermission()
            await MainActor.run {
                isRequestingNotifications = false
                data.notificationsEnabled = granted
            }
        }
    }

    private func requestScreenTimeAccess() {
        isRequestingScreenTime = true
        Task {
            do {
                try await screenTimeManager.requestAuthorization()
                await MainActor.run {
                    isRequestingScreenTime = false
                    screenTimeEnabled = screenTimeManager.isAuthorized
                }
            } catch {
                await MainActor.run {
                    isRequestingScreenTime = false
                }
            }
        }
    }
}

// MARK: - Permission Card Component

struct PermissionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()

            Button(action: action) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(isEnabled ? MPColors.success : MPColors.primary)
                    } else if isEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(MPColors.success)
                    } else {
                        Text("Continue")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, MPSpacing.md)
                            .padding(.vertical, MPSpacing.sm)
                            .background(MPColors.primary)
                            .cornerRadius(MPRadius.full)
                    }
                }
            }
            .disabled(isLoading || isEnabled)
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }
}

import SwiftUI

struct AppLockingSettingsView: View {
    @Environment(\.dismiss) var dismiss

    // Example apps that could be locked (placeholder data)
    private let suggestedApps = [
        AppInfo(name: "Instagram", icon: "camera.fill", bundleId: "com.instagram.instagram"),
        AppInfo(name: "TikTok", icon: "play.rectangle.fill", bundleId: "com.zhiliaoapp.musically"),
        AppInfo(name: "Twitter / X", icon: "bubble.left.fill", bundleId: "com.twitter.twitter"),
        AppInfo(name: "YouTube", icon: "play.tv.fill", bundleId: "com.google.ios.youtube"),
        AppInfo(name: "Reddit", icon: "text.bubble.fill", bundleId: "com.reddit.reddit"),
        AppInfo(name: "Facebook", icon: "person.2.fill", bundleId: "com.facebook.facebook"),
        AppInfo(name: "Snapchat", icon: "camera.viewfinder", bundleId: "com.toyopagroup.picaboo"),
        AppInfo(name: "Netflix", icon: "tv.fill", bundleId: "com.netflix.netflix")
    ]

    @State private var selectedApps: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MPSpacing.xl) {
                        // Header explanation
                        headerSection

                        // Coming soon banner
                        comingSoonBanner

                        // App selection
                        appSelectionSection

                        // How it works
                        howItWorksSection
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
        }
    }

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

    var comingSoonBanner: some View {
        HStack(spacing: MPSpacing.md) {
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.title2)
                .foregroundColor(MPColors.accent)

            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text("Coming Soon")
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textPrimary)

                Text("App locking requires special approval from Apple. We're working on getting this feature approved.")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }
        }
        .padding(MPSpacing.lg)
        .background(MPColors.warningLight)
        .cornerRadius(MPRadius.lg)
    }

    var appSelectionSection: some View {
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            Text("APPS TO BLOCK")
                .font(MPFont.labelSmall())
                .foregroundColor(MPColors.textTertiary)
                .tracking(0.5)
                .padding(.leading, MPSpacing.xs)

            VStack(spacing: 0) {
                ForEach(suggestedApps) { app in
                    appRow(app)

                    if app.id != suggestedApps.last?.id {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
        }
    }

    func appRow(_ app: AppInfo) -> some View {
        let isSelected = selectedApps.contains(app.bundleId)

        return Button {
            if isSelected {
                selectedApps.remove(app.bundleId)
            } else {
                selectedApps.insert(app.bundleId)
            }
        } label: {
            HStack(spacing: MPSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(isSelected ? MPColors.primaryLight.opacity(0.3) : MPColors.surfaceSecondary)
                        .frame(width: 44, height: 44)

                    Image(systemName: app.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? MPColors.primary : MPColors.textTertiary)
                }

                Text(app.name)
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? MPColors.primary : MPColors.border)
            }
            .padding(.vertical, MPSpacing.sm)
        }
    }

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
                    title: "Select Apps",
                    description: "Choose which apps to block during your morning routine"
                )

                howItWorksRow(
                    number: "2",
                    title: "Morning Starts",
                    description: "Selected apps are blocked until you complete your habits"
                )

                howItWorksRow(
                    number: "3",
                    title: "Complete Habits",
                    description: "Once all habits are done, apps unlock automatically"
                )

                howItWorksRow(
                    number: "4",
                    title: "Grace Period",
                    description: "If cutoff passes, apps stay locked for your set grace period"
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
}

// MARK: - App Info Model

struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let bundleId: String
}

#Preview {
    AppLockingSettingsView()
}

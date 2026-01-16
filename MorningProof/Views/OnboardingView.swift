import SwiftUI

struct OnboardingView: View {
    @ObservedObject var manager: MorningProofManager
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var selectedHabits: Set<HabitType> = [.madeBed, .sleepDuration, .coldShower, .noSnooze]
    @State private var cutoffMinutes = 540  // 9:00 AM
    @State private var showCutoffTimePicker = false
    @State private var isRequestingHealth = false
    @State private var healthAuthorized = false
    @FocusState private var isNameFieldFocused: Bool

    private let healthKit = HealthKitManager.shared

    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            VStack {
                // Progress dots
                HStack(spacing: MPSpacing.sm) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index <= currentPage ? MPColors.primary : MPColors.border)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, MPSpacing.xl)

                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    namePage.tag(1)
                    habitsPage.tag(2)
                    permissionsPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
            }
        }
    }

    // MARK: - Welcome Page

    var welcomePage: some View {
        VStack(spacing: MPSpacing.xxxl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(MPColors.surface)
                    .frame(width: 160, height: 160)
                    .mpShadow(.large)

                Image(systemName: "sunrise.fill")
                    .font(.system(size: 70))
                    .foregroundColor(MPColors.accent)
            }

            VStack(spacing: MPSpacing.md) {
                Text("Morning Proof")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(MPColors.textPrimary)

                Text("Build unshakeable morning habits\nwith proof-based accountability")
                    .font(MPFont.bodyLarge())
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            MPButton(title: "Get Started", style: .primary) {
                withAnimation { currentPage = 1 }
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, MPSpacing.xxxl)
    }

    // MARK: - Name Page

    var namePage: some View {
        VStack(spacing: MPSpacing.xxxl) {
            Spacer()

            VStack(spacing: MPSpacing.lg) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: MPIconSize.hero))
                    .foregroundColor(MPColors.primaryLight)

                Text("What should we call you?")
                    .font(MPFont.headingSmall())
                    .foregroundColor(MPColors.textPrimary)
            }

            TextField("", text: $userName, prompt: Text("Your name").foregroundColor(MPColors.textSecondary))
                .font(.title3)
                .foregroundColor(MPColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(MPSpacing.lg)
                .background(MPColors.surface)
                .cornerRadius(MPRadius.lg)
                .mpShadow(.small)
                .padding(.horizontal, 40)
                .focused($isNameFieldFocused)

            // Time settings
            VStack(spacing: MPSpacing.lg) {
                Button {
                    showCutoffTimePicker = true
                } label: {
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

                        Text(TimeOptions.formatTime(cutoffMinutes))
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundColor(MPColors.primary)
                            .padding(.horizontal, MPSpacing.md)
                            .padding(.vertical, MPSpacing.sm)
                            .background(MPColors.primaryLight)
                            .cornerRadius(MPRadius.md)
                    }
                }
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
            .padding(.horizontal, MPSpacing.xxxl)
            .sheet(isPresented: $showCutoffTimePicker) {
                TimeWheelPicker(
                    selectedMinutes: $cutoffMinutes,
                    title: "Morning Cutoff Time",
                    subtitle: "Complete your habits by this time to lock in your day",
                    timeOptions: TimeOptions.cutoffTime
                )
                .presentationDetents([.medium])
            }

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                isNameFieldFocused = false
                withAnimation { currentPage = 2 }
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, MPSpacing.xxxl)
    }

    // MARK: - Habits Page

    var habitsPage: some View {
        VStack(spacing: MPSpacing.xxl) {
            VStack(spacing: MPSpacing.sm) {
                Text("Choose Your Habits")
                    .font(MPFont.headingSmall())
                    .foregroundColor(MPColors.textPrimary)

                Text("Select at least 3 morning habits to track")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
            }
            .padding(.top, MPSpacing.xxxl)

            ScrollView {
                VStack(spacing: MPSpacing.md) {
                    ForEach(HabitType.allCases) { habitType in
                        habitSelectionRow(habitType)
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
            }

            MPButton(title: "Continue", style: .primary, isDisabled: selectedHabits.count < 3) {
                withAnimation { currentPage = 3 }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }

    func habitSelectionRow(_ habitType: HabitType) -> some View {
        let isSelected = selectedHabits.contains(habitType)

        return Button {
            if isSelected {
                selectedHabits.remove(habitType)
            } else {
                selectedHabits.insert(habitType)
            }
        } label: {
            HStack(spacing: MPSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(isSelected ? MPColors.successLight : MPColors.surfaceSecondary)
                        .frame(width: 44, height: 44)

                    Image(systemName: habitType.icon)
                        .font(.system(size: MPIconSize.sm))
                        .foregroundColor(isSelected ? MPColors.success : MPColors.textTertiary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(habitType.displayName)
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)

                    Text(habitType.tier.description)
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? MPColors.success : MPColors.border)
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
        }
    }

    // MARK: - Permissions Page

    var permissionsPage: some View {
        VStack(spacing: MPSpacing.xxxl) {
            Spacer()

            VStack(spacing: MPSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(MPColors.surface)
                        .frame(width: 120, height: 120)
                        .mpShadow(.medium)

                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: MPIconSize.hero))
                        .foregroundColor(MPColors.error)
                }

                Text("Connect Health Data")
                    .font(MPFont.headingSmall())
                    .foregroundColor(MPColors.textPrimary)

                Text("Morning Proof uses Apple Health to\nautomatically track your steps and sleep")
                    .font(MPFont.bodyLarge())
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Permission items
            VStack(spacing: MPSpacing.lg) {
                permissionRow(icon: "figure.walk", title: "Step Count", description: "Track morning walks")
                permissionRow(icon: "moon.zzz.fill", title: "Sleep Analysis", description: "Monitor sleep duration")
            }
            .padding(MPSpacing.xl)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.medium)
            .padding(.horizontal, MPSpacing.xxxl)

            Spacer()

            VStack(spacing: MPSpacing.md) {
                Button {
                    requestHealthPermissions()
                } label: {
                    HStack {
                        if isRequestingHealth {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: healthAuthorized ? "checkmark.circle.fill" : "heart.fill")
                            Text(healthAuthorized ? "Connected!" : "Connect Health")
                        }
                    }
                    .font(MPFont.labelLarge())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: MPButtonHeight.lg)
                    .background(healthAuthorized ? MPColors.success : MPColors.error)
                    .cornerRadius(MPRadius.lg)
                }
                .disabled(isRequestingHealth || healthAuthorized)

                Button {
                    completeOnboarding()
                } label: {
                    Text(healthAuthorized ? "Continue" : "Skip for Now")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.primary)
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }

    func permissionRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: MPSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: MPIconSize.lg))
                .foregroundColor(MPColors.primary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()
        }
    }

    func requestHealthPermissions() {
        isRequestingHealth = true

        Task {
            let authorized = await healthKit.requestAuthorization()
            await MainActor.run {
                isRequestingHealth = false
                healthAuthorized = authorized
            }
        }
    }

    func completeOnboarding() {
        // Save settings
        manager.settings.userName = userName
        manager.settings.morningCutoffMinutes = cutoffMinutes

        // Update habit configs
        for habitType in HabitType.allCases {
            let isEnabled = selectedHabits.contains(habitType)
            manager.updateHabitConfig(habitType, isEnabled: isEnabled)
        }

        // Complete onboarding
        manager.completeOnboarding()
    }
}

#Preview {
    OnboardingView(manager: MorningProofManager.shared)
}

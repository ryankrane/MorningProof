import SwiftUI

struct OnboardingView: View {
    @ObservedObject var manager: MorningProofManager
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var selectedHabits: Set<HabitType> = [.madeBed, .morningSteps, .sleepDuration, .drankWater]
    @State private var wakeTimeHour = 7
    @State private var cutoffHour = 9
    @State private var isRequestingHealth = false
    @State private var healthAuthorized = false

    private let healthKit = HealthKitManager.shared

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.96, blue: 0.93)
                .ignoresSafeArea()

            VStack {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index <= currentPage ?
                                Color(red: 0.55, green: 0.45, blue: 0.35) :
                                Color(red: 0.85, green: 0.82, blue: 0.78))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)

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
        VStack(spacing: 30) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 160, height: 160)
                    .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)

                Image(systemName: "sunrise.fill")
                    .font(.system(size: 70))
                    .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.4))
            }

            VStack(spacing: 12) {
                Text("Morning Proof")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                Text("Build unshakeable morning habits\nwith proof-based accountability")
                    .font(.body)
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    .multilineTextAlignment(.center)
            }

            Spacer()

            nextButton(title: "Get Started") {
                withAnimation { currentPage = 1 }
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Name Page

    var namePage: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.75, green: 0.65, blue: 0.55))

                Text("What should we call you?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
            }

            TextField("Your name", text: $userName)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(16)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 40)

            // Time settings
            VStack(spacing: 20) {
                HStack {
                    Text("Wake time")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))

                    Spacer()

                    Picker("Wake time", selection: $wakeTimeHour) {
                        ForEach(4..<11) { hour in
                            Text("\(hour):00 AM").tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color(red: 0.55, green: 0.45, blue: 0.35))
                }

                HStack {
                    Text("Morning cutoff")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))

                    Spacer()

                    Picker("Cutoff", selection: $cutoffHour) {
                        ForEach(7..<13) { hour in
                            Text("\(hour):00 AM").tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color(red: 0.55, green: 0.45, blue: 0.35))
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 30)

            Spacer()

            nextButton(title: "Continue") {
                withAnimation { currentPage = 2 }
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Habits Page

    var habitsPage: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Choose Your Habits")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                Text("Select at least 3 morning habits to track")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
            }
            .padding(.top, 30)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(HabitType.allCases) { habitType in
                        habitSelectionRow(habitType)
                    }
                }
                .padding(.horizontal, 20)
            }

            nextButton(title: "Continue") {
                withAnimation { currentPage = 3 }
            }
            .disabled(selectedHabits.count < 3)
            .opacity(selectedHabits.count < 3 ? 0.5 : 1)
            .padding(.horizontal, 30)
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
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ?
                            Color(red: 0.9, green: 0.97, blue: 0.9) :
                            Color(red: 0.95, green: 0.93, blue: 0.9))
                        .frame(width: 44, height: 44)

                    Image(systemName: habitType.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ?
                            Color(red: 0.4, green: 0.7, blue: 0.45) :
                            Color(red: 0.6, green: 0.55, blue: 0.5))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(habitType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                    Text(habitType.tier.description)
                        .font(.caption)
                        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ?
                        Color(red: 0.55, green: 0.75, blue: 0.55) :
                        Color(red: 0.8, green: 0.75, blue: 0.7))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Permissions Page

    var permissionsPage: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)

                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.5))
                }

                Text("Connect Health Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                Text("Morning Proof uses Apple Health to\nautomatically track your steps and sleep")
                    .font(.body)
                    .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                    .multilineTextAlignment(.center)
            }

            // Permission items
            VStack(spacing: 16) {
                permissionRow(icon: "figure.walk", title: "Step Count", description: "Track morning walks")
                permissionRow(icon: "moon.zzz.fill", title: "Sleep Analysis", description: "Monitor sleep duration")
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 12) {
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
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(healthAuthorized ?
                        Color(red: 0.55, green: 0.75, blue: 0.55) :
                        Color(red: 0.9, green: 0.5, blue: 0.5))
                    .cornerRadius(14)
                }
                .disabled(isRequestingHealth || healthAuthorized)

                Button {
                    completeOnboarding()
                } label: {
                    Text(healthAuthorized ? "Continue" : "Skip for Now")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }

    func permissionRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
            }

            Spacer()
        }
    }

    // MARK: - Actions

    func nextButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(red: 0.55, green: 0.45, blue: 0.35))
                .cornerRadius(14)
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
        manager.settings.wakeTimeHour = wakeTimeHour
        manager.settings.morningCutoffHour = cutoffHour

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

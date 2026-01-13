import SwiftUI
import StoreKit
import AuthenticationServices

// MARK: - Onboarding Data Model

class OnboardingData: ObservableObject {
    @Published var userName: String = ""
    @Published var gender: Gender = .preferNotToSay
    @Published var heardAboutUs: HeardAboutSource = .other
    @Published var currentlyTracking: Bool = false
    @Published var primaryGoal: PrimaryGoal = .setHabits
    @Published var obstacles: Set<Obstacle> = []
    @Published var desiredOutcome: DesiredOutcome = .moreEnergy
    @Published var healthConnected: Bool = false
    @Published var notificationsEnabled: Bool = false
    @Published var selectedHabits: Set<HabitType> = [.madeBed, .sleepDuration, .noSnooze]

    enum Gender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
        case preferNotToSay = "Prefer not to say"

        var icon: String {
            switch self {
            case .male: return "figure.stand"
            case .female: return "figure.stand.dress"
            case .preferNotToSay: return "person.fill.questionmark"
            }
        }
    }

    enum HeardAboutSource: String, CaseIterable {
        case appStore = "App Store"
        case socialMedia = "Social Media"
        case friend = "Friend or Family"
        case youtube = "YouTube"
        case podcast = "Podcast"
        case other = "Other"

        var icon: String {
            switch self {
            case .appStore: return "apple.logo"
            case .socialMedia: return "bubble.left.and.bubble.right.fill"
            case .friend: return "person.2.fill"
            case .youtube: return "play.rectangle.fill"
            case .podcast: return "mic.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }

    enum PrimaryGoal: String, CaseIterable {
        case setHabits = "Set new habits"
        case maintainHabits = "Maintain existing habits"

        var icon: String {
            switch self {
            case .setHabits: return "plus.circle.fill"
            case .maintainHabits: return "checkmark.circle.fill"
            }
        }

        var description: String {
            switch self {
            case .setHabits: return "Build a consistent morning routine from scratch"
            case .maintainHabits: return "Stay accountable to habits you've already started"
            }
        }
    }

    enum Obstacle: String, CaseIterable {
        case lackMotivation = "Lack of motivation"
        case forgetful = "I forget to do them"
        case noTime = "Not enough time"
        case noAccountability = "No accountability"
        case overwhelmed = "Feel overwhelmed"
        case inconsistent = "Inconsistent schedule"

        var icon: String {
            switch self {
            case .lackMotivation: return "battery.25"
            case .forgetful: return "brain"
            case .noTime: return "clock.fill"
            case .noAccountability: return "person.slash.fill"
            case .overwhelmed: return "tornado"
            case .inconsistent: return "calendar.badge.exclamationmark"
            }
        }
    }

    enum DesiredOutcome: String, CaseIterable {
        case moreEnergy = "More energy"
        case betterFocus = "Better focus"
        case improvedMood = "Improved mood"
        case increasedProductivity = "Increased productivity"
        case betterHealth = "Better health"
        case selfDiscipline = "Self-discipline"

        var icon: String {
            switch self {
            case .moreEnergy: return "bolt.fill"
            case .betterFocus: return "target"
            case .improvedMood: return "face.smiling.fill"
            case .increasedProductivity: return "chart.line.uptrend.xyaxis"
            case .betterHealth: return "heart.fill"
            case .selfDiscipline: return "flame.fill"
            }
        }
    }
}

// MARK: - Onboarding Flow View

struct OnboardingFlowView: View {
    @ObservedObject var manager: MorningProofManager
    @StateObject private var onboardingData = OnboardingData()
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var currentStep = 0
    @State private var isAnimatingTransition = false

    private let totalSteps = 15

    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with skip button
                HStack {
                    Spacer()

                    // Skip button for testing
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Skip")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textTertiary)
                            .padding(.horizontal, MPSpacing.md)
                            .padding(.vertical, MPSpacing.sm)
                    }
                }
                .padding(.horizontal, MPSpacing.lg)
                .padding(.top, MPSpacing.sm)

                // Progress bar
                if currentStep > 0 && currentStep < totalSteps - 1 {
                    OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps - 2)
                        .padding(.horizontal, MPSpacing.xl)
                        .padding(.top, MPSpacing.sm)
                }

                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep(onContinue: nextStep)
                        .tag(0)

                    GenderStep(data: onboardingData, onContinue: nextStep)
                        .tag(1)

                    NameStep(data: onboardingData, onContinue: nextStep)
                        .tag(2)

                    HeardAboutStep(data: onboardingData, onContinue: nextStep)
                        .tag(3)

                    TrackingQuestionStep(data: onboardingData, onContinue: nextStep)
                        .tag(4)

                    TrackingComparisonStep(currentlyTracking: onboardingData.currentlyTracking, onContinue: nextStep)
                        .tag(5)

                    PrimaryGoalStep(data: onboardingData, onContinue: nextStep)
                        .tag(6)

                    GainTwiceAnimationStep(onContinue: nextStep)
                        .tag(7)

                    ObstaclesStep(data: onboardingData, onContinue: nextStep)
                        .tag(8)

                    DesiredOutcomeStep(data: onboardingData, onContinue: nextStep)
                        .tag(9)

                    HealthConnectStep(data: onboardingData, onContinue: nextStep)
                        .tag(10)

                    RatingStep(onContinue: nextStep)
                        .tag(11)

                    NotificationStep(data: onboardingData, onContinue: nextStep)
                        .tag(12)

                    LoadingPlanStep(userName: onboardingData.userName, onComplete: nextStep)
                        .tag(13)

                    CustomPlanStep(
                        data: onboardingData,
                        manager: manager,
                        onComplete: completeOnboarding
                    )
                    .tag(14)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    private func nextStep() {
        // If user just signed in, prefill their name
        if currentStep == 0, let user = authManager.currentUser {
            if let fullName = user.fullName, !fullName.isEmpty {
                // Extract first name only
                let firstName = fullName.components(separatedBy: " ").first ?? fullName
                onboardingData.userName = firstName
            }
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }

    private func completeOnboarding() {
        // Save all data to manager
        manager.settings.userName = onboardingData.userName

        // Update habit configs
        for habitType in HabitType.allCases {
            let isEnabled = onboardingData.selectedHabits.contains(habitType)
            manager.updateHabitConfig(habitType, isEnabled: isEnabled)
        }

        manager.completeOnboarding()
    }
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var progress: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(MPColors.progressBg)
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(MPColors.primary)
                    .frame(width: geometry.size.width * progress, height: 6)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Step 1: Welcome

struct WelcomeStep: View {
    let onContinue: () -> Void
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var animateIcon = false
    @State private var animateText = false
    @State private var showSignInOptions = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App branding
            VStack(spacing: MPSpacing.xl) {
                Text("Morning Proof")
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundColor(MPColors.textPrimary)
                    .tracking(-0.5)
                    .opacity(animateText ? 1 : 0)
                    .offset(y: animateText ? 0 : 20)

                // Soft gradient orb
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    MPColors.accentLight.opacity(0.8),
                                    MPColors.accent.opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateIcon ? 1.05 : 1.0)

                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [MPColors.accent, MPColors.accentGold],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: animateIcon ? -3 : 3)
                }
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateIcon)
            }

            Spacer().frame(height: 40)

            // Purpose statement
            VStack(spacing: MPSpacing.md) {
                Text("Build your morning routine")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)
                    .opacity(animateText ? 1 : 0)

                Text("Prove your habits with AI verification.\nTrack streaks, stay accountable, win your mornings.")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(animateText ? 1 : 0)
            }
            .padding(.horizontal, MPSpacing.xxxl)

            Spacer()

            // Sign-in buttons
            VStack(spacing: MPSpacing.md) {
                // Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
                    authManager.handleAppleSignInRequest(request)
                } onCompletion: { result in
                    authManager.handleAppleSignInCompletion(result) { success in
                        if success {
                            onContinue()
                        }
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(MPRadius.lg)

                // Sign in with Google button (styled to match)
                Button {
                    authManager.signInWithGoogle { success in
                        if success {
                            onContinue()
                        }
                    }
                } label: {
                    HStack(spacing: MPSpacing.md) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))
                        Text("Sign in with Google")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(MPColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: MPRadius.lg)
                            .stroke(MPColors.border, lineWidth: 1)
                    )
                }

                // Divider with "or"
                HStack {
                    Rectangle()
                        .fill(MPColors.divider)
                        .frame(height: 1)
                    Text("or")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                        .padding(.horizontal, MPSpacing.md)
                    Rectangle()
                        .fill(MPColors.divider)
                        .frame(height: 1)
                }
                .padding(.vertical, MPSpacing.sm)

                // Continue without account
                Button {
                    authManager.continueAnonymously()
                    onContinue()
                } label: {
                    Text("Continue without account")
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.primary)
                }
            }
            .padding(.horizontal, MPSpacing.xl)
            .padding(.bottom, 50)
            .opacity(animateText ? 1 : 0)

            // Error message
            if let error = authManager.errorMessage {
                Text(error)
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.bottom, MPSpacing.md)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateText = true
            }
            animateIcon = true
        }
    }
}

// MARK: - Step 2: Gender

struct GenderStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.md) {
                Text("How do you identify?")
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)

                Text("This helps us personalize your experience")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.md) {
                ForEach(OnboardingData.Gender.allCases, id: \.rawValue) { gender in
                    OnboardingOptionButton(
                        title: gender.rawValue,
                        icon: gender.icon,
                        isSelected: data.gender == gender
                    ) {
                        data.gender = gender
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 3: Name (Optional)

struct NameStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.md) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(MPColors.primary)

                Text("What should we call you?")
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)

                Text("Optional - just to personalize your experience")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            TextField("", text: $data.userName, prompt: Text("First name (optional)").foregroundColor(MPColors.textTertiary))
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(MPColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(MPSpacing.xl)
                .background(MPColors.surface)
                .cornerRadius(MPRadius.lg)
                .mpShadow(.small)
                .padding(.horizontal, MPSpacing.xxxl)
                .focused($isNameFocused)

            Spacer()

            MPButton(
                title: "Continue",
                style: .primary
            ) {
                isNameFocused = false
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
    }
}

// MARK: - Step 4: Where did you hear about us

struct HeardAboutStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.md) {
                Text("Where did you hear\nabout us?")
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Help us understand how you found Morning Proof")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MPSpacing.md) {
                ForEach(OnboardingData.HeardAboutSource.allCases, id: \.rawValue) { source in
                    OnboardingGridButton(
                        title: source.rawValue,
                        icon: source.icon,
                        isSelected: data.heardAboutUs == source
                    ) {
                        data.heardAboutUs = source
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 5: Do you currently track

struct TrackingQuestionStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.md) {
                Image(systemName: "checklist")
                    .font(.system(size: 60))
                    .foregroundColor(MPColors.primary)

                Text("Do you currently track\nyour morning routine?")
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.md) {
                OnboardingOptionButton(
                    title: "Yes, I track my habits",
                    icon: "checkmark.circle.fill",
                    isSelected: data.currentlyTracking
                ) {
                    data.currentlyTracking = true
                }

                OnboardingOptionButton(
                    title: "No, I don't track yet",
                    icon: "xmark.circle.fill",
                    isSelected: !data.currentlyTracking
                ) {
                    data.currentlyTracking = false
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 6: Tracking Comparison Animation

struct TrackingComparisonStep: View {
    let currentlyTracking: Bool
    let onContinue: () -> Void

    @State private var showComparison = false
    @State private var trackingProgress: CGFloat = 0
    @State private var noTrackingProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            Text("The Power of Tracking")
                .font(MPFont.headingLarge())
                .foregroundColor(MPColors.textPrimary)

            Spacer().frame(height: MPSpacing.xxxl)

            // Comparison cards
            HStack(spacing: MPSpacing.lg) {
                // Without tracking
                VStack(spacing: MPSpacing.lg) {
                    ZStack {
                        Circle()
                            .stroke(MPColors.progressBg, lineWidth: 8)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: noTrackingProgress)
                            .stroke(MPColors.error, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(noTrackingProgress * 100))%")
                            .font(MPFont.headingMedium())
                            .foregroundColor(MPColors.textPrimary)
                    }

                    Text("Without\nTracking")
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)

                    Text("23% success rate")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.textTertiary)
                }
                .padding(MPSpacing.xl)
                .background(MPColors.surface)
                .cornerRadius(MPRadius.lg)
                .mpShadow(.small)

                // With tracking
                VStack(spacing: MPSpacing.lg) {
                    ZStack {
                        Circle()
                            .stroke(MPColors.progressBg, lineWidth: 8)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: trackingProgress)
                            .stroke(MPColors.success, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(trackingProgress * 100))%")
                            .font(MPFont.headingMedium())
                            .foregroundColor(MPColors.textPrimary)
                    }

                    Text("With\nTracking")
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)

                    Text("91% success rate")
                        .font(MPFont.bodySmall())
                        .foregroundColor(MPColors.success)
                }
                .padding(MPSpacing.xl)
                .background(MPColors.surface)
                .cornerRadius(MPRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: MPRadius.lg)
                        .stroke(MPColors.success.opacity(0.3), lineWidth: 2)
                )
                .mpShadow(.medium)
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer().frame(height: MPSpacing.xxxl)

            // Insight text
            VStack(spacing: MPSpacing.sm) {
                Text("People who track their habits are")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)

                Text("4x more likely to succeed")
                    .font(MPFont.headingSmall())
                    .foregroundColor(MPColors.success)
            }
            .opacity(showComparison ? 1 : 0)

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                noTrackingProgress = 0.23
            }
            withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                trackingProgress = 0.91
            }
            withAnimation(.easeIn(duration: 0.5).delay(1.5)) {
                showComparison = true
            }
        }
    }
}

// MARK: - Step 7: Primary Goal

struct PrimaryGoalStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.md) {
                Image(systemName: "target")
                    .font(.system(size: 50))
                    .foregroundColor(MPColors.accent)

                Text("What's your goal?")
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.md) {
                ForEach(OnboardingData.PrimaryGoal.allCases, id: \.rawValue) { goal in
                    Button {
                        data.primaryGoal = goal
                    } label: {
                        HStack(spacing: MPSpacing.lg) {
                            ZStack {
                                Circle()
                                    .fill(data.primaryGoal == goal ? MPColors.primaryLight : MPColors.surfaceSecondary)
                                    .frame(width: 50, height: 50)

                                Image(systemName: goal.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(data.primaryGoal == goal ? MPColors.primary : MPColors.textTertiary)
                            }

                            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                                Text(goal.rawValue)
                                    .font(MPFont.labelLarge())
                                    .foregroundColor(MPColors.textPrimary)

                                Text(goal.description)
                                    .font(MPFont.bodySmall())
                                    .foregroundColor(MPColors.textTertiary)
                            }

                            Spacer()

                            Image(systemName: data.primaryGoal == goal ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundColor(data.primaryGoal == goal ? MPColors.primary : MPColors.border)
                        }
                        .padding(MPSpacing.lg)
                        .background(MPColors.surface)
                        .cornerRadius(MPRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: MPRadius.lg)
                                .stroke(data.primaryGoal == goal ? MPColors.primary : Color.clear, lineWidth: 2)
                        )
                        .mpShadow(.small)
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 8: Gain Twice Animation

struct GainTwiceAnimationStep: View {
    let onContinue: () -> Void

    @State private var showMultiplier = false
    @State private var showText = false
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated multiplier
            ZStack {
                // Pulse circles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(MPColors.accent.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: CGFloat(150 + index * 40), height: CGFloat(150 + index * 40))
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0 : 1)
                        .animation(
                            .easeOut(duration: 2)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                            value: pulseAnimation
                        )
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MPColors.accent, MPColors.accentGold],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .mpShadow(.large)

                Text("2x")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(showMultiplier ? 1 : 0.5)
                    .opacity(showMultiplier ? 1 : 0)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.lg) {
                Text("Gain Twice as Much")
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 20)

                Text("Morning Proof users accomplish\ntwice their goals compared to\ntraditional habit trackers.")
                    .font(MPFont.bodyLarge())
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(showText ? 1 : 0)
                    .offset(y: showText ? 0 : 20)
            }

            Spacer()

            MPButton(title: "Show Me How", style: .primary, icon: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            pulseAnimation = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showMultiplier = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                showText = true
            }
        }
    }
}

// MARK: - Step 9: Obstacles

struct ObstaclesStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.md) {
                Text("What's stopping you from\nreaching your goals?")
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Select all that apply")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MPSpacing.md) {
                ForEach(OnboardingData.Obstacle.allCases, id: \.rawValue) { obstacle in
                    OnboardingGridButton(
                        title: obstacle.rawValue,
                        icon: obstacle.icon,
                        isSelected: data.obstacles.contains(obstacle)
                    ) {
                        if data.obstacles.contains(obstacle) {
                            data.obstacles.remove(obstacle)
                        } else {
                            data.obstacles.insert(obstacle)
                        }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(
                title: "Continue",
                style: .primary,
                isDisabled: data.obstacles.isEmpty
            ) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 10: Desired Outcome

struct DesiredOutcomeStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.md) {
                Image(systemName: "star.fill")
                    .font(.system(size: 50))
                    .foregroundColor(MPColors.accentGold)

                Text("What would you like\nto accomplish?")
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Your primary motivation")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MPSpacing.md) {
                ForEach(OnboardingData.DesiredOutcome.allCases, id: \.rawValue) { outcome in
                    OnboardingGridButton(
                        title: outcome.rawValue,
                        icon: outcome.icon,
                        isSelected: data.desiredOutcome == outcome
                    ) {
                        data.desiredOutcome = outcome
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 11: Health Connect

struct HealthConnectStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    @State private var isRequesting = false
    private let healthKit = HealthKitManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            ZStack {
                Circle()
                    .fill(MPColors.errorLight)
                    .frame(width: 120, height: 120)

                Image(systemName: "heart.fill")
                    .font(.system(size: 50))
                    .foregroundColor(MPColors.error)
            }

            Spacer().frame(height: MPSpacing.xxl)

            VStack(spacing: MPSpacing.md) {
                Text("Connect Apple Health")
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)

                Text("Automatically track your sleep\nand step count")
                    .font(MPFont.bodyLarge())
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            // Benefits
            VStack(spacing: MPSpacing.lg) {
                HealthBenefitRow(icon: "moon.zzz.fill", title: "Sleep Tracking", description: "Auto-log your sleep duration")
                HealthBenefitRow(icon: "figure.walk", title: "Step Count", description: "Track morning walks automatically")
            }
            .padding(MPSpacing.xl)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            VStack(spacing: MPSpacing.md) {
                Button {
                    requestHealthAccess()
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: data.healthConnected ? "checkmark.circle.fill" : "heart.fill")
                            Text(data.healthConnected ? "Connected!" : "Connect Health")
                        }
                    }
                    .font(MPFont.labelLarge())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: MPButtonHeight.lg)
                    .background(data.healthConnected ? MPColors.success : MPColors.error)
                    .cornerRadius(MPRadius.lg)
                }
                .disabled(isRequesting || data.healthConnected)

                Button {
                    onContinue()
                } label: {
                    Text(data.healthConnected ? "Continue" : "Skip for Now")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.primary)
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }

    private func requestHealthAccess() {
        isRequesting = true
        Task {
            let authorized = await healthKit.requestAuthorization()
            await MainActor.run {
                isRequesting = false
                data.healthConnected = authorized
                if authorized {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onContinue()
                    }
                }
            }
        }
    }
}

struct HealthBenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 24))
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
}

// MARK: - Step 12: Rating

struct RatingStep: View {
    let onContinue: () -> Void
    @State private var hasRequestedReview = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(MPColors.accentLight)
                    .frame(width: 120, height: 120)

                Image(systemName: "star.fill")
                    .font(.system(size: 50))
                    .foregroundColor(MPColors.accentGold)
            }

            Spacer().frame(height: MPSpacing.xxl)

            VStack(spacing: MPSpacing.md) {
                Text("Enjoying Morning Proof?")
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)

                Text("Your rating helps us improve\nand reach more people")
                    .font(MPFont.bodyLarge())
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            // Star rating visual
            HStack(spacing: MPSpacing.sm) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 36))
                        .foregroundColor(MPColors.accentGold)
                }
            }

            Spacer()

            VStack(spacing: MPSpacing.md) {
                MPButton(title: "Rate Morning Proof", style: .primary, icon: "star.fill") {
                    requestReview()
                }

                if hasRequestedReview {
                    Button {
                        onContinue()
                    } label: {
                        Text("Continue")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.primary)
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        hasRequestedReview = true

        // Auto-continue after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            onContinue()
        }
    }
}

// MARK: - Step 13: Notifications

struct NotificationStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    @State private var isRequesting = false
    private let notificationManager = NotificationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            ZStack {
                Circle()
                    .fill(MPColors.primaryLight)
                    .frame(width: 120, height: 120)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 50))
                    .foregroundColor(MPColors.primary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            VStack(spacing: MPSpacing.md) {
                Text("Stay on Track")
                    .font(MPFont.headingLarge())
                    .foregroundColor(MPColors.textPrimary)

                Text("Get gentle reminders to complete\nyour morning routine")
                    .font(MPFont.bodyLarge())
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            // Notification features
            VStack(spacing: MPSpacing.lg) {
                NotificationFeatureRow(icon: "sunrise.fill", title: "Morning Reminder", description: "Wake up to a motivating nudge")
                NotificationFeatureRow(icon: "clock.badge.exclamationmark.fill", title: "Deadline Alerts", description: "Never miss your cutoff time")
                NotificationFeatureRow(icon: "flame.fill", title: "Streak Protection", description: "Reminders to keep your streak alive")
            }
            .padding(MPSpacing.xl)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .mpShadow(.small)
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            VStack(spacing: MPSpacing.md) {
                Button {
                    requestNotifications()
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: data.notificationsEnabled ? "checkmark.circle.fill" : "bell.fill")
                            Text(data.notificationsEnabled ? "Enabled!" : "Enable Notifications")
                        }
                    }
                    .font(MPFont.labelLarge())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: MPButtonHeight.lg)
                    .background(data.notificationsEnabled ? MPColors.success : MPColors.primary)
                    .cornerRadius(MPRadius.lg)
                }
                .disabled(isRequesting || data.notificationsEnabled)

                Button {
                    onContinue()
                } label: {
                    Text(data.notificationsEnabled ? "Continue" : "Maybe Later")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.primary)
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }

    private func requestNotifications() {
        isRequesting = true
        Task {
            let granted = await notificationManager.requestPermission()
            await MainActor.run {
                isRequesting = false
                data.notificationsEnabled = granted
                if granted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onContinue()
                    }
                }
            }
        }
    }
}

struct NotificationFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(MPColors.accent)
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
}

// MARK: - Step 14: Loading Plan

struct LoadingPlanStep: View {
    let userName: String
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var currentMessage = 0

    private let messages = [
        "Analyzing your goals...",
        "Customizing habits...",
        "Building your routine...",
        "Optimizing for success...",
        "Finalizing your plan..."
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                // Animated loading indicator
                ZStack {
                    Circle()
                        .stroke(MPColors.progressBg, lineWidth: 8)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [MPColors.primary, MPColors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress * 100))%")
                        .font(MPFont.headingMedium())
                        .foregroundColor(MPColors.textPrimary)
                }

                VStack(spacing: MPSpacing.md) {
                    Text("Creating Your Plan")
                        .font(MPFont.headingLarge())
                        .foregroundColor(MPColors.textPrimary)

                    Text(messages[currentMessage])
                        .font(MPFont.bodyLarge())
                        .foregroundColor(MPColors.textSecondary)
                        .animation(.easeInOut, value: currentMessage)
                }
            }

            Spacer()
        }
        .onAppear {
            startLoading()
        }
    }

    private func startLoading() {
        // Animate progress bar
        withAnimation(.easeInOut(duration: 3)) {
            progress = 1.0
        }

        // Cycle through messages
        for i in 0..<messages.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6) {
                withAnimation {
                    currentMessage = i
                }
            }
        }

        // Complete after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            onComplete()
        }
    }
}

// MARK: - Step 15: Custom Plan

struct CustomPlanStep: View {
    @ObservedObject var data: OnboardingData
    @ObservedObject var manager: MorningProofManager
    let onComplete: () -> Void

    @State private var animateCheckmark = false
    @State private var animateContent = false
    @State private var animateChips = false

    // Calculate goal date (30 days from now)
    private var goalDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return formatter.string(from: futureDate)
    }

    // Benefit chips based on user's selections
    private var benefitChips: [(text: String, icon: String, color: Color)] {
        var chips: [(String, String, Color)] = []

        // Add based on desired outcome
        switch data.desiredOutcome {
        case .moreEnergy:
            chips.append(("More Energy", "bolt.fill", Color.orange))
        case .betterFocus:
            chips.append(("Better Focus", "scope", MPColors.primary))
        case .improvedMood:
            chips.append(("Better Mood", "face.smiling.fill", MPColors.success))
        case .increasedProductivity:
            chips.append(("Productivity", "chart.line.uptrend.xyaxis", MPColors.primary))
        case .betterHealth:
            chips.append(("Better Health", "heart.fill", MPColors.error))
        case .selfDiscipline:
            chips.append(("Self-Discipline", "flame.fill", Color.orange))
        }

        // Add some default benefits
        chips.append(("Consistency", "checkmark.circle.fill", MPColors.success))
        chips.append(("Accountability", "person.2.fill", MPColors.accent))
        chips.append(("Better Sleep", "moon.zzz.fill", MPColors.primary))
        chips.append(("Morning Wins", "trophy.fill", MPColors.accentGold))
        chips.append(("Healthy Habits", "leaf.fill", MPColors.success))

        return chips
    }

    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: MPSpacing.xxxl * 2)

                    // Checkmark icon
                    ZStack {
                        Circle()
                            .fill(MPColors.successLight)
                            .frame(width: 80, height: 80)

                        Image(systemName: "checkmark")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(MPColors.success)
                    }
                    .scaleEffect(animateCheckmark ? 1 : 0.5)
                    .opacity(animateCheckmark ? 1 : 0)

                    Spacer().frame(height: MPSpacing.xxl)

                    // Personalized header
                    VStack(spacing: MPSpacing.md) {
                        Text("\(data.userName.isEmpty ? "Friend" : data.userName), we've made you\na custom plan.")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(MPColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)

                        Spacer().frame(height: MPSpacing.md)

                        Text("You will build your routine by:")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textSecondary)
                            .opacity(animateContent ? 1 : 0)

                        // Date pill
                        Text(goalDate)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(MPColors.textPrimary)
                            .padding(.horizontal, MPSpacing.xl)
                            .padding(.vertical, MPSpacing.md)
                            .background(MPColors.surface)
                            .cornerRadius(MPRadius.full)
                            .mpShadow(.small)
                            .opacity(animateContent ? 1 : 0)
                            .scaleEffect(animateContent ? 1 : 0.9)
                    }

                    Spacer().frame(height: MPSpacing.xxxl)

                    // Divider line
                    Rectangle()
                        .fill(MPColors.divider)
                        .frame(width: 200, height: 1)
                        .opacity(animateContent ? 1 : 0)

                    Spacer().frame(height: MPSpacing.xxxl)

                    // Stars decoration
                    HStack(spacing: 4) {
                        // Left laurel
                        Image(systemName: "laurel.leading")
                            .font(.system(size: 36))
                            .foregroundColor(MPColors.textTertiary)

                        // 5 stars
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(MPColors.accentGold)
                            }
                        }

                        // Right laurel
                        Image(systemName: "laurel.trailing")
                            .font(.system(size: 36))
                            .foregroundColor(MPColors.textTertiary)
                    }
                    .opacity(animateContent ? 1 : 0)

                    Spacer().frame(height: MPSpacing.xl)

                    // Motivational headline
                    VStack(spacing: MPSpacing.sm) {
                        Text("Become the best of\nyourself with Morning Proof")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(MPColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1 : 0)

                        Text("Consistent. Accountable. Unstoppable.")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textSecondary)
                            .opacity(animateContent ? 1 : 0)
                    }

                    Spacer().frame(height: MPSpacing.xxl)

                    // Benefit chips
                    BenefitChipsView(chips: benefitChips, animate: animateChips)
                        .padding(.horizontal, MPSpacing.lg)

                    Spacer().frame(height: 140)
                }
            }

            // Bottom CTA overlay
            VStack {
                Spacer()

                VStack(spacing: MPSpacing.md) {
                    MPButton(title: "Start My Journey", style: .primary, icon: "arrow.right") {
                        onComplete()
                    }
                    .padding(.horizontal, MPSpacing.xxxl)

                    // Subtle info text
                    HStack(spacing: MPSpacing.lg) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(MPColors.success)
                                .font(.system(size: 14))
                            Text("Free to start")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.textTertiary)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "sunrise.fill")
                                .foregroundColor(MPColors.accent)
                                .font(.system(size: 14))
                            Text("Transform your mornings")
                                .font(MPFont.bodySmall())
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }
                }
                .padding(.bottom, 40)
                .padding(.top, MPSpacing.lg)
                .background(
                    LinearGradient(
                        colors: [
                            MPColors.background.opacity(0),
                            MPColors.background.opacity(0.9),
                            MPColors.background
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                animateCheckmark = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animateContent = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                animateChips = true
            }
        }
    }
}

// MARK: - Benefit Chips View

struct BenefitChipsView: View {
    let chips: [(text: String, icon: String, color: Color)]
    let animate: Bool

    var body: some View {
        VStack(spacing: MPSpacing.md) {
            // Row 1 - 2 chips
            HStack(spacing: MPSpacing.sm) {
                if chips.count > 0 {
                    BenefitChip(text: chips[0].text, icon: chips[0].icon, color: chips[0].color)
                        .opacity(animate ? 1 : 0)
                        .offset(x: animate ? 0 : -20)
                }
                if chips.count > 1 {
                    BenefitChip(text: chips[1].text, icon: chips[1].icon, color: chips[1].color)
                        .opacity(animate ? 1 : 0)
                        .offset(x: animate ? 0 : 20)
                }
            }

            // Row 2 - 3 chips
            HStack(spacing: MPSpacing.sm) {
                if chips.count > 2 {
                    BenefitChip(text: chips[2].text, icon: chips[2].icon, color: chips[2].color)
                        .opacity(animate ? 1 : 0)
                        .offset(x: animate ? 0 : -20)
                }
                if chips.count > 3 {
                    BenefitChip(text: chips[3].text, icon: chips[3].icon, color: chips[3].color)
                        .opacity(animate ? 1 : 0)
                }
                if chips.count > 4 {
                    BenefitChip(text: chips[4].text, icon: chips[4].icon, color: chips[4].color)
                        .opacity(animate ? 1 : 0)
                        .offset(x: animate ? 0 : 20)
                }
            }

            // Row 3 - 2 chips
            HStack(spacing: MPSpacing.sm) {
                if chips.count > 5 {
                    BenefitChip(text: chips[5].text, icon: chips[5].icon, color: chips[5].color)
                        .opacity(animate ? 1 : 0)
                        .offset(x: animate ? 0 : -20)
                }
                if chips.count > 6 {
                    BenefitChip(text: chips[6].text, icon: chips[6].icon, color: chips[6].color)
                        .opacity(animate ? 1 : 0)
                        .offset(x: animate ? 0 : 20)
                }
            }
        }
    }
}

struct BenefitChip: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MPColors.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(MPColors.surface)
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .mpShadow(.small)
    }
}

struct HabitSelectionRow: View {
    let habitType: HabitType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MPSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(isSelected ? MPColors.successLight : MPColors.surfaceSecondary)
                        .frame(width: 44, height: 44)

                    Image(systemName: habitType.icon)
                        .font(.system(size: 18))
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
            .padding(MPSpacing.md)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.md)
                    .stroke(isSelected ? MPColors.success.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Reusable Components

struct OnboardingOptionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(isSelected ? MPColors.primaryLight : MPColors.surfaceSecondary)
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? MPColors.primary : MPColors.textTertiary)
                }

                Text(title)
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? MPColors.primary : MPColors.border)
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .stroke(isSelected ? MPColors.primary : Color.clear, lineWidth: 2)
            )
            .mpShadow(.small)
        }
    }
}

struct OnboardingGridButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: MPSpacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? MPColors.primaryLight : MPColors.surfaceSecondary)
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? MPColors.primary : MPColors.textTertiary)
                }

                Text(title)
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MPSpacing.lg)
            .padding(.horizontal, MPSpacing.md)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .stroke(isSelected ? MPColors.primary : Color.clear, lineWidth: 2)
            )
            .mpShadow(.small)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlowView(manager: MorningProofManager.shared)
}

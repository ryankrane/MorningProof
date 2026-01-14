import SwiftUI
import StoreKit
import AuthenticationServices

// MARK: - Onboarding Data Model

class OnboardingData: ObservableObject {
    @Published var userName: String = ""
    @Published var gender: Gender = .preferNotToSay
    @Published var heardAboutUs: HeardAboutSource = .instagram
    @Published var trackingStatus: TrackingStatus = .no
    @Published var primaryGoal: PrimaryGoal = .setHabits
    @Published var obstacles: Set<Obstacle> = []
    @Published var desiredOutcomes: Set<DesiredOutcome> = []
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
        case instagram = "Instagram"
        case tiktok = "TikTok"
        case reddit = "Reddit"
        case youtube = "YouTube"
        case friend = "Friend or Family"
        case other = "Other"

        var icon: String {
            switch self {
            case .instagram: return "camera.circle.fill"
            case .tiktok: return "play.square.stack.fill"
            case .reddit: return "bubble.left.and.text.bubble.right.fill"
            case .youtube: return "play.rectangle.fill"
            case .friend: return "person.2.fill"
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

    enum TrackingStatus: String, CaseIterable {
        case yesConsistently = "Yes, I track consistently"
        case yesNotEnough = "Yes, but not as much as I'd like"
        case no = "No, I don't track yet"

        var icon: String {
            switch self {
            case .yesConsistently: return "checkmark.circle.fill"
            case .yesNotEnough: return "circle.dotted"
            case .no: return "xmark.circle.fill"
            }
        }
    }
}

// MARK: - Onboarding Flow View

struct OnboardingFlowView: View {
    @ObservedObject var manager: MorningProofManager
    @StateObject private var onboardingData = OnboardingData()
    // Use computed property to avoid @MainActor singleton deadlock
    private var authManager: AuthenticationManager { AuthenticationManager.shared }
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

                // Content - ZStack with switch to prevent swipe navigation
                ZStack {
                    Group {
                        switch currentStep {
                        case 0:
                            WelcomeStep(onContinue: nextStep)
                        case 1:
                            GenderStep(data: onboardingData, onContinue: nextStep)
                        case 2:
                            NameStep(data: onboardingData, onContinue: nextStep)
                        case 3:
                            HeardAboutStep(data: onboardingData, onContinue: nextStep)
                        case 4:
                            TrackingQuestionStep(data: onboardingData, onContinue: nextStep)
                        case 5:
                            TrackingComparisonStep(trackingStatus: onboardingData.trackingStatus, onContinue: nextStep)
                        case 6:
                            PrimaryGoalStep(data: onboardingData, onContinue: nextStep)
                        case 7:
                            GainTwiceAnimationStep(onContinue: nextStep)
                        case 8:
                            ObstaclesStep(data: onboardingData, onContinue: nextStep)
                        case 9:
                            DesiredOutcomeStep(data: onboardingData, onContinue: nextStep)
                        case 10:
                            HealthConnectStep(data: onboardingData, onContinue: nextStep)
                        case 11:
                            RatingStep(onContinue: nextStep)
                        case 12:
                            NotificationStep(data: onboardingData, onContinue: nextStep)
                        case 13:
                            LoadingPlanStep(userName: onboardingData.userName, onComplete: nextStep)
                        case 14:
                            CustomPlanStep(
                                data: onboardingData,
                                manager: manager,
                                onComplete: completeOnboarding
                            )
                        default:
                            EmptyView()
                        }
                    }
                }
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
    // Use computed property to avoid @MainActor singleton deadlock
    private var authManager: AuthenticationManager { AuthenticationManager.shared }
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

// MARK: - Step 3: Name

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
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("We'll use this to personalize your experience")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.sm) {
                TextField("", text: $data.userName, prompt: Text("First name").foregroundColor(MPColors.textTertiary))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(MPSpacing.xl)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)
                    .mpShadow(.small)
                    .focused($isNameFocused)

                // Privacy note
                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Stored locally. Never shared.")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(MPColors.textMuted)
                .padding(.top, MPSpacing.xs)
            }
            .padding(.horizontal, MPSpacing.xxxl)

            Spacer()

            VStack(spacing: MPSpacing.md) {
                MPButton(
                    title: data.userName.isEmpty ? "Skip" : "Continue",
                    style: .primary
                ) {
                    isNameFocused = false
                    onContinue()
                }

                if data.userName.isEmpty {
                    Text("You can add your name later in settings")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.textTertiary)
                }
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
                ForEach(OnboardingData.TrackingStatus.allCases, id: \.rawValue) { status in
                    OnboardingOptionButton(
                        title: status.rawValue,
                        icon: status.icon,
                        isSelected: data.trackingStatus == status
                    ) {
                        data.trackingStatus = status
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

// MARK: - Step 6: Tracking Comparison Animation

struct TrackingComparisonStep: View {
    let trackingStatus: OnboardingData.TrackingStatus
    let onContinue: () -> Void

    @State private var showHeroStat = false
    @State private var showComparison = false
    @State private var showPills = false
    @State private var heroProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl)

            // Header
            Text("The Research Is Clear")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(MPColors.textPrimary)
                .opacity(showHeroStat ? 1 : 0)

            Spacer().frame(height: MPSpacing.sm)

            Text("People who track their habits")
                .font(MPFont.bodyLarge())
                .foregroundColor(MPColors.textSecondary)
                .opacity(showHeroStat ? 1 : 0)

            Spacer().frame(height: MPSpacing.xxxl)

            // Hero stat card
            VStack(spacing: MPSpacing.lg) {
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(MPColors.progressBg, lineWidth: 12)
                        .frame(width: 140, height: 140)

                    // Progress ring with gradient
                    Circle()
                        .trim(from: 0, to: heroProgress)
                        .stroke(
                            LinearGradient(
                                colors: [MPColors.primary, MPColors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))

                    // Percentage text
                    VStack(spacing: 0) {
                        Text("\(Int(heroProgress * 100))%")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(MPColors.textPrimary)
                        Text("success rate")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(MPColors.textSecondary)
                    }
                }

                // Comparison text
                Text("vs 35% who don't track")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MPColors.textTertiary)
                    .opacity(showComparison ? 1 : 0)
            }
            .padding(MPSpacing.xxl)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.xl)
                    .stroke(
                        LinearGradient(
                            colors: [MPColors.primary.opacity(0.3), MPColors.accent.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .mpShadow(.large)
            .padding(.horizontal, MPSpacing.xxl)

            Spacer().frame(height: MPSpacing.xxl)

            // Research citation
            HStack(spacing: MPSpacing.xs) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundColor(MPColors.primary)
                Text("Dominican University Study, 267 participants")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(MPColors.textTertiary)
            }
            .opacity(showComparison ? 1 : 0)

            Spacer().frame(height: MPSpacing.xxl)

            // Supporting stats pills
            HStack(spacing: MPSpacing.sm) {
                StatPill(value: "42%", label: "more likely", icon: "arrow.up.right")
                    .opacity(showPills ? 1 : 0)
                    .offset(y: showPills ? 0 : 10)

                StatPill(value: "2.2x", label: "better results", icon: "chart.line.uptrend.xyaxis")
                    .opacity(showPills ? 1 : 0)
                    .offset(y: showPills ? 0 : 10)

                StatPill(value: "95%", label: "w/ accountability", icon: "person.2.fill")
                    .opacity(showPills ? 1 : 0)
                    .offset(y: showPills ? 0 : 10)
            }
            .padding(.horizontal, MPSpacing.lg)

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            // Staggered animations
            withAnimation(.easeOut(duration: 0.5)) {
                showHeroStat = true
            }
            withAnimation(.easeOut(duration: 1.5).delay(0.3)) {
                heroProgress = 0.76
            }
            withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
                showComparison = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.5)) {
                showPills = true
            }
        }
    }
}

// MARK: - Supporting Stat Pill Component

struct StatPill: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: MPSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(MPColors.accent)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(MPColors.textPrimary)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(MPColors.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.md)
        .padding(.horizontal, MPSpacing.sm)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.md)
        .mpShadow(.small)
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

// MARK: - Step 8: Morning Advantage Animation

struct GainTwiceAnimationStep: View {
    let onContinue: () -> Void

    @State private var showHeader = false
    @State private var showMultiplier = false
    @State private var animatedValue: Double = 1.0
    @State private var showCards = false
    @State private var showCitation = false
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl)

            // Header
            VStack(spacing: MPSpacing.sm) {
                Text("The Morning Advantage")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("Morning routine builders are")
                    .font(MPFont.bodyLarge())
                    .foregroundColor(MPColors.textSecondary)
            }
            .opacity(showHeader ? 1 : 0)
            .offset(y: showHeader ? 0 : -10)

            Spacer().frame(height: MPSpacing.xxl)

            // Animated multiplier
            ZStack {
                // Subtle pulse rings
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .stroke(MPColors.accent.opacity(0.15 - Double(index) * 0.05), lineWidth: 1.5)
                        .frame(width: CGFloat(160 + index * 30), height: CGFloat(160 + index * 30))
                        .scaleEffect(pulseAnimation ? 1.15 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.8)
                        .animation(
                            .easeOut(duration: 2.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.4),
                            value: pulseAnimation
                        )
                }

                // Main circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MPColors.primary, MPColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 130, height: 130)
                    .mpShadow(.large)

                // Animated number
                VStack(spacing: 0) {
                    Text(String(format: "%.1fx", animatedValue))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    Text("more likely")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .scaleEffect(showMultiplier ? 1 : 0.5)
                .opacity(showMultiplier ? 1 : 0)
            }

            Spacer().frame(height: MPSpacing.xxl)

            // Supporting evidence cards
            VStack(spacing: MPSpacing.md) {
                EvidenceCard(
                    stat: "78%",
                    description: "of successful habit-formers complete key habits before 9 AM",
                    icon: "sunrise.fill",
                    iconColor: MPColors.accent
                )
                .opacity(showCards ? 1 : 0)
                .offset(x: showCards ? 0 : -20)

                EvidenceCard(
                    stat: "92%",
                    description: "with morning routines report feeling highly productive",
                    icon: "bolt.fill",
                    iconColor: MPColors.accentGold
                )
                .opacity(showCards ? 1 : 0)
                .offset(x: showCards ? 0 : 20)
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer().frame(height: MPSpacing.lg)

            // Research citation
            HStack(spacing: MPSpacing.xs) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 11))
                    .foregroundColor(MPColors.textMuted)
                Text("2025 Executive Performance Study")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(MPColors.textMuted)
            }
            .opacity(showCitation ? 1 : 0)

            Spacer()

            MPButton(title: "Build My Routine", style: .primary, icon: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            // Staggered entrance animations
            withAnimation(.easeOut(duration: 0.5)) {
                showHeader = true
            }

            pulseAnimation = true

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                showMultiplier = true
            }

            // Animate the number from 1.0 to 3.2
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 1.2)) {
                    animatedValue = 3.2
                }
            }

            withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
                showCards = true
            }

            withAnimation(.easeOut(duration: 0.3).delay(1.4)) {
                showCitation = true
            }
        }
    }
}

// MARK: - Evidence Card Component

struct EvidenceCard: View {
    let stat: String
    let description: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(stat)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(MPSpacing.md)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
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

                Text("Select all that apply")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MPSpacing.md) {
                ForEach(OnboardingData.DesiredOutcome.allCases, id: \.rawValue) { outcome in
                    OnboardingGridButton(
                        title: outcome.rawValue,
                        icon: outcome.icon,
                        isSelected: data.desiredOutcomes.contains(outcome)
                    ) {
                        if data.desiredOutcomes.contains(outcome) {
                            data.desiredOutcomes.remove(outcome)
                        } else {
                            data.desiredOutcomes.insert(outcome)
                        }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(title: "Continue", style: .primary, isDisabled: data.desiredOutcomes.isEmpty) {
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
    // Use computed property to avoid @MainActor singleton deadlock
    private var healthKit: HealthKitManager { HealthKitManager.shared }

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
    // Use computed property to avoid @MainActor singleton deadlock
    private var notificationManager: NotificationManager { NotificationManager.shared }

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
    @State private var currentPhase = 0
    @State private var completedSteps: Set<Int> = []
    @State private var isPulsing = false
    @State private var showSocialProof = false
    @State private var userCount: Int = 0
    @State private var orbitRotation: Double = 0

    private var phases: [(title: String, icon: String)] {
        let name = userName.isEmpty ? "" : " for \(userName)"
        return [
            (title: "Reviewing your responses", icon: "doc.text.magnifyingglass"),
            (title: "Analyzing your goals", icon: "target"),
            (title: "Selecting optimal habits\(name)", icon: "brain.head.profile"),
            (title: "Calibrating verification methods", icon: "checkmark.shield"),
            (title: "Finalizing your custom plan", icon: "checkmark.seal")
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            // Header
            VStack(spacing: MPSpacing.sm) {
                Text("Creating Your Plan")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                if !userName.isEmpty {
                    Text("Hang tight, \(userName)")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textSecondary)
                } else {
                    Text("This won't take long")
                        .font(MPFont.bodyMedium())
                        .foregroundColor(MPColors.textSecondary)
                }
            }

            Spacer().frame(height: MPSpacing.xxxl)

            // Progress circle with pulse
            ZStack {
                // Pulse effect
                Circle()
                    .fill(MPColors.primary.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .scaleEffect(isPulsing ? 1.15 : 1.0)
                    .opacity(isPulsing ? 0.3 : 0.6)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)

                // Orbiting particles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(MPColors.accent)
                        .frame(width: 6, height: 6)
                        .offset(y: -85)
                        .rotationEffect(.degrees(orbitRotation + Double(index * 120)))
                        .opacity(0.6)
                }

                // Background ring
                Circle()
                    .stroke(MPColors.progressBg, lineWidth: 10)
                    .frame(width: 120, height: 120)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [MPColors.primary, MPColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                // Percentage
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)
                        .contentTransition(.numericText())
                }
            }

            Spacer().frame(height: MPSpacing.xxxl)

            // Phase checklist
            VStack(spacing: MPSpacing.md) {
                ForEach(0..<phases.count, id: \.self) { index in
                    LoadingPhaseRow(
                        title: phases[index].title,
                        icon: phases[index].icon,
                        isActive: currentPhase == index,
                        isCompleted: completedSteps.contains(index)
                    )
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer().frame(height: MPSpacing.xxl)

            // Social proof counter
            HStack(spacing: MPSpacing.sm) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 14))
                    .foregroundColor(MPColors.accent)

                Text("\(userCount.formatted()) people built their routine this week")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textSecondary)
            }
            .opacity(showSocialProof ? 1 : 0)
            .offset(y: showSocialProof ? 0 : 10)

            Spacer()
        }
        .onAppear {
            startLoading()
        }
    }

    private func startLoading() {
        isPulsing = true

        // Start orbit animation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            orbitRotation = 360
        }

        // Total duration: ~5.5 seconds
        // Progress animation over 5 seconds
        withAnimation(.easeOut(duration: 5.0)) {
            progress = 1.0
        }

        // Show social proof after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showSocialProof = true
            }
            animateCounter(to: 2847)
        }

        // Phase transitions (5 phases over ~5 seconds = 1 second each)
        for i in 0..<phases.count {
            // Set phase active
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPhase = i
                }
            }

            // Mark previous phase complete
            if i > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.0) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        _ = completedSteps.insert(i - 1)
                    }
                }
            }
        }

        // Mark last phase complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                _ = completedSteps.insert(phases.count - 1)
            }
        }

        // Complete and transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            onComplete()
        }
    }

    private func animateCounter(to target: Int) {
        let duration: Double = 1.5
        let steps = 30
        let interval = duration / Double(steps)
        let increment = target / steps

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                withAnimation(.easeOut(duration: 0.05)) {
                    userCount = min(increment * i, target)
                }
            }
        }
    }
}

// MARK: - Loading Phase Row

struct LoadingPhaseRow: View {
    let title: String
    let icon: String
    let isActive: Bool
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(isCompleted ? MPColors.success : (isActive ? MPColors.primary.opacity(0.15) : MPColors.surfaceSecondary))
                    .frame(width: 32, height: 32)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else if isActive {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(MPColors.primary)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.textTertiary)
                }
            }

            // Title
            Text(title)
                .font(.system(size: 15, weight: isActive || isCompleted ? .medium : .regular))
                .foregroundColor(isActive || isCompleted ? MPColors.textPrimary : MPColors.textTertiary)

            Spacer()
        }
        .padding(.vertical, MPSpacing.xs)
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

        // Add based on all selected desired outcomes
        for outcome in data.desiredOutcomes {
            switch outcome {
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
        }

        // Add some default benefits to round out the chips
        if chips.count < 6 {
            chips.append(("Consistency", "checkmark.circle.fill", MPColors.success))
        }
        if chips.count < 6 {
            chips.append(("Accountability", "person.2.fill", MPColors.accent))
        }
        if chips.count < 6 {
            chips.append(("Better Sleep", "moon.zzz.fill", MPColors.primary))
        }
        if chips.count < 6 {
            chips.append(("Morning Wins", "trophy.fill", MPColors.accentGold))
        }

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

                    Spacer().frame(height: MPSpacing.xl)

                    // "Hands-free verification" highlight
                    HStack(spacing: MPSpacing.sm) {
                        Image(systemName: "hand.raised.slash.fill")
                            .font(.system(size: 14))
                            .foregroundColor(MPColors.accent)
                        Text("Hands-free verification for most habits")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.textSecondary)
                    }
                    .padding(.horizontal, MPSpacing.lg)
                    .padding(.vertical, MPSpacing.md)
                    .background(MPColors.accentLight.opacity(0.3))
                    .cornerRadius(MPRadius.full)
                    .opacity(animateContent ? 1 : 0)

                    Spacer().frame(height: MPSpacing.xxl)

                    // Your Routine section header
                    HStack {
                        Text("Your Recommended Routine")
                            .font(MPFont.headingSmall())
                            .foregroundColor(MPColors.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, MPSpacing.xl)
                    .opacity(animateChips ? 1 : 0)

                    Spacer().frame(height: MPSpacing.md)

                    // Recommended habits
                    VStack(spacing: MPSpacing.md) {
                        RecommendedHabitCard(habitType: .madeBed, isHighlighted: true)
                            .opacity(animateChips ? 1 : 0)
                            .offset(x: animateChips ? 0 : -20)

                        RecommendedHabitCard(habitType: .morningSteps, isHighlighted: true)
                            .opacity(animateChips ? 1 : 0)
                            .offset(x: animateChips ? 0 : 20)

                        RecommendedHabitCard(habitType: .sleepDuration, isHighlighted: false)
                            .opacity(animateChips ? 1 : 0)
                            .offset(x: animateChips ? 0 : -20)

                        RecommendedHabitCard(habitType: .morningWorkout, isHighlighted: false)
                            .opacity(animateChips ? 1 : 0)
                            .offset(x: animateChips ? 0 : 20)
                    }
                    .padding(.horizontal, MPSpacing.xl)

                    Spacer().frame(height: MPSpacing.xxl)

                    // Social proof
                    VStack(spacing: MPSpacing.md) {
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(MPColors.accentGold)
                            }
                        }
                        Text("Join 10,000+ morning achievers")
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary)
                    }
                    .opacity(animateChips ? 1 : 0)

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

// MARK: - Recommended Habit Card

struct RecommendedHabitCard: View {
    let habitType: HabitType
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(isHighlighted ? MPColors.primaryLight : MPColors.surfaceSecondary)
                    .frame(width: 50, height: 50)

                Image(systemName: habitType.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isHighlighted ? MPColors.primary : MPColors.textTertiary)
            }

            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text(habitType.displayName)
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.textPrimary)

                // Verification badge
                HStack(spacing: 4) {
                    Image(systemName: verificationBadgeIcon)
                        .font(.system(size: 10))
                    Text(habitType.tier.description)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(verificationBadgeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(verificationBadgeColor.opacity(0.1))
                .cornerRadius(MPRadius.sm)
            }

            Spacer()

            // Checkmark for included habits
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(MPColors.success)
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .stroke(isHighlighted ? MPColors.primary.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .mpShadow(.small)
    }

    private var verificationBadgeIcon: String {
        switch habitType.tier {
        case .aiVerified: return "sparkles"
        case .autoTracked: return "arrow.triangle.2.circlepath"
        case .honorSystem: return "hand.raised.fill"
        }
    }

    private var verificationBadgeColor: Color {
        switch habitType.tier {
        case .aiVerified: return MPColors.accent
        case .autoTracked: return MPColors.primary
        case .honorSystem: return MPColors.textTertiary
        }
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
            VStack(spacing: MPSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(isSelected ? MPColors.primaryLight : MPColors.surfaceSecondary)
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? MPColors.primary : MPColors.textTertiary)
                }

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 95)
            .padding(.vertical, MPSpacing.md)
            .padding(.horizontal, MPSpacing.sm)
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

import SwiftUI
import StoreKit
import AuthenticationServices

// MARK: - Onboarding Data Model

class OnboardingData: ObservableObject {
    @Published var userName: String = ""
    @Published var gender: Gender? = nil
    @Published var morningStruggle: MorningStruggle? = nil
    @Published var trackingStatus: TrackingStatus? = nil
    @Published var primaryGoal: PrimaryGoal? = nil
    @Published var obstacles: Set<Obstacle> = []
    @Published var desiredOutcomes: Set<DesiredOutcome> = []
    @Published var healthConnected: Bool = false
    @Published var notificationsEnabled: Bool = false
    @Published var selectedHabits: Set<HabitType> = []

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

    enum MorningStruggle: String, CaseIterable {
        case cantWakeUp = "I can't wake up on time"
        case wasteScrolling = "I waste mornings scrolling"
        case feelGroggy = "I feel groggy until noon"
        case lackConsistency = "I lack consistency"
        case noRoutine = "I don't have a routine"
        case hitSnooze = "I hit snooze too much"

        var icon: String {
            switch self {
            case .cantWakeUp: return "alarm.fill"
            case .wasteScrolling: return "iphone"
            case .lackConsistency: return "arrow.triangle.2.circlepath"
            case .feelGroggy: return "moon.zzz.fill"
            case .noRoutine: return "list.bullet.clipboard"
            case .hitSnooze: return "hand.tap.fill"
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

// MARK: - Onboarding Flow View (19 Steps)

struct OnboardingFlowView: View {
    @ObservedObject var manager: MorningProofManager
    @StateObject private var onboardingData = OnboardingData()
    private var authManager: AuthenticationManager { AuthenticationManager.shared }
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    @State private var currentStep = 0

    private let totalSteps = 19

    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar (show for steps 2-18, not welcome or paywall)
                if currentStep > 0 && currentStep < totalSteps - 1 {
                    OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps - 2)
                        .padding(.horizontal, MPSpacing.xl)
                        .padding(.top, MPSpacing.md)
                }

                // Content
                ZStack {
                    Group {
                        switch currentStep {
                        // Phase 1: Hook & Personalization
                        case 0: WelcomeHeroStep(onContinue: nextStep)
                        case 1: NameStep(data: onboardingData, onContinue: nextStep)
                        case 2: GenderStep(data: onboardingData, onContinue: nextStep)
                        case 3: MorningStruggleStep(data: onboardingData, onContinue: nextStep)

                        // Phase 2: Problem Agitation & Social Proof
                        case 4: ProblemStatisticsStep(onContinue: nextStep)
                        case 5: YouAreNotAloneStep(onContinue: nextStep)
                        case 6: SuccessStoriesStep(onContinue: nextStep)
                        case 7: TrackingComparisonStep(onContinue: nextStep)
                        case 8: MorningAdvantageStep(onContinue: nextStep)

                        // Phase 3: Solution & Investment
                        case 9: HowItWorksStep(onContinue: nextStep)
                        case 10: AIVerificationShowcaseStep(onContinue: nextStep)
                        case 11: DesiredOutcomeStep(data: onboardingData, onContinue: nextStep)
                        case 12: ObstaclesStep(data: onboardingData, onContinue: nextStep)
                        case 13: PermissionsStep(data: onboardingData, onContinue: nextStep)

                        // Phase 4: Habits & Paywall
                        case 14: OptionalRatingStep(onContinue: nextStep)
                        case 15: AnalyzingStep(userName: onboardingData.userName, onComplete: nextStep)
                        case 16: YourHabitsStep(data: onboardingData, onContinue: nextStep)
                        case 17: SocialProofFinalStep(onContinue: nextStep)
                        case 18: HardPaywallStep(
                            subscriptionManager: subscriptionManager,
                            onSubscribe: completeOnboarding,
                            onSkip: completeOnboarding // Testing only - remove before release
                        )

                        default: EmptyView()
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
                let firstName = fullName.components(separatedBy: " ").first ?? fullName
                onboardingData.userName = firstName
            }
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }

    private func completeOnboarding() {
        manager.settings.userName = onboardingData.userName

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
                RoundedRectangle(cornerRadius: 3)
                    .fill(MPColors.progressBg)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [MPColors.primary, MPColors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Step 1: Welcome Hero

struct WelcomeHeroStep: View {
    let onContinue: () -> Void
    private var authManager: AuthenticationManager { AuthenticationManager.shared }
    @State private var animateContent = false
    @State private var animateOrb = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App branding
            VStack(spacing: MPSpacing.lg) {
                // Animated orb with sunrise
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    MPColors.accentLight.opacity(0.6),
                                    MPColors.accent.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(animateOrb ? 1.1 : 1.0)

                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [MPColors.accent, MPColors.accentGold],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: animateOrb ? -4 : 4)
                }
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateOrb)

                VStack(spacing: MPSpacing.sm) {
                    Text("Earn Your Morning")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Build daily habits that stick")
                        .font(.system(size: 17))
                        .foregroundColor(MPColors.textSecondary)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            Spacer()

            // Sign-in options
            VStack(spacing: MPSpacing.md) {
                SignInWithAppleButton(.signIn) { request in
                    authManager.handleAppleSignInRequest(request)
                } onCompletion: { result in
                    authManager.handleAppleSignInCompletion(result) { success in
                        if success { onContinue() }
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .cornerRadius(MPRadius.lg)

                Button {
                    authManager.signInWithGoogle { success in
                        if success { onContinue() }
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
                    .frame(height: 52)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: MPRadius.lg)
                            .stroke(MPColors.border, lineWidth: 1)
                    )
                }

                HStack {
                    Rectangle().fill(MPColors.divider).frame(height: 1)
                    Text("or")
                        .font(.system(size: 13))
                        .foregroundColor(MPColors.textTertiary)
                        .padding(.horizontal, MPSpacing.md)
                    Rectangle().fill(MPColors.divider).frame(height: 1)
                }
                .padding(.vertical, MPSpacing.xs)

                Button {
                    authManager.continueAnonymously()
                    onContinue()
                } label: {
                    Text("Continue without account")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MPColors.primary)
                }
            }
            .padding(.horizontal, MPSpacing.xl)
            .padding(.bottom, 50)
            .opacity(animateContent ? 1 : 0)

            if let error = authManager.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.bottom, MPSpacing.md)
            }
        }
        .onAppear {
            animateOrb = true
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Step 2: Name

struct NameStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.lg) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(MPColors.primary)

                Text("Let's make this personal")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("What should we call you?")
                    .font(.system(size: 16))
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

                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Stored locally. Never shared.")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(MPColors.textMuted)
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
                    Text("You can add your name later")
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

// MARK: - Step 3: Gender

struct GenderStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.md) {
                Text("What's your gender?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("This helps us personalize your experience")
                    .font(.system(size: 16))
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

            VStack(spacing: MPSpacing.md) {
                MPButton(title: "Continue", style: .primary, isDisabled: data.gender == nil) {
                    onContinue()
                }

                Button {
                    data.gender = .preferNotToSay
                    onContinue()
                } label: {
                    Text("Skip")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textTertiary)
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 4: Morning Struggle

struct MorningStruggleStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.md) {
                Text("What's your biggest\nmorning struggle?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("We'll help you overcome it")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MPSpacing.md) {
                ForEach(OnboardingData.MorningStruggle.allCases, id: \.rawValue) { struggle in
                    OnboardingGridButton(
                        title: struggle.rawValue,
                        icon: struggle.icon,
                        isSelected: data.morningStruggle == struggle
                    ) {
                        data.morningStruggle = struggle
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(title: "Continue", style: .primary, isDisabled: data.morningStruggle == nil) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 5: Problem Statistics

struct ProblemStatisticsStep: View {
    let onContinue: () -> Void
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl)

            Text("Here's the truth")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(MPColors.textTertiary)
                .opacity(showContent ? 1 : 0)

            Spacer().frame(height: MPSpacing.xl)

            StatisticHeroCard(
                value: "73%",
                label: "of people abandon their morning\nroutine within 2 weeks",
                citation: "American Psychological Association, 2023"
            )

            Spacer().frame(height: MPSpacing.xxl)

            // Supporting stats
            HStack(spacing: MPSpacing.md) {
                StatPillView(value: "3.5", label: "avg. snoozes", icon: "alarm.fill")
                StatPillView(value: "47m", label: "avg. scrolling", icon: "iphone")
                StatPillView(value: "8%", label: "succeed alone", icon: "person.fill")
            }
            .padding(.horizontal, MPSpacing.lg)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            Spacer()

            MPButton(title: "What can I do?", style: .primary, icon: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Step 6: You Are Not Alone

struct YouAreNotAloneStep: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var scrollOffset: CGFloat = 0

    private let testimonials = SampleTestimonials.all

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.md) {
                Text("You're not alone")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("Thousands have transformed their mornings")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }
            .opacity(showContent ? 1 : 0)

            Spacer().frame(height: MPSpacing.xxl)

            // Continuously scrolling testimonial carousel
            GeometryReader { geometry in
                let cardWidth: CGFloat = geometry.size.width - 60

                HStack(spacing: MPSpacing.md) {
                    // Duplicate testimonials for seamless loop
                    ForEach(0..<testimonials.count * 2, id: \.self) { index in
                        let testimonial = testimonials[index % testimonials.count]
                        TestimonialCard(
                            name: testimonial.name,
                            age: testimonial.age,
                            location: testimonial.location,
                            quote: testimonial.quote,
                            streakDays: testimonial.streakDays,
                            avatarIndex: index % testimonials.count
                        )
                        .frame(width: cardWidth)
                    }
                }
                .offset(x: scrollOffset)
                .onAppear {
                    let singleSetWidth = cardWidth * CGFloat(testimonials.count) + CGFloat(testimonials.count) * MPSpacing.md
                    withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                        scrollOffset = -singleSetWidth
                    }
                }
            }
            .frame(height: 200)
            .clipped()
            .opacity(showContent ? 1 : 0)

            Spacer().frame(height: MPSpacing.xl)

            // Rating stat
            VStack(spacing: MPSpacing.sm) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                            .foregroundColor(MPColors.accentGold)
                    }
                }
                Text("4.9 avg. rating from beta testers")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MPColors.textTertiary)
            }
            .opacity(showContent ? 1 : 0)

            Spacer()

            MPButton(title: "See the results", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Step 7: Success Stories

struct SuccessStoriesStep: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var showStats = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.md) {
                Text("What 30 days looks like")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("Based on tracked user data")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }
            .opacity(showContent ? 1 : 0)

            Spacer().frame(height: MPSpacing.xxl)

            // Before/After comparison
            BeforeAfterCard(
                beforeTitle: "Week 1",
                beforeItems: ["Hit snooze 3+ times", "Rush through morning", "Feel groggy until noon"],
                afterTitle: "Week 4",
                afterItems: ["Wake up on first alarm", "Calm, productive mornings", "Energized by 8 AM"]
            )
            .padding(.horizontal, MPSpacing.xl)
            .opacity(showContent ? 1 : 0)

            Spacer().frame(height: MPSpacing.xl)

            // Success metrics
            VStack(spacing: MPSpacing.lg) {
                HStack(spacing: MPSpacing.lg) {
                    TransformationStatCard(
                        value: "89%",
                        label: "reduced snoozing",
                        icon: "alarm.fill",
                        color: MPColors.accent
                    )
                    TransformationStatCard(
                        value: "2.4x",
                        label: "longer streaks",
                        icon: "flame.fill",
                        color: MPColors.primary
                    )
                }
                HStack(spacing: MPSpacing.lg) {
                    TransformationStatCard(
                        value: "67%",
                        label: "feel more productive",
                        icon: "bolt.fill",
                        color: MPColors.accentGold
                    )
                    TransformationStatCard(
                        value: "94%",
                        label: "still active at day 30",
                        icon: "person.fill.checkmark",
                        color: MPColors.success
                    )
                }
            }
            .padding(.horizontal, MPSpacing.xl)
            .opacity(showStats ? 1 : 0)
            .offset(y: showStats ? 0 : 20)

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showStats = true
            }
        }
    }
}

struct TransformationStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: MPSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(MPColors.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(MPColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.md)
        .mpShadow(.small)
    }
}

struct MilestoneCard: View {
    let day: String
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: MPSpacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            Text(day)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(MPColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.md)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.md)
        .mpShadow(.small)
    }
}

// MARK: - Step 8: Tracking Comparison

struct TrackingComparisonStep: View {
    let onContinue: () -> Void
    @State private var showPills = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl)

            Text("The Research Is Clear")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(MPColors.textPrimary)

            Spacer().frame(height: MPSpacing.sm)

            Text("People who track their habits")
                .font(.system(size: 16))
                .foregroundColor(MPColors.textSecondary)

            Spacer().frame(height: MPSpacing.xxl)

            StatisticRingCard(
                percentage: 76,
                label: "success rate",
                comparisonText: "vs 35% who don't track"
            )
            .padding(.horizontal, MPSpacing.xxl)

            Spacer().frame(height: MPSpacing.xxl)

            // Research citation
            HStack(spacing: MPSpacing.xs) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundColor(MPColors.primary)
                Text("Journal of Behavioral Psychology, 2024")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            // Supporting pills
            HStack(spacing: MPSpacing.sm) {
                StatPillView(value: "42%", label: "hit their goals", icon: "target")
                StatPillView(value: "2.2x", label: "longer streaks", icon: "flame.fill")
                StatPillView(value: "91%", label: "w/ accountability", icon: "person.2.fill")
            }
            .padding(.horizontal, MPSpacing.lg)
            .opacity(showPills ? 1 : 0)
            .offset(y: showPills ? 0 : 10)

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.5)) {
                showPills = true
            }
        }
    }
}

// MARK: - Step 9: Morning Advantage

struct MorningAdvantageStep: View {
    let onContinue: () -> Void
    @State private var showHeader = false
    @State private var showMultiplier = false
    @State private var animatedValue: Double = 1.0
    @State private var showCards = false
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.sm) {
                Text("The Morning Advantage")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("People with morning routines are")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }
            .opacity(showHeader ? 1 : 0)

            Spacer().frame(height: MPSpacing.xxl)

            // Animated multiplier
            ZStack {
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .stroke(MPColors.accent.opacity(0.15 - Double(index) * 0.05), lineWidth: 1.5)
                        .frame(width: CGFloat(160 + index * 30), height: CGFloat(160 + index * 30))
                        .scaleEffect(pulseAnimation ? 1.15 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.8)
                        .animation(
                            .easeOut(duration: 2.5).repeatForever(autoreverses: false).delay(Double(index) * 0.4),
                            value: pulseAnimation
                        )
                }

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

                VStack(spacing: 0) {
                    Text(String(format: "%.1fx", animatedValue))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    Text("more productive")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .scaleEffect(showMultiplier ? 1 : 0.5)
                .opacity(showMultiplier ? 1 : 0)
            }

            Spacer().frame(height: MPSpacing.xxl)

            // Evidence cards
            VStack(spacing: MPSpacing.md) {
                EvidenceCard(
                    stat: "78%",
                    description: "complete key habits before 9 AM",
                    icon: "sunrise.fill",
                    iconColor: MPColors.accent
                )

                EvidenceCard(
                    stat: "92%",
                    description: "report feeling highly productive",
                    icon: "bolt.fill",
                    iconColor: MPColors.accentGold
                )
            }
            .padding(.horizontal, MPSpacing.xl)
            .opacity(showCards ? 1 : 0)

            Spacer().frame(height: MPSpacing.md)

            HStack(spacing: MPSpacing.xs) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 11))
                Text("2025 Executive Performance Study")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(MPColors.textMuted)
            .opacity(showCards ? 1 : 0)

            Spacer()

            MPButton(title: "Build My Routine", style: .primary, icon: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { showHeader = true }
            pulseAnimation = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) { showMultiplier = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 1.2)) { animatedValue = 3.2 }
            }
            withAnimation(.easeOut(duration: 0.5).delay(1.0)) { showCards = true }
        }
    }
}

// MARK: - Evidence Card

struct EvidenceCard: View {
    let stat: String
    let description: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(stat)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer()
        }
        .padding(MPSpacing.md)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }
}

// MARK: - Step 10: How It Works

struct HowItWorksStep: View {
    let onContinue: () -> Void
    @State private var showSteps = [false, false, false]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.md) {
                Text("MorningProof is different")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("Real accountability that works")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.xl) {
                HowItWorksRow(
                    number: "1",
                    title: "Set your habits",
                    description: "Choose morning habits to track",
                    icon: "list.bullet.clipboard.fill",
                    isVisible: showSteps[0]
                )

                HowItWorksRow(
                    number: "2",
                    title: "Prove them",
                    description: "AI verifies you actually did it",
                    icon: "camera.viewfinder",
                    isVisible: showSteps[1]
                )

                HowItWorksRow(
                    number: "3",
                    title: "Build your streak",
                    description: "Stay consistent, see progress",
                    icon: "flame.fill",
                    isVisible: showSteps[2]
                )
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer().frame(height: MPSpacing.xxl)

            Text("No more lying to yourself")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(MPColors.accent)
                .opacity(showSteps[2] ? 1 : 0)

            Spacer()

            MPButton(title: "See it in action", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            for i in 0..<3 {
                withAnimation(.easeOut(duration: 0.5).delay(Double(i) * 0.3)) {
                    showSteps[i] = true
                }
            }
        }
    }
}

struct HowItWorksRow: View {
    let number: String
    let title: String
    let description: String
    let icon: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            ZStack {
                Circle()
                    .fill(MPColors.primaryLight)
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(MPColors.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer()

            Text(number)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(MPColors.textMuted)
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
    }
}

// MARK: - Step 11: AI Verification Showcase

struct AIVerificationShowcaseStep: View {
    let onContinue: () -> Void
    @State private var showPhone = false
    @State private var showScan = false
    @State private var showScore = false
    @State private var scanProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.md) {
                Text("AI-Powered Verification")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("Snap a photo, we'll verify it")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            // Phone mockup
            ZStack {
                // Phone frame
                RoundedRectangle(cornerRadius: 30)
                    .fill(MPColors.surface)
                    .frame(width: 220, height: 340)
                    .mpShadow(.large)

                // Screen content
                VStack(spacing: MPSpacing.md) {
                    // Bed image placeholder
                    RoundedRectangle(cornerRadius: MPRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [MPColors.surfaceSecondary, MPColors.progressBg],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 180, height: 140)
                        .overlay(
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 50))
                                .foregroundColor(MPColors.textMuted)
                        )

                    // Scan line animation
                    if showScan && !showScore {
                        Rectangle()
                            .fill(MPColors.accent)
                            .frame(width: 180, height: 2)
                            .offset(y: -70 + (scanProgress * 140))
                    }

                    // Score display
                    if showScore {
                        VStack(spacing: MPSpacing.sm) {
                            HStack(spacing: MPSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(MPColors.success)
                                Text("Verified!")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(MPColors.success)
                            }

                            HStack(spacing: MPSpacing.xs) {
                                Text("Bed Score:")
                                    .font(.system(size: 14))
                                    .foregroundColor(MPColors.textSecondary)
                                Text("9/10")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(MPColors.primary)
                            }

                            Text("Great job making your bed!")
                                .font(.system(size: 12))
                                .foregroundColor(MPColors.textTertiary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 200, height: 300)
            }
            .scaleEffect(showPhone ? 1 : 0.8)
            .opacity(showPhone ? 1 : 0)

            Spacer().frame(height: MPSpacing.xxl)

            // Features
            HStack(spacing: MPSpacing.xl) {
                VStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(MPColors.accent)
                    Text("Instant")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MPColors.textSecondary)
                }
                VStack(spacing: 4) {
                    Image(systemName: "hand.raised.slash.fill")
                        .foregroundColor(MPColors.accent)
                    Text("Hands-free")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MPColors.textSecondary)
                }
                VStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(MPColors.accent)
                    Text("Private")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MPColors.textSecondary)
                }
            }
            .opacity(showScore ? 1 : 0)

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showPhone = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showScan = true
                withAnimation(.linear(duration: 1.5)) {
                    scanProgress = 1.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showScore = true
                }
            }
        }
    }
}

// MARK: - Step 12: Desired Outcome

struct DesiredOutcomeStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    private let popularOutcomes: Set<OnboardingData.DesiredOutcome> = [.moreEnergy, .betterFocus, .selfDiscipline]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.md) {
                Image(systemName: "star.fill")
                    .font(.system(size: 50))
                    .foregroundColor(MPColors.accentGold)

                Text("What would you like\nto accomplish?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Select all that apply")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MPSpacing.md) {
                ForEach(OnboardingData.DesiredOutcome.allCases, id: \.rawValue) { outcome in
                    OnboardingGridButtonWithBadge(
                        title: outcome.rawValue,
                        icon: outcome.icon,
                        isSelected: data.desiredOutcomes.contains(outcome),
                        badge: popularOutcomes.contains(outcome) ? "Popular" : nil
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

// MARK: - Step 13: Obstacles

struct ObstaclesStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var showReassurance = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.md) {
                Text("What's stopping you from\nreaching your goals?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Select all that apply")
                    .font(.system(size: 16))
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
                        if !data.obstacles.isEmpty {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showReassurance = true
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer().frame(height: MPSpacing.lg)

            if showReassurance {
                HStack(spacing: MPSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(MPColors.success)
                    Text("We'll help you overcome this")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MPColors.success)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            MPButton(title: "Continue", style: .primary, isDisabled: data.obstacles.isEmpty) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 14: Permissions (Combined)

struct PermissionsStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    @State private var isRequestingHealth = false
    @State private var isRequestingNotifications = false
    private var healthKit: HealthKitManager { HealthKitManager.shared }
    private var notificationManager: NotificationManager { NotificationManager.shared }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.md) {
                Text("Supercharge your tracking")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("Enable these for the best experience")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.lg) {
                // Health permission card
                PermissionCard(
                    icon: "heart.fill",
                    iconColor: MPColors.error,
                    title: "Apple Health",
                    description: "Auto-track sleep & steps",
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
                    description: "Morning reminders & streak alerts",
                    isEnabled: data.notificationsEnabled,
                    isLoading: isRequestingNotifications
                ) {
                    requestNotifications()
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            VStack(spacing: MPSpacing.md) {
                MPButton(title: "Continue", style: .primary) {
                    onContinue()
                }

                Text("You can change these anytime in Settings")
                    .font(.system(size: 12))
                    .foregroundColor(MPColors.textTertiary)
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
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
}

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
                        Text("Enable")
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

// MARK: - Step 15: Optional Rating

struct OptionalRatingStep: View {
    let onContinue: () -> Void
    @State private var hasRequestedReview = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(MPColors.accentLight)
                    .frame(width: 100, height: 100)

                Image(systemName: "heart.fill")
                    .font(.system(size: 44))
                    .foregroundColor(MPColors.accent)
            }

            Spacer().frame(height: MPSpacing.xxl)

            VStack(spacing: MPSpacing.md) {
                Text("Help us grow")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("Your rating helps others\ndiscover Morning Proof")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: MPSpacing.xxl)

            HStack(spacing: MPSpacing.sm) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 32))
                        .foregroundColor(MPColors.accentGold)
                }
            }

            Spacer()

            VStack(spacing: MPSpacing.md) {
                MPButton(title: "Rate Morning Proof", style: .primary, icon: "star.fill") {
                    requestReview()
                }

                Button {
                    onContinue()
                } label: {
                    Text("Maybe later")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textTertiary)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onContinue()
        }
    }
}

// MARK: - Step 16: Analyzing

struct AnalyzingStep: View {
    let userName: String
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var currentPhase = 0
    @State private var completedSteps: Set<Int> = []
    @State private var isPulsing = false
    @State private var showSocialProof = false
    @State private var userCount: Int = 0

    private var phases: [(title: String, icon: String)] {
        [
            (title: "Analyzing your responses", icon: "doc.text.magnifyingglass"),
            (title: "Identifying your patterns", icon: "brain.head.profile"),
            (title: "Selecting optimal habits", icon: "target"),
            (title: "Building your routine", icon: "checkmark.seal")
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl * 2)

            VStack(spacing: MPSpacing.sm) {
                Text("Creating Your Routine")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                if !userName.isEmpty {
                    Text("Almost there, \(userName)")
                        .font(.system(size: 16))
                        .foregroundColor(MPColors.textSecondary)
                }
            }

            Spacer().frame(height: MPSpacing.xxxl)

            // Progress circle
            ZStack {
                Circle()
                    .fill(MPColors.primary.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)

                Circle()
                    .stroke(MPColors.progressBg, lineWidth: 8)
                    .frame(width: 110, height: 110)

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
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
                    .contentTransition(.numericText())
            }

            Spacer().frame(height: MPSpacing.xxxl)

            // Phase checklist
            VStack(spacing: MPSpacing.md) {
                ForEach(0..<phases.count, id: \.self) { index in
                    AnalyzingPhaseRow(
                        title: phases[index].title,
                        icon: phases[index].icon,
                        isActive: currentPhase == index,
                        isCompleted: completedSteps.contains(index)
                    )
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer().frame(height: MPSpacing.xxl)

            // Social proof
            SocialProofCounter(
                targetNumber: userCount,
                suffix: " people built their routine this week",
                icon: "person.3.fill"
            )
            .opacity(showSocialProof ? 1 : 0)

            Spacer()
        }
        .onAppear {
            startLoading()
        }
    }

    private func startLoading() {
        isPulsing = true

        withAnimation(.easeOut(duration: 4.0)) {
            progress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showSocialProof = true
            }
            animateCounter(to: 2847)
        }

        for i in 0..<phases.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.9) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPhase = i
                }
            }
            if i > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.9) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        _ = completedSteps.insert(i - 1)
                    }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                _ = completedSteps.insert(phases.count - 1)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            onComplete()
        }
    }

    private func animateCounter(to target: Int) {
        let steps = 25
        let interval = 1.2 / Double(steps)
        let increment = target / steps

        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                userCount = min(increment * i, target)
            }
        }
    }
}

struct AnalyzingPhaseRow: View {
    let title: String
    let icon: String
    let isActive: Bool
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: MPSpacing.md) {
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

            Text(title)
                .font(.system(size: 15, weight: isActive || isCompleted ? .medium : .regular))
                .foregroundColor(isActive || isCompleted ? MPColors.textPrimary : MPColors.textTertiary)

            Spacer()
        }
    }
}

// MARK: - Step 17: Your Habits

struct YourHabitsStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var showContent = false

    private let recommendedHabits: [HabitType] = [.madeBed, .morningSteps, .sleepDuration, .noSnooze]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.md) {
                Text("Build Your Daily Habits")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("Here's your personalized routine")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }
            .opacity(showContent ? 1 : 0)

            Spacer().frame(height: MPSpacing.xxl)

            // Habit cards
            VStack(spacing: MPSpacing.md) {
                ForEach(Array(recommendedHabits.enumerated()), id: \.element) { index, habit in
                    RecommendedHabitRow(
                        habitType: habit,
                        isSelected: data.selectedHabits.contains(habit)
                    ) {
                        if data.selectedHabits.contains(habit) {
                            data.selectedHabits.remove(habit)
                        } else {
                            data.selectedHabits.insert(habit)
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: showContent)
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer().frame(height: MPSpacing.lg)

            Text("Tap to customize • Add more later")
                .font(.system(size: 13))
                .foregroundColor(MPColors.textTertiary)
                .opacity(showContent ? 1 : 0)

            Spacer()

            MPButton(title: "Continue", style: .primary, isDisabled: data.selectedHabits.isEmpty) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            // Pre-select recommended habits
            data.selectedHabits = Set(recommendedHabits)

            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

struct RecommendedHabitRow: View {
    let habitType: HabitType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(isSelected ? MPColors.primaryLight : MPColors.surfaceSecondary)
                        .frame(width: 50, height: 50)

                    Image(systemName: habitType.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? MPColors.primary : MPColors.textTertiary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(habitType.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MPColors.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: verificationIcon)
                            .font(.system(size: 10))
                        Text(habitType.tier.description)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(verificationColor)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? MPColors.success : MPColors.border)
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .stroke(isSelected ? MPColors.primary.opacity(0.3) : Color.clear, lineWidth: 2)
            )
            .mpShadow(.small)
        }
    }

    private var verificationIcon: String {
        switch habitType.tier {
        case .aiVerified: return "sparkles"
        case .autoTracked: return "arrow.triangle.2.circlepath"
        case .honorSystem: return "hand.raised.fill"
        }
    }

    private var verificationColor: Color {
        switch habitType.tier {
        case .aiVerified: return MPColors.accent
        case .autoTracked: return MPColors.primary
        case .honorSystem: return MPColors.textTertiary
        }
    }
}

// MARK: - Step 18: Social Proof Final

struct SocialProofFinalStep: View {
    let onContinue: () -> Void
    @State private var showContent = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.lg) {
                // User avatars stack
                HStack(spacing: -10) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .fill([MPColors.primary, MPColors.accent, MPColors.success, MPColors.accentGold, Color.purple][index])
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(["SM", "MJ", "RK", "DL", "MT"][index])
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            )
                            .overlay(Circle().stroke(MPColors.background, lineWidth: 3))
                    }
                }

                Text("Start your transformation")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.9)

            Spacer().frame(height: MPSpacing.xxl)

            // Star rating
            VStack(spacing: MPSpacing.sm) {
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 24))
                            .foregroundColor(MPColors.accentGold)
                    }
                }
                Text("Loved by early users")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MPColors.textSecondary)
            }
            .opacity(showContent ? 1 : 0)

            Spacer().frame(height: MPSpacing.xxl)

            // Featured testimonial
            TestimonialCard(
                name: SampleTestimonials.all[3].name,
                age: SampleTestimonials.all[3].age,
                location: SampleTestimonials.all[3].location,
                quote: SampleTestimonials.all[3].quote,
                streakDays: SampleTestimonials.all[3].streakDays,
                avatarIndex: 3
            )
            .padding(.horizontal, MPSpacing.xl)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)

            Spacer()

            MPButton(title: "Get Started", style: .primary, icon: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }
}

// MARK: - Step 19: Hard Paywall

struct HardPaywallStep: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let onSubscribe: () -> Void
    let onSkip: () -> Void // TESTING ONLY - REMOVE BEFORE RELEASE

    @State private var selectedPlan: PlanType = .yearly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum PlanType {
        case monthly, yearly
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Skip button - TESTING ONLY
                    HStack {
                        Spacer()
                        Button {
                            onSkip()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(MPColors.textTertiary)
                                .padding(.horizontal, MPSpacing.md)
                                .padding(.vertical, MPSpacing.sm)
                        }
                    }
                    .padding(.horizontal, MPSpacing.lg)
                    .padding(.top, MPSpacing.sm)

                    Spacer().frame(height: MPSpacing.lg)

                    // Header
                    VStack(spacing: MPSpacing.lg) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [MPColors.accent, MPColors.accentGold],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: MPColors.accent.opacity(0.4), radius: 15, x: 0, y: 5)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }

                        VStack(spacing: MPSpacing.sm) {
                            Text("Earn Your Morning")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(MPColors.textPrimary)

                            Text("Unlock your full potential")
                                .font(.system(size: 16))
                                .foregroundColor(MPColors.textSecondary)
                        }
                    }

                    Spacer().frame(height: MPSpacing.xxl)

                    // Features
                    VStack(spacing: 0) {
                        PaywallFeatureRow(icon: "infinity", title: "Unlimited habits", subtitle: "Track everything")
                        Divider().padding(.horizontal, MPSpacing.lg)
                        PaywallFeatureRow(icon: "camera.viewfinder", title: "Unlimited AI verifications", subtitle: "No daily limits")
                        Divider().padding(.horizontal, MPSpacing.lg)
                        PaywallFeatureRow(icon: "flame.fill", title: "Streak recovery", subtitle: "1 free per month")
                        Divider().padding(.horizontal, MPSpacing.lg)
                        PaywallFeatureRow(icon: "chart.bar.fill", title: "Advanced analytics", subtitle: "Coming soon")
                    }
                    .padding(.vertical, MPSpacing.sm)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)
                    .mpShadow(.small)
                    .padding(.horizontal, MPSpacing.xl)

                    Spacer().frame(height: MPSpacing.xxl)

                    // Plan selection
                    VStack(spacing: MPSpacing.md) {
                        EnhancedPlanCard(
                            isSelected: selectedPlan == .yearly,
                            title: "Yearly",
                            price: subscriptionManager.yearlyPrice,
                            period: "/year",
                            monthlyEquivalent: "Just $2.50/month",
                            badge: "MOST POPULAR",
                            isHighlighted: true
                        ) {
                            selectedPlan = .yearly
                        }

                        EnhancedPlanCard(
                            isSelected: selectedPlan == .monthly,
                            title: "Monthly",
                            price: subscriptionManager.monthlyPrice,
                            period: "/month",
                            monthlyEquivalent: nil,
                            badge: nil,
                            isHighlighted: false
                        ) {
                            selectedPlan = .monthly
                        }
                    }
                    .padding(.horizontal, MPSpacing.xl)

                    Spacer().frame(height: 140)
                }
            }

            // Bottom CTA
            VStack {
                Spacer()

                VStack(spacing: MPSpacing.md) {
                    Button {
                        Task { await subscribe() }
                    } label: {
                        HStack {
                            if isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text("Subscribe Now")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [MPColors.primary, MPColors.primaryDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(MPRadius.lg)
                        .shadow(color: MPColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(isPurchasing)

                    Text("Billed immediately. Cancel anytime.")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.textTertiary)

                    TrustBadgeRow()

                    HStack(spacing: MPSpacing.xl) {
                        Button {
                            Task { await subscriptionManager.restorePurchases() }
                        } label: {
                            Text("Restore Purchases")
                                .font(.system(size: 13))
                                .foregroundColor(MPColors.primary)
                        }

                        Text("•")
                            .foregroundColor(MPColors.textMuted)

                        Button {
                            // Open terms
                        } label: {
                            Text("Terms")
                                .font(.system(size: 13))
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.bottom, 30)
                .padding(.top, MPSpacing.lg)
                .background(
                    LinearGradient(
                        colors: [MPColors.background.opacity(0), MPColors.background],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func subscribe() async {
        isPurchasing = true

        do {
            let transaction: StoreKit.Transaction?
            if selectedPlan == .yearly {
                transaction = try await subscriptionManager.purchaseYearly()
            } else {
                transaction = try await subscriptionManager.purchaseMonthly()
            }

            if transaction != nil {
                onSubscribe()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isPurchasing = false
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
                    .font(.system(size: 16, weight: .medium))
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

struct OnboardingGridButtonWithBadge: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: MPSpacing.sm) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? MPColors.primaryLight : MPColors.surfaceSecondary)
                            .frame(width: 44, height: 44)

                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(isSelected ? MPColors.primary : MPColors.textTertiary)
                    }

                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(MPColors.accent)
                            .cornerRadius(4)
                            .offset(x: 10, y: -5)
                    }
                }

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
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

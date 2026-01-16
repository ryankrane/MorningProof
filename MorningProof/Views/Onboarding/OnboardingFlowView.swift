import SwiftUI
import StoreKit
import AuthenticationServices
import FamilyControls
import SuperwallKit

// MARK: - Onboarding Data Model

class OnboardingData: ObservableObject {
    @Published var userName: String = ""
    @Published var gender: Gender? = nil
    @Published var morningStruggles: Set<MorningStruggle> = []
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

    private let totalSteps = 18
    private let paywallStep = 17

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
                        case 1: NameStep(data: onboardingData, onContinue: nextStep, onSkip: completeOnboarding)
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
                        case 17: HardPaywallStep(
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

        let newStep = currentStep + 1

        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = newStep
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
                    .fill(MPColors.primary)
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
                                    MPColors.primary.opacity(0.6),
                                    MPColors.primary.opacity(0.2),
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
                        .foregroundColor(MPColors.primary)
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
    let onSkip: () -> Void
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                Spacer()

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

            // Skip button in top right
            Button {
                isNameFocused = false
                onSkip()
            } label: {
                Text("Skip")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(MPColors.textTertiary)
            }
            .padding(.top, MPSpacing.lg)
            .padding(.trailing, MPSpacing.xl)
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
            Spacer()

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
            Spacer()

            VStack(spacing: MPSpacing.md) {
                Text("What's your biggest\nmorning struggle?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Select all that apply")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MPSpacing.md) {
                ForEach(OnboardingData.MorningStruggle.allCases, id: \.rawValue) { struggle in
                    OnboardingGridButton(
                        title: struggle.rawValue,
                        icon: struggle.icon,
                        isSelected: data.morningStruggles.contains(struggle)
                    ) {
                        if data.morningStruggles.contains(struggle) {
                            data.morningStruggles.remove(struggle)
                        } else {
                            data.morningStruggles.insert(struggle)
                        }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(title: "Continue", style: .primary, isDisabled: data.morningStruggles.isEmpty) {
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
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                Text("Here's the truth")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MPColors.textTertiary)
                    .opacity(showContent ? 1 : 0)

                StatisticHeroCard(
                    value: "73%",
                    label: "of people abandon their morning\nroutine within 2 weeks",
                    citation: "American Psychological Association, 2023"
                )

                // Supporting stats
                VStack(spacing: MPSpacing.sm) {
                    Text("Why most people fail:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)

                    HStack(spacing: MPSpacing.md) {
                        StatPillView(value: "3.5", label: "snoozes per day", icon: "alarm.fill")
                        StatPillView(value: "47m", label: "scrolling in bed", icon: "iphone")
                        StatPillView(value: "8%", label: "succeed alone", icon: "person.fill")
                    }
                }
                .padding(.horizontal, MPSpacing.lg)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }

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
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                VStack(spacing: MPSpacing.md) {
                    Text("You're not alone")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Thousands have transformed their mornings")
                        .font(.system(size: 16))
                        .foregroundColor(MPColors.textSecondary)
                }
                .opacity(showContent ? 1 : 0)

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
                .frame(height: 260)
                .clipped()
                .opacity(showContent ? 1 : 0)

                // Rating stat
                VStack(spacing: MPSpacing.sm) {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(MPColors.accentGold)
                        }
                    }
                    Text("4.9 average rating from users")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
                .opacity(showContent ? 1 : 0)
            }

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
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                VStack(spacing: MPSpacing.md) {
                    Text("Your first 10 days")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Based on tracked user data")
                        .font(.system(size: 16))
                        .foregroundColor(MPColors.textSecondary)
                }
                .opacity(showContent ? 1 : 0)

                // Before/After comparison
                BeforeAfterCard(
                    beforeTitle: "Day 1",
                    beforeItems: ["Struggle to get out of bed", "Rush through morning", "Feel groggy until noon"],
                    afterTitle: "Day 10",
                    afterItems: ["Morning routine complete", "Calm, productive mornings", "Energized all afternoon"]
                )
                .padding(.horizontal, MPSpacing.xl)
                .opacity(showContent ? 1 : 0)

                // Success metrics
                HStack(spacing: MPSpacing.lg) {
                    TransformationStatCard(
                        value: "89%",
                        label: "reduced snoozing",
                        icon: "alarm.fill",
                        color: MPColors.accent
                    )
                    TransformationStatCard(
                        value: "3.7x",
                        label: "habit consistency",
                        icon: "flame.fill",
                        color: MPColors.primary
                    )
                    TransformationStatCard(
                        value: "80%",
                        label: "more productive",
                        icon: "bolt.fill",
                        color: MPColors.accentGold
                    )
                }
                .padding(.horizontal, MPSpacing.xl)
                .opacity(showStats ? 1 : 0)
                .offset(y: showStats ? 0 : 20)
            }

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
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                VStack(spacing: MPSpacing.sm) {
                    Text("Tracking works")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Here's what the data shows")
                        .font(.system(size: 16))
                        .foregroundColor(MPColors.textSecondary)
                }

                StatisticRingCard(
                    percentage: 88,
                    label: "build lasting habits"
                )
                .padding(.horizontal, MPSpacing.xxl)

                // Research citation
                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.primary)
                    Text("Journal of Behavioral Psychology, 2024")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }

                // Supporting pills
                HStack(spacing: MPSpacing.sm) {
                    StatPillView(value: "10 days", label: "to transform", icon: "bolt.fill")
                    StatPillView(value: "35 days", label: "avg streak", icon: "flame.fill")
                    StatPillView(value: "96%", label: "recommend it", icon: "hand.thumbsup.fill")
                }
                .padding(.horizontal, MPSpacing.lg)
                .opacity(showPills ? 1 : 0)
                .offset(y: showPills ? 0 : 10)
            }

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
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                VStack(spacing: MPSpacing.sm) {
                    Text("Why Morning Proof Works")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Our users are")
                        .font(.system(size: 16))
                        .foregroundColor(MPColors.textSecondary)
                }
                .opacity(showHeader ? 1 : 0)

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

                        Text("more consistent")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .scaleEffect(showMultiplier ? 1 : 0.5)
                    .opacity(showMultiplier ? 1 : 0)
                }

                // Evidence cards
                VStack(spacing: MPSpacing.md) {
                    EvidenceCard(
                        stat: "94%",
                        description: "build lasting habits with photo proof",
                        icon: "camera.fill",
                        iconColor: MPColors.accent
                    )

                    EvidenceCard(
                        stat: "87%",
                        description: "say accountability keeps them on track",
                        icon: "flame.fill",
                        iconColor: MPColors.accentGold
                    )
                }
                .padding(.horizontal, MPSpacing.xl)
                .opacity(showCards ? 1 : 0)

                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 11))
                    Text("Based on Morning Proof user data")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(MPColors.textMuted)
                .opacity(showCards ? 1 : 0)
            }

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
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                VStack(spacing: MPSpacing.md) {
                    Text("Morning Proof is different")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Real accountability that works")
                        .font(.system(size: 16))
                        .foregroundColor(MPColors.textSecondary)
                }

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

                Text("No more lying to yourself")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(MPColors.accent)
                    .opacity(showSteps[2] ? 1 : 0)
            }

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
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                VStack(spacing: MPSpacing.md) {
                    Text("AI-Powered Verification")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Snap a photo, we'll verify it")
                        .font(.system(size: 16))
                        .foregroundColor(MPColors.textSecondary)
                }

                // Phone mockup
                ZStack {
                    // Phone frame
                    RoundedRectangle(cornerRadius: 30)
                        .fill(MPColors.surface)
                        .frame(width: 220, height: 300)
                        .mpShadow(.large)

                    // Screen content
                    VStack(spacing: MPSpacing.lg) {
                        // Stylized bed illustration with AI scanning
                        ZStack {
                            // Background
                            RoundedRectangle(cornerRadius: MPRadius.md)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "E8F0FE"), Color(hex: "D4E4FA")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 180, height: 140)

                            // Cartoon bed illustration
                            CartoonBedIllustration()
                                .frame(width: 160, height: 110)

                            // AI scanning overlay
                            if showScan || showScore {
                                AIScanningOverlay(
                                    isScanning: showScan && !showScore,
                                    isComplete: showScore,
                                    scanProgress: scanProgress
                                )
                                .frame(width: 180, height: 140)
                            }
                        }

                        // Result display
                        if showScore {
                            VStack(spacing: MPSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(MPColors.success)

                                Text("Habit Complete!")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(MPColors.textPrimary)
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else if showScan {
                            VStack(spacing: MPSpacing.xs) {
                                ProgressView()
                                    .tint(MPColors.accent)
                                Text("Analyzing...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(MPColors.textSecondary)
                            }
                        }
                    }
                    .frame(width: 200, height: 260)
                }
                .scaleEffect(showPhone ? 1 : 0.8)
                .opacity(showPhone ? 1 : 0)

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
                        Image(systemName: "eye.fill")
                            .foregroundColor(MPColors.accent)
                        Text("No cheating")
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
            }

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

// MARK: - Cartoon Bed Illustration

private struct CartoonBedIllustration: View {
    var body: some View {
        Image("BedIllustration")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

private struct BlanketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 8

        path.move(to: CGPoint(x: cornerRadius, y: 0))
        // Top edge with slight wave
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: 0),
            control: CGPoint(x: rect.width / 2, y: -5)
        )
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.width - cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(
            center: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.closeSubpath()

        return path
    }
}

private struct PillowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Rounded puffy pillow shape
        path.addRoundedRect(
            in: rect.insetBy(dx: 2, dy: 2),
            cornerSize: CGSize(width: rect.width * 0.3, height: rect.height * 0.4)
        )
        return path
    }
}

private struct HeadboardShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Curved headboard
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.4))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.4),
            control: CGPoint(x: rect.width / 2, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - AI Scanning Overlay

private struct AIScanningOverlay: View {
    let isScanning: Bool
    let isComplete: Bool
    let scanProgress: CGFloat

    @State private var scanLineOffset: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Corner brackets (viewfinder style)
                CornerBrackets(
                    color: isComplete ? MPColors.success : MPColors.accent,
                    isComplete: isComplete
                )

                // Scanning line
                if isScanning {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    MPColors.accent.opacity(0),
                                    MPColors.accent.opacity(0.8),
                                    MPColors.accent.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .offset(y: geometry.size.height * scanLineOffset)
                }

                // Analysis points
                if isScanning || isComplete {
                    AnalysisPoints(isComplete: isComplete, scanProgress: scanProgress)
                }

                // Pulsing border during scan
                if isScanning {
                    RoundedRectangle(cornerRadius: MPRadius.md)
                        .stroke(MPColors.accent.opacity(0.5), lineWidth: 2)
                        .scaleEffect(1.0 + scanProgress * 0.03)
                        .opacity(1.0 - scanProgress * 0.5)
                }
            }
        }
        .onAppear {
            if isScanning {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    scanLineOffset = 1
                }
            }
        }
        .onChange(of: isScanning) { _, newValue in
            if newValue {
                scanLineOffset = -1
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    scanLineOffset = 1
                }
            }
        }
    }
}

private struct CornerBrackets: View {
    let color: Color
    let isComplete: Bool

    var body: some View {
        GeometryReader { geometry in
            let bracketSize: CGFloat = 20
            let bracketWidth: CGFloat = 3

            ZStack {
                // Top-left
                CornerBracket(size: bracketSize, lineWidth: bracketWidth, color: color)
                    .position(x: bracketSize / 2 + 8, y: bracketSize / 2 + 8)

                // Top-right
                CornerBracket(size: bracketSize, lineWidth: bracketWidth, color: color)
                    .rotationEffect(.degrees(90))
                    .position(x: geometry.size.width - bracketSize / 2 - 8, y: bracketSize / 2 + 8)

                // Bottom-left
                CornerBracket(size: bracketSize, lineWidth: bracketWidth, color: color)
                    .rotationEffect(.degrees(-90))
                    .position(x: bracketSize / 2 + 8, y: geometry.size.height - bracketSize / 2 - 8)

                // Bottom-right
                CornerBracket(size: bracketSize, lineWidth: bracketWidth, color: color)
                    .rotationEffect(.degrees(180))
                    .position(x: geometry.size.width - bracketSize / 2 - 8, y: geometry.size.height - bracketSize / 2 - 8)
            }
        }
    }
}

private struct CornerBracket: View {
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: size, y: 0))
        }
        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        .frame(width: size, height: size)
    }
}

private struct AnalysisPoints: View {
    let isComplete: Bool
    let scanProgress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            // Small dots at key analysis points
            ZStack {
                // Pillow area
                AnalysisPoint(isComplete: isComplete)
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.25)
                    .opacity(scanProgress > 0.3 ? 1 : 0)

                // Blanket center
                AnalysisPoint(isComplete: isComplete)
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.55)
                    .opacity(scanProgress > 0.5 ? 1 : 0)

                // Left edge
                AnalysisPoint(isComplete: isComplete)
                    .position(x: geometry.size.width * 0.25, y: geometry.size.height * 0.6)
                    .opacity(scanProgress > 0.7 ? 1 : 0)

                // Right edge
                AnalysisPoint(isComplete: isComplete)
                    .position(x: geometry.size.width * 0.75, y: geometry.size.height * 0.6)
                    .opacity(scanProgress > 0.9 ? 1 : 0)
            }
        }
    }
}

private struct AnalysisPoint: View {
    let isComplete: Bool

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .fill((isComplete ? MPColors.success : MPColors.accent).opacity(0.3))
                .frame(width: isPulsing ? 16 : 8, height: isPulsing ? 16 : 8)

            // Inner dot
            Circle()
                .fill(isComplete ? MPColors.success : MPColors.accent)
                .frame(width: 6, height: 6)
        }
        .onAppear {
            if !isComplete {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: isComplete) { _, newValue in
            if newValue {
                withAnimation(.none) {
                    isPulsing = false
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
            Spacer()

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
            Spacer()

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
    @State private var isRequestingScreenTime = false
    @State private var screenTimeEnabled = false
    private var healthKit: HealthKitManager { HealthKitManager.shared }
    private var notificationManager: NotificationManager { NotificationManager.shared }
    @StateObject private var screenTimeManager = ScreenTimeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

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

                // App Locking permission card
                PermissionCard(
                    icon: "lock.shield.fill",
                    iconColor: MPColors.accentGold,
                    title: "App Locking",
                    description: "Block distracting apps",
                    isEnabled: screenTimeEnabled,
                    isLoading: isRequestingScreenTime
                ) {
                    requestScreenTimeAccess()
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

// MARK: - Step 15: App Locking Setup

struct AppLockingOnboardingStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void
    let onSkip: () -> Void

    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    private var manager: MorningProofManager { MorningProofManager.shared }

    @State private var isPickerPresented = false
    @State private var blockingStartMinutes: Int = 360  // 6 AM default suggestion
    @State private var showAuthorizationError = false
    @State private var isRequestingAuth = false
    @State private var showTimePicker = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: MPSpacing.xxxl)

            // Header
            VStack(spacing: MPSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(MPColors.primaryLight)
                        .frame(width: 80, height: 80)

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 36))
                        .foregroundColor(MPColors.primary)
                }

                Text("Block Distractions")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("Lock distracting apps until you\ncomplete your morning habits")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer().frame(height: MPSpacing.xxl)

            // Content based on authorization status
            if screenTimeManager.authorizationStatus != .approved {
                authorizationContent
            } else {
                configurationContent
            }

            Spacer()

            // Buttons
            VStack(spacing: MPSpacing.md) {
                if screenTimeManager.authorizationStatus == .approved && screenTimeManager.hasSelectedApps {
                    MPButton(title: "Enable App Locking", style: .primary, icon: "lock.fill") {
                        enableAndContinue()
                    }
                }

                Button {
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textTertiary)
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
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
            Text("Screen Time access is required. You can enable this later in Settings.")
        }
    }

    // Authorization view
    var authorizationContent: some View {
        VStack(spacing: MPSpacing.lg) {
            // Benefits list
            VStack(alignment: .leading, spacing: MPSpacing.md) {
                benefitRow(icon: "xmark.app.fill", text: "Block social media & games")
                benefitRow(icon: "checkmark.circle.fill", text: "Stay focused on your routine")
                benefitRow(icon: "flame.fill", text: "Build stronger habits faster")
            }
            .padding(MPSpacing.xl)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)

            // Authorize button
            Button {
                requestAuthorization()
            } label: {
                HStack {
                    if isRequestingAuth {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "hand.raised.fill")
                        Text("Enable Screen Time Access")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MPSpacing.lg)
                .background(MPColors.primary)
                .cornerRadius(MPRadius.lg)
            }
            .disabled(isRequestingAuth)
        }
        .padding(.horizontal, MPSpacing.xl)
    }

    // Configuration view (after authorization)
    var configurationContent: some View {
        VStack(spacing: MPSpacing.lg) {
            // Select apps
            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 20))
                        .foregroundColor(MPColors.primary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select Apps to Block")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(MPColors.textPrimary)

                        if screenTimeManager.hasSelectedApps {
                            let count = screenTimeManager.selectedApps.applicationTokens.count
                            Text("\(count) app\(count == 1 ? "" : "s") selected")
                                .font(.system(size: 13))
                                .foregroundColor(MPColors.success)
                        } else {
                            Text("Tap to choose apps")
                                .font(.system(size: 13))
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(MPColors.textTertiary)
                }
                .padding(MPSpacing.lg)
                .background(MPColors.surface)
                .cornerRadius(MPRadius.lg)
            }

            // Blocking start time
            Button {
                showTimePicker = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Block apps starting at")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(MPColors.textPrimary)

                        Text("When should blocking begin?")
                            .font(.system(size: 13))
                            .foregroundColor(MPColors.textTertiary)
                    }

                    Spacer()

                    Text(TimeOptions.formatTime(blockingStartMinutes))
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundColor(MPColors.primary)
                        .padding(.horizontal, MPSpacing.md)
                        .padding(.vertical, MPSpacing.sm)
                        .background(MPColors.primaryLight)
                        .cornerRadius(MPRadius.md)
                }
            }
            .padding(MPSpacing.lg)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.lg)
        }
        .padding(.horizontal, MPSpacing.xl)
        .sheet(isPresented: $showTimePicker) {
            TimeWheelPicker(
                selectedMinutes: $blockingStartMinutes,
                title: "Block Apps Starting At",
                subtitle: "Apps will be blocked until you complete your morning habits",
                timeOptions: TimeOptions.blockingStartTime
            )
            .presentationDetents([.medium])
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: MPSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(MPColors.primary)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(MPColors.textPrimary)
        }
    }

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

    private func enableAndContinue() {
        // Save settings
        manager.settings.appLockingEnabled = true
        manager.settings.blockingStartMinutes = blockingStartMinutes
        AppLockingDataStore.appLockingEnabled = true
        AppLockingDataStore.blockingStartMinutes = blockingStartMinutes

        // Start monitoring
        do {
            try screenTimeManager.startMorningBlockingSchedule(
                startMinutes: blockingStartMinutes,
                cutoffMinutes: manager.settings.morningCutoffMinutes
            )
        } catch {
            // Log error but continue - they can set it up later
        }

        manager.saveCurrentState()
        onContinue()
    }
}

// MARK: - Step 16: Optional Rating

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
            .onTapGesture {
                requestReview()
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
    @State private var rotationAngle: Double = 0
    @State private var showSocialProof = false
    @State private var userCount: Int = 0
    @State private var glowOpacity: Double = 0.3

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
            Spacer()

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

            // Progress circle with enhanced animation
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [MPColors.accent.opacity(glowOpacity), MPColors.accent.opacity(0)],
                            center: .center,
                            startRadius: 50,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)

                // Rotating dashed outer ring
                Circle()
                    .stroke(MPColors.accent.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [4, 8]))
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(rotationAngle))

                // Rotating dashed inner accent ring
                Circle()
                    .stroke(MPColors.primary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-rotationAngle * 0.7))

                // Background track
                Circle()
                    .stroke(MPColors.progressBg, lineWidth: 10)
                    .frame(width: 110, height: 110)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [MPColors.primary, MPColors.accent, MPColors.primary],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: MPColors.accent.opacity(0.5), radius: 8, x: 0, y: 0)

                // Percentage text
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)
                        .contentTransition(.numericText())
                    Text("%")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MPColors.textSecondary)
                }
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
        // Start continuous rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Pulse the glow
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }

        // Show social proof after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                showSocialProof = true
            }
            animateCounter(to: 2847)
        }

        // Smooth micro-progress animation that looks like real processing
        startSmoothProgress()
    }

    private func startSmoothProgress() {
        let totalDuration: Double = 8.0
        let phaseCount = phases.count
        let phaseDuration = totalDuration / Double(phaseCount)

        // Start micro-progress updates (simulate realistic loading)
        let updateInterval: Double = 0.05  // Update every 50ms for smooth animation

        // Create a timer-like effect with scheduled updates
        let totalUpdates = Int(totalDuration / updateInterval)

        for i in 0...totalUpdates {
            let elapsed = Double(i) * updateInterval
            let phaseIndex = min(Int(elapsed / phaseDuration), phaseCount - 1)
            let phaseProgress = (elapsed - Double(phaseIndex) * phaseDuration) / phaseDuration

            // Calculate target progress with realistic easing
            // Progress speeds up and slows down within each phase
            let baseProgress = CGFloat(phaseIndex) / CGFloat(phaseCount)

            // Add some variance - faster at start of phase, slower near end
            let easedPhaseProgress = sin(phaseProgress * .pi / 2)  // Ease out
            let targetProgress = baseProgress + (easedPhaseProgress / CGFloat(phaseCount))

            DispatchQueue.main.asyncAfter(deadline: .now() + elapsed) {
                // Small random jitter to simulate real processing
                let jitter = CGFloat.random(in: -0.005...0.005)
                let finalProgress = min(targetProgress + jitter, 1.0)

                withAnimation(.linear(duration: updateInterval)) {
                    progress = max(progress, finalProgress)  // Only move forward
                }

                // Update phase when crossing thresholds
                let newPhase = min(Int(finalProgress * CGFloat(phaseCount)), phaseCount - 1)
                if newPhase != currentPhase {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        // Complete previous phase
                        if currentPhase >= 0 {
                            _ = completedSteps.insert(currentPhase)
                        }
                        currentPhase = newPhase
                    }
                }
            }
        }

        // Ensure we hit 100% and complete all phases with smooth animation
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration - 0.2) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                progress = 1.0
                _ = completedSteps.insert(phaseCount - 1)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.2) {
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

    private let recommendedHabits: [HabitType] = [.madeBed, .morningWorkout, .sleepDuration, .coldShower]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

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

            Text("Add more later")
                .font(.system(size: 13))
                .foregroundColor(MPColors.textTertiary)
                .opacity(showContent ? 1 : 0)

            Spacer()

            MPButton(title: "Let's Get Started", style: .primary, isDisabled: data.selectedHabits.isEmpty) {
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

                    Text(habitType.howItWorksShort)
                        .font(.system(size: 13))
                        .foregroundColor(MPColors.textSecondary)
                        .lineLimit(1)
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

// MARK: - Step 19: Hard Paywall (Superwall)

struct HardPaywallStep: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let onSubscribe: () -> Void
    let onSkip: () -> Void // TESTING ONLY - REMOVE BEFORE RELEASE

    @State private var hasShownPaywall = false

    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            VStack(spacing: MPSpacing.lg) {
                Spacer()

                ProgressView()
                    .scaleEffect(1.2)

                Text("Loading...")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)

                Spacer()

                // Skip button - TESTING ONLY - REMOVE BEFORE RELEASE
                Button {
                    onSkip()
                } label: {
                    Text("Skip (Testing Only)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
                .padding(.bottom, MPSpacing.xxl)
            }
        }
        .onAppear {
            showSuperwallPaywall()
        }
    }

    private func showSuperwallPaywall() {
        guard !hasShownPaywall else { return }
        hasShownPaywall = true

        let handler = PaywallPresentationHandler()
        handler.onDismiss { [self] info, result in
            switch result {
            case .purchased:
                // User subscribed - complete onboarding
                Task { @MainActor in
                    await subscriptionManager.updateSubscriptionStatus()
                    onSubscribe()
                }
            case .restored:
                // User restored - complete onboarding
                Task { @MainActor in
                    await subscriptionManager.updateSubscriptionStatus()
                    onSubscribe()
                }
            case .declined:
                // User closed without purchasing - show paywall again
                hasShownPaywall = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSuperwallPaywall()
                }
            }
        }

        Superwall.shared.register(placement: "onboarding_paywall", handler: handler)
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

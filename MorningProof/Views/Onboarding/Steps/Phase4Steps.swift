import SwiftUI
import StoreKit
import SuperwallKit

// MARK: - Phase 4: Setup & Conversion

// MARK: - Step 13: Permissions

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
                    description: "Skip manual check-ins—we pull your data automatically",
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

// MARK: - Step 14: Optional Rating

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

// MARK: - Step 15: Analyzing

struct AnalyzingStep: View {
    @ObservedObject var data: OnboardingData
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var currentPhase = 0
    @State private var completedSteps: Set<Int> = []
    @State private var rotationAngle: Double = 0
    @State private var glowOpacity: Double = 0.3

    private var userName: String { data.userName }

    private var phases: [(title: String, icon: String)] {
        let struggleCount = data.morningStruggles.count
        let goalCount = data.desiredOutcomes.count
        let obstacleCount = data.obstacles.count

        return [
            (title: struggleCount > 0 ? "Analyzing \(struggleCount) morning challenge\(struggleCount == 1 ? "" : "s")" : "Analyzing your responses", icon: "doc.text.magnifyingglass"),
            (title: obstacleCount > 0 ? "Finding solutions for \(obstacleCount) obstacle\(obstacleCount == 1 ? "" : "s")" : "Identifying your patterns", icon: "brain.head.profile"),
            (title: goalCount > 0 ? "Matching habits to \(goalCount) goal\(goalCount == 1 ? "" : "s")" : "Selecting optimal habits", icon: "target"),
            (title: "Building your personalized routine", icon: "checkmark.seal")
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

        // Smooth micro-progress animation that looks like real processing
        startSmoothProgress()
    }

    private func startSmoothProgress() {
        let phaseCount = phases.count

        // PHASE 1: Realistic processing feel (0% to 70% in ~4 seconds)
        let phase1Increments: [(delay: Double, progress: Double)] = [
            (0.0, 0.02), (0.12, 0.05), (0.28, 0.08), (0.35, 0.11),
            (0.42, 0.14), (0.65, 0.17), (0.80, 0.21), (0.95, 0.24),
            (1.05, 0.28), (1.30, 0.31), (1.55, 0.35), (1.70, 0.38),
            (1.82, 0.42), (1.90, 0.45), (2.20, 0.48), (2.45, 0.51),
            (2.60, 0.54), (2.80, 0.57), (3.10, 0.60), (3.35, 0.62),
            (3.50, 0.64), (3.58, 0.66), (3.65, 0.68), (3.90, 0.70),
        ]

        for increment in phase1Increments {
            DispatchQueue.main.asyncAfter(deadline: .now() + increment.delay) {
                withAnimation(.easeOut(duration: 0.1)) {
                    progress = CGFloat(increment.progress)
                }

                let phaseIndex = min(Int(increment.progress * Double(phaseCount)), phaseCount - 1)
                if phaseIndex != currentPhase {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if currentPhase >= 0 {
                            _ = completedSteps.insert(currentPhase)
                        }
                        currentPhase = phaseIndex
                    }
                }
            }
        }

        // PHASE 2: Sporadic progress (70% to 93% in ~2 seconds)
        let phase2Start: Double = 4.0
        let sporadicIncrements: [(delay: Double, progress: Double)] = [
            (0.0, 0.72), (0.15, 0.74), (0.35, 0.76), (0.50, 0.78),
            (0.55, 0.79), (0.70, 0.81), (0.95, 0.83), (1.10, 0.85),
            (1.20, 0.86), (1.35, 0.88), (1.55, 0.89), (1.70, 0.91),
            (1.85, 0.92), (2.00, 0.93),
        ]

        for increment in sporadicIncrements {
            DispatchQueue.main.asyncAfter(deadline: .now() + phase2Start + increment.delay) {
                withAnimation(.easeOut(duration: 0.12)) {
                    progress = CGFloat(increment.progress)
                }

                let phaseIndex = min(Int(increment.progress * Double(phaseCount)), phaseCount - 1)
                if phaseIndex != currentPhase {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if currentPhase >= 0 {
                            _ = completedSteps.insert(currentPhase)
                        }
                        currentPhase = phaseIndex
                    }
                }
            }
        }

        // PHASE 3: Sporadic crawl (93% to 100% in ~3 seconds)
        let phase3Start: Double = 6.0
        let phase3Duration: Double = 3.0
        let crawlSteps: [(delay: Double, progress: Double)] = [
            (0.0, 0.93), (0.6, 0.94), (0.9, 0.95), (1.5, 0.96),
            (1.7, 0.97), (1.85, 0.98), (2.5, 0.99), (2.8, 1.00),
        ]

        for step in crawlSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + phase3Start + step.delay) {
                withAnimation(.easeOut(duration: 0.35)) {
                    progress = CGFloat(step.progress)
                }
            }
        }

        // Complete final phase
        DispatchQueue.main.asyncAfter(deadline: .now() + phase3Start + phase3Duration) {
            withAnimation(.easeInOut(duration: 0.3)) {
                _ = completedSteps.insert(phaseCount - 1)
            }
        }

        // Transition to next screen
        DispatchQueue.main.asyncAfter(deadline: .now() + phase3Start + phase3Duration + 0.5) {
            onComplete()
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

// MARK: - Step 16: Your Habits

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
        Button(action: {
            // Light tap haptic when selecting/deselecting habits
            HapticManager.shared.light()
            action()
        }) {
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
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
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
}

// MARK: - Step 17: Social Proof Final

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

// MARK: - Step 18: Hard Paywall (Superwall)

struct HardPaywallStep: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let onSubscribe: () -> Void

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

        handler.onDismiss { info, result in
            Task { @MainActor in
                switch result {
                case .purchased:
                    await subscriptionManager.updateSubscriptionStatus()
                    onSubscribe()
                case .restored:
                    await subscriptionManager.updateSubscriptionStatus()
                    onSubscribe()
                case .declined:
                    // User closed without purchasing - show paywall again
                    hasShownPaywall = false
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    showSuperwallPaywall()
                }
            }
        }

        handler.onSkip { reason in
            Task { @MainActor in
                // Paywall was skipped by Superwall (no products, not in experiment, etc.)
                // Complete onboarding anyway
                onSubscribe()
            }
        }

        handler.onError { error in
            Task { @MainActor in
                print("⚠️ Superwall error: \(error)")
                // On error, complete onboarding anyway
                onSubscribe()
            }
        }

        Superwall.shared.register(placement: "onboarding_paywall", handler: handler)
    }
}

import SwiftUI
import StoreKit
import SuperwallKit

// MARK: - Phase 6: Conversion (Steps 13-16)

// MARK: - Step 13: Optional Rating

struct OptionalRatingStep: View {
    let onContinue: () -> Void
    @State private var starsVisible = [false, false, false, false, false]
    @State private var buttonEnabled = false
    @State private var hoverOffset: CGFloat = 0
    @State private var glowIntensity: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(maxHeight: 120)

            // Title
            Text("Enjoying Morning Proof?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(MPColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MPSpacing.xl)

            Spacer().frame(height: 12)

            // Subtitle
            Text("Your rating helps others find better mornings")
                .font(.system(size: 16))
                .foregroundColor(MPColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MPSpacing.xl)

            Spacer().frame(height: 48)

            // Stars with glow and gentle hover animation
            HStack(spacing: 16) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: 48))
                        .foregroundColor(MPColors.accentGold)
                        .shadow(color: MPColors.accentGold.opacity(0.4 + glowIntensity * 0.3), radius: 8 + glowIntensity * 6)
                        .shadow(color: MPColors.accentGold.opacity(0.2 + glowIntensity * 0.15), radius: 16 + glowIntensity * 8)
                        .opacity(starsVisible[index] ? 1 : 0)
                        .scaleEffect(starsVisible[index] ? 1 : 0.3)
                        .offset(y: starsVisible[index] ? hoverOffset : 30)
                }
            }

            Spacer()

            MPButton(title: "Done", style: .primary, isDisabled: !buttonEnabled) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            // Animate stars in one by one with stagger
            for i in 0..<5 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(Double(i) * 0.12)) {
                    starsVisible[i] = true
                }
            }

            // Start hover animation after stars appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    hoverOffset = -8
                }
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    glowIntensity = 1
                }
            }

            // Show review prompt after stars finish appearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                requestReview()
            }

            // Enable button after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    buttonEnabled = true
                }
            }
        }
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Step 14: Analyzing

struct AnalyzingStep: View {
    @ObservedObject var data: OnboardingData
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var displayedProgress: Int = 0
    @State private var currentPhase = 0
    @State private var completedSteps: Set<Int> = []
    @State private var showContent = false
    @State private var isComplete = false
    @State private var phaseRowCenters: [Int: CGPoint] = [:]
    @State private var burstTarget: CGPoint? = nil

    private var userName: String { data.userName }

    private let phases: [(title: String, icon: String)] = [
        (title: "Analyzing your responses", icon: "magnifyingglass"),
        (title: "Identifying patterns", icon: "brain.head.profile"),
        (title: "Selecting habits", icon: "target"),
        (title: "Finalizing your plan", icon: "checkmark.seal.fill")
    ]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                // Neural Network Particle Cloud or Checkmark when complete
                ZStack {
                    if isComplete {
                        // Completion checkmark
                        ZStack {
                            Circle()
                                .fill(MPColors.success)
                                .frame(width: 100, height: 100)

                            Image(systemName: "checkmark")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        NeuralLoadingView(
                            progress: Double(progress),
                            isProcessing: !isComplete,
                            burstTarget: $burstTarget
                        )
                    }
                }
                .frame(width: 220, height: 220)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.8)

                Spacer().frame(height: MPSpacing.xxl)

                // Title
                VStack(spacing: MPSpacing.xs) {
                    Text("Building Your Plan")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    if !userName.isEmpty {
                        Text("Hang tight, \(userName)")
                            .font(.system(size: 15))
                            .foregroundColor(MPColors.textSecondary)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)

                Spacer().frame(height: MPSpacing.xxl)

                // Phase checklist
                VStack(spacing: MPSpacing.sm) {
                    ForEach(0..<phases.count, id: \.self) { index in
                        AnalyzingPhaseRow(
                            title: phases[index].title,
                            icon: phases[index].icon,
                            isActive: currentPhase == index,
                            isCompleted: completedSteps.contains(index)
                        )
                        .background(
                            GeometryReader { rowGeometry in
                                Color.clear
                                    .onAppear {
                                        // Calculate center of row in view coordinates
                                        let frame = rowGeometry.frame(in: .named("analyzingStep"))
                                        phaseRowCenters[index] = CGPoint(
                                            x: frame.midX,
                                            y: frame.midY
                                        )
                                    }
                            }
                        )
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : -20)
                        .animation(.easeOut(duration: 0.4).delay(0.1 + Double(index) * 0.1), value: showContent)
                    }
                }
                .padding(.horizontal, MPSpacing.xxl)

                Spacer()
            }
            .coordinateSpace(name: "analyzingStep")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            startLoading()
        }
    }

    private func startLoading() {
        startSmoothProgress()
    }

    private func startSmoothProgress() {
        let phaseCount = phases.count

        // PHASE 1: Quick start (0% to 70% in ~4 seconds)
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
                    displayedProgress = Int(increment.progress * 100)
                }

                let phaseIndex = min(Int(increment.progress * Double(phaseCount)), phaseCount - 1)
                if phaseIndex != currentPhase {
                    HapticManager.shared.light()
                    // Trigger burst toward the completed phase row
                    if let targetPoint = phaseRowCenters[currentPhase] {
                        burstTarget = targetPoint
                    }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if currentPhase >= 0 {
                            _ = completedSteps.insert(currentPhase)
                        }
                        currentPhase = phaseIndex
                    }
                }
            }
        }

        // PHASE 2: Slowing down (70% to 93%)
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
                    displayedProgress = Int(increment.progress * 100)
                }

                let phaseIndex = min(Int(increment.progress * Double(phaseCount)), phaseCount - 1)
                if phaseIndex != currentPhase {
                    HapticManager.shared.light()
                    // Trigger burst toward the completed phase row
                    if let targetPoint = phaseRowCenters[currentPhase] {
                        burstTarget = targetPoint
                    }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if currentPhase >= 0 {
                            _ = completedSteps.insert(currentPhase)
                        }
                        currentPhase = phaseIndex
                    }
                }
            }
        }

        // PHASE 3: Final crawl (93% to 100%)
        let phase3Start: Double = 6.0
        let crawlSteps: [(delay: Double, progress: Double)] = [
            (0.0, 0.93), (0.5, 0.94), (0.9, 0.95), (1.3, 0.96),
            (1.6, 0.97), (1.9, 0.98), (2.2, 0.99), (2.5, 1.00),
        ]

        for step in crawlSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + phase3Start + step.delay) {
                withAnimation(.easeOut(duration: 0.25)) {
                    progress = CGFloat(step.progress)
                    displayedProgress = Int(step.progress * 100)
                }
            }
        }

        // Show completion state
        DispatchQueue.main.asyncAfter(deadline: .now() + phase3Start + 2.7) {
            HapticManager.shared.success()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isComplete = true
                _ = completedSteps.insert(phaseCount - 1)
            }
        }

        // Transition to next screen
        DispatchQueue.main.asyncAfter(deadline: .now() + phase3Start + 3.4) {
            onComplete()
        }
    }
}

// MARK: - Analyzing Phase Row Component

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

// MARK: - Step 15: Your Habits

struct YourHabitsStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var showContent = false

    private let recommendedHabits: [HabitType] = [.madeBed, .morningWorkout, .sleepDuration, .prayer]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.md) {
                Text("Build Your Morning Routine")
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

            MPButton(title: "Activate My Routine", style: .primary, isDisabled: data.selectedHabits.isEmpty) {
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

// MARK: - Recommended Habit Row Component

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
                        .fill(isSelected ? MPColors.primary : MPColors.surfaceSecondary)
                        .frame(width: 50, height: 50)

                    Image(systemName: habitType.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : MPColors.textTertiary)
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

// MARK: - Step 16: Hard Paywall (Superwall)

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

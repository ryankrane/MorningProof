import SwiftUI

// MARK: - Phase 3: Solution & Investment

// MARK: - Step 9: How It Works

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

// MARK: - Step 10: AI Verification Showcase

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

                                Text("Bed Made!")
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
            .scaleEffect(1.25)
            .clipped()
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

// MARK: - Step 11: Desired Outcome

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

// MARK: - Step 12: Obstacles

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

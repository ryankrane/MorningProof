import SwiftUI

// MARK: - Phase 3: Solution Setup (Steps 6-8)
// Note: DistractionSelectionStep (Step 6) is a wrapper in OnboardingFlowView.swift

// MARK: - Step 7: How It Works

struct HowItWorksStep: View {
    let onContinue: () -> Void
    @State private var showSteps = [false, false, false, false]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.xl) {
                VStack(spacing: MPSpacing.md) {
                    Text("Morning Proof is different")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Real accountability that works")
                        .font(.system(size: 16))
                        .foregroundColor(MPColors.textSecondary)
                }

                VStack(spacing: MPSpacing.md) {
                    HowItWorksRow(
                        number: "1",
                        title: "Make your routine",
                        description: "Choose habits to complete each morning",
                        icon: "list.bullet.clipboard.fill",
                        isVisible: showSteps[0]
                    )

                    HowItWorksRow(
                        number: "2",
                        title: "Set your deadline",
                        description: "Pick a time to finish by each day",
                        icon: "clock.fill",
                        isVisible: showSteps[1]
                    )

                    HowItWorksRow(
                        number: "3",
                        title: "Prove it with AI",
                        description: "Snap a photo, AI verifies you did it",
                        icon: "camera.viewfinder",
                        isVisible: showSteps[2]
                    )

                    HowItWorksRow(
                        number: "4",
                        title: "Build your streak",
                        description: "Stay consistent, see progress",
                        icon: "flame.fill",
                        isVisible: showSteps[3]
                    )
                }
                .padding(.horizontal, MPSpacing.lg)

                Text("No more lying to yourself")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(MPColors.accent)
                    .opacity(showSteps[3] ? 1 : 0)
            }

            Spacer()

            MPButton(title: "See it in action", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            for i in 0..<4 {
                withAnimation(.easeOut(duration: 0.45).delay(Double(i) * 0.25)) {
                    showSteps[i] = true
                }
            }
        }
    }
}

// MARK: - How It Works Row Component

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
                    .foregroundColor(.black)
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

// MARK: - Step 8: AI Verification Showcase

struct AIVerificationShowcaseStep: View {
    let onContinue: () -> Void
    @State private var showPhone = false
    @State private var showScan = false
    @State private var showScore = false
    @State private var scanProgress: CGFloat = 0
    @State private var showUnlockMessage = false
    @State private var hapticTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.xl) {
                VStack(spacing: MPSpacing.md) {
                    Text("AI-Powered Verification")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("No excuses. Photo proof holds you accountable.")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Phone mockup with high-tech scan
                ZStack {
                    // Phone frame with subtle glow during scan
                    RoundedRectangle(cornerRadius: 30)
                        .fill(MPColors.surface)
                        .frame(width: 240, height: 320)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(
                                    showScan && !showScore ? MPColors.accent.opacity(0.5) : Color.clear,
                                    lineWidth: 2
                                )
                        )
                        .mpShadow(.large)

                    // Screen content
                    VStack(spacing: MPSpacing.md) {
                        // Bed illustration with laser scanning
                        ZStack {
                            // Background
                            RoundedRectangle(cornerRadius: MPRadius.md)
                                .fill(
                                    LinearGradient(
                                        colors: [MPColors.primaryLight, MPColors.primary.opacity(0.3)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 200, height: 150)

                            // Cartoon bed illustration
                            CartoonBedIllustration()
                                .frame(width: 180, height: 120)

                            // High-tech laser scanning overlay
                            if showScan || showScore {
                                HighTechScanOverlay(
                                    isScanning: showScan && !showScore,
                                    isComplete: showScore,
                                    scanProgress: scanProgress
                                )
                                .frame(width: 200, height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: MPRadius.md))
                            }
                        }

                        // Result display
                        if showScore {
                            VStack(spacing: MPSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(MPColors.success)
                                    .shadow(color: MPColors.success.opacity(0.5), radius: 10)

                                Text("Bed Made!")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(MPColors.textPrimary)
                            }
                            .transition(.scale.combined(with: .opacity))
                        } else if showScan {
                            VStack(spacing: MPSpacing.sm) {
                                // Scanning percentage
                                Text("\(Int(scanProgress * 100))%")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(MPColors.accent)
                                    .contentTransition(.numericText())

                                Text("Analyzing...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(MPColors.textSecondary)
                            }
                        }
                    }
                    .frame(width: 220, height: 280)
                }
                .scaleEffect(showPhone ? 1 : 0.8)
                .opacity(showPhone ? 1 : 0)

                // TODO: FAMILY CONTROLS - Re-enable this unlock message when approved:
                // Unlock message - appears after verification
                // if showUnlockMessage {
                //     HStack(spacing: MPSpacing.sm) {
                //         Image(systemName: "lock.open.fill")
                //             .font(.system(size: 16))
                //             .foregroundColor(MPColors.success)
                //
                //         Text("Once verified, your apps unlock instantly")
                //             .font(.system(size: 15, weight: .semibold))
                //             .foregroundColor(MPColors.success)
                //     }
                //     .padding(.horizontal, MPSpacing.lg)
                //     .padding(.vertical, MPSpacing.md)
                //     .background(MPColors.success.opacity(0.1))
                //     .cornerRadius(MPRadius.full)
                //     .transition(.opacity.combined(with: .move(edge: .bottom)))
                // }

                // Features row
                HStack(spacing: MPSpacing.xl) {
                    FeaturePill(icon: "bolt.fill", text: "Instant")
                    FeaturePill(icon: "eye.fill", text: "No cheating")
                    FeaturePill(icon: "lock.shield.fill", text: "Private")
                }
                .opacity(showScore ? 1 : 0)

                // AI disclosure note (required for App Store)
                HStack(spacing: MPSpacing.sm) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.textMuted)
                    Text("Photos are analyzed by AI to verify habits")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.textMuted)
                }
                .opacity(showScore ? 1 : 0)
            }

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                stopHaptics()
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            startVerificationSequence()
        }
        .onDisappear {
            stopHaptics()
        }
    }

    private func startVerificationSequence() {
        // Show phone
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showPhone = true
        }

        // Start scanning after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showScan = true
            startHapticPulses()

            // Animate scan progress
            animateScanProgress()
        }

        // Complete scan and show result
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            stopHaptics()

            // Success "jingle" haptic when AI verifies the photo
            HapticManager.shared.success()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showScore = true
            }
        }

        // Show unlock message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showUnlockMessage = true
            }
        }
    }

    private func animateScanProgress() {
        // Smooth progress animation over 2.5 seconds
        let duration: Double = 2.5
        let steps = 50
        let stepDuration = duration / Double(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.linear(duration: stepDuration)) {
                    scanProgress = CGFloat(i) / CGFloat(steps)
                }
            }
        }
    }

    private func startHapticPulses() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()

        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            generator.impactOccurred(intensity: 0.4)
            generator.prepare()
        }
    }

    private func stopHaptics() {
        hapticTimer?.invalidate()
        hapticTimer = nil
    }
}

// MARK: - Feature Pill Component

private struct FeaturePill: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(MPColors.accent)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MPColors.textSecondary)
        }
    }
}

// MARK: - High-Tech Scan Overlay

private struct HighTechScanOverlay: View {
    let isScanning: Bool
    let isComplete: Bool
    let scanProgress: CGFloat

    @State private var laserPosition: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Corner brackets - use dark color for visibility against purple gradient
                CornerBrackets(
                    color: isComplete ? MPColors.success : Color.black.opacity(0.6),
                    isComplete: isComplete
                )

                // Laser scan line with glow
                if isScanning {
                    LaserScanLine(position: laserPosition, size: geometry.size)
                }

                // Pulsing scan border
                if isScanning {
                    RoundedRectangle(cornerRadius: MPRadius.md)
                        .stroke(MPColors.accent.opacity(0.4), lineWidth: 1)
                        .scaleEffect(1.0 + sin(scanProgress * .pi * 4) * 0.01)
                }
            }
        }
        .onAppear {
            if isScanning {
                startLaserAnimation()
            }
        }
        .onChange(of: isScanning) { _, newValue in
            if newValue {
                startLaserAnimation()
            }
        }
    }

    private func startLaserAnimation() {
        laserPosition = 0
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            laserPosition = 1.0
        }
    }
}

// MARK: - Laser Scan Line

private struct LaserScanLine: View {
    let position: CGFloat
    let size: CGSize

    private let scanColor = Color(red: 1.0, green: 0.2, blue: 0.2)

    var body: some View {
        let y = size.height * position

        ZStack {
            // Outer glow (wide, soft)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            scanColor.opacity(0),
                            scanColor.opacity(0.3),
                            scanColor.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width - 10, height: 30)
                .blur(radius: 12)

            // Inner glow (medium)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            scanColor.opacity(0),
                            scanColor.opacity(0.6),
                            scanColor.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width - 15, height: 12)
                .blur(radius: 6)

            // Main laser line (bright core)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            scanColor.opacity(0),
                            scanColor,
                            scanColor,
                            scanColor.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width - 20, height: 2)
                .shadow(color: scanColor, radius: 4)
        }
        .position(x: size.width / 2, y: y)
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

// MARK: - Corner Brackets

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

// MARK: - Corner Bracket Shape

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

// MARK: - App Locking Onboarding Step (Screen Time Permission)
// ============================================================
// TODO: ENABLE THIS ONCE APPLE APPROVES FAMILY CONTROLS
// To enable:
// 1. Change `#if false` to `#if true` below
// 2. In OnboardingFlowView.swift: uncomment `import FamilyControls`
// 3. In OnboardingFlowView.swift: add this step to the switch statement
// 4. In ScreenTimeManager.swift: change `#if false` to `#if true`
// ============================================================

#if false // DISABLED - Waiting for Family Controls approval

import FamilyControls

struct AppLockingOnboardingStep: View {
    let onContinue: () -> Void

    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var showContent = false
    @State private var showFeatures = [false, false, false]
    @State private var isRequesting = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                // Header
                VStack(spacing: MPSpacing.md) {
                    // Apple Screen Time icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.4, green: 0.5, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "hourglass")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.8)

                    Text("Block Distractions")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("We use Apple's Screen Time to keep you focused")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 15)

                // Feature list
                VStack(spacing: MPSpacing.md) {
                    ScreenTimeFeatureRow(
                        icon: "lock.shield.fill",
                        title: "Official Apple API",
                        description: "Secure, private, built into iOS",
                        isVisible: showFeatures[0]
                    )

                    ScreenTimeFeatureRow(
                        icon: "app.badge.checkmark.fill",
                        title: "You Choose Apps",
                        description: "Only block what you select",
                        isVisible: showFeatures[1]
                    )

                    ScreenTimeFeatureRow(
                        icon: "sunrise.fill",
                        title: "Morning Only",
                        description: "Unlocks when you complete habits",
                        isVisible: showFeatures[2]
                    )
                }
                .padding(.horizontal, MPSpacing.xl)

                // Privacy note
                HStack(spacing: MPSpacing.sm) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 14))
                        .foregroundColor(MPColors.primary)
                    Text("We never see which apps you use")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
                .opacity(showFeatures[2] ? 1 : 0)
            }

            Spacer()

            VStack(spacing: MPSpacing.md) {
                // Error message
                if showError {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(MPColors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MPSpacing.xl)
                }

                // Connect button
                MPButton(
                    title: isRequesting ? "Connecting..." : "Connect Screen Time",
                    style: .primary,
                    icon: "hourglass",
                    isDisabled: isRequesting
                ) {
                    requestPermission()
                }
                .padding(.horizontal, MPSpacing.xxxl)

                // Skip button
                Button {
                    onContinue()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
                .padding(.bottom, 30)
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            for i in 0..<3 {
                withAnimation(.easeOut(duration: 0.4).delay(0.3 + Double(i) * 0.15)) {
                    showFeatures[i] = true
                }
            }
        }
    }

    private func requestPermission() {
        isRequesting = true
        showError = false

        Task {
            do {
                try await screenTimeManager.requestAuthorization()
                await MainActor.run {
                    isRequesting = false
                    if screenTimeManager.isAuthorized {
                        onContinue()
                    } else {
                        errorMessage = "Permission not granted. You can enable this later in Settings."
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    errorMessage = "Something went wrong. You can try again in Settings."
                    showError = true
                }
            }
        }
    }
}

// MARK: - Screen Time Feature Row

private struct ScreenTimeFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            ZStack {
                Circle()
                    .fill(MPColors.primaryLight)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(MPColors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer()
        }
        .padding(MPSpacing.md)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.md)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
    }
}

#endif // End DISABLED - Family Controls

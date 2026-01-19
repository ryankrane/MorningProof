import SwiftUI

// MARK: - Phase 3: Solution & Investment

// MARK: - Step 9: How It Works

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
                        title: "Set your habits",
                        description: "Choose morning habits to track",
                        icon: "list.bullet.clipboard.fill",
                        isVisible: showSteps[0]
                    )

                    HowItWorksRow(
                        number: "2",
                        title: "Lock distractions",
                        description: "Apps blocked until you're done",
                        icon: "lock.shield.fill",
                        isVisible: showSteps[1]
                    )

                    HowItWorksRow(
                        number: "3",
                        title: "Prove it",
                        description: "AI verifies you actually did it",
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

// MARK: - Step 10: AI Verification Showcase

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

                    Text("No excuses. Photo proof locks in your commitment.")
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

                // Unlock message - appears after verification
                if showUnlockMessage {
                    HStack(spacing: MPSpacing.sm) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 16))
                            .foregroundColor(MPColors.success)

                        Text("Once verified, your apps unlock instantly")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(MPColors.success)
                    }
                    .padding(.horizontal, MPSpacing.lg)
                    .padding(.vertical, MPSpacing.md)
                    .background(MPColors.success.opacity(0.1))
                    .cornerRadius(MPRadius.full)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                // Features row
                HStack(spacing: MPSpacing.xl) {
                    FeaturePill(icon: "bolt.fill", text: "Instant")
                    FeaturePill(icon: "eye.fill", text: "No cheating")
                    FeaturePill(icon: "lock.shield.fill", text: "Private")
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

// MARK: - Feature Pill

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

    var body: some View {
        let y = size.height * position

        ZStack {
            // Main laser line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            MPColors.accent.opacity(0),
                            MPColors.accent,
                            MPColors.accent,
                            MPColors.accent.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width - 20, height: 2)

            // Glow effect
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            MPColors.accent.opacity(0),
                            MPColors.accent.opacity(0.6),
                            MPColors.accent.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width - 20, height: 20)
                .blur(radius: 8)
        }
        .position(x: size.width / 2, y: y)
    }
}

// MARK: - Analysis Grid

private struct AnalysisGrid: View {
    let isComplete: Bool
    let scanProgress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid of analysis points
                ForEach(0..<6, id: \.self) { index in
                    let row = index / 3
                    let col = index % 3
                    let x = geometry.size.width * (0.2 + CGFloat(col) * 0.3)
                    let y = geometry.size.height * (0.3 + CGFloat(row) * 0.4)
                    let threshold = CGFloat(index + 1) / 7.0

                    AnalysisPoint(isComplete: isComplete)
                        .position(x: x, y: y)
                        .opacity(scanProgress > threshold ? 1 : 0)
                        .scaleEffect(scanProgress > threshold ? 1 : 0.5)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: scanProgress > threshold)
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

// MARK: - Step 10.5: Doom Scrolling Simulator (The "Villain" Reveal)

struct DoomScrollingSimulatorStep: View {
    let onContinue: () -> Void

    @State private var showPhone = false
    @State private var isScrolling = true
    @State private var showLockdown = false
    @State private var lockSlammed = false
    @State private var scrollOffset: CGFloat = 0

    // Simulated social feed items
    private let feedItems: [(icon: String, color: Color, title: String)] = [
        ("camera.fill", Color(white: 0.35), "Photos"),
        ("play.square.fill", .black, "Reels"),
        ("heart.fill", Color(white: 0.3), "Activity"),
        ("bubble.left.fill", Color(white: 0.4), "Trending"),
        ("play.rectangle.fill", .black, "Videos"),
        ("text.bubble.fill", Color(white: 0.35), "Posts"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.sm) {
                Text("Your Mornings, Protected")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text("Complete your habits first, then scroll")
                    .font(.system(size: 15))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            // Phone mockup with doom scrolling → lockdown sequence
            ZStack {
                // Phone outer bezel - metallic gradient effect
                RoundedRectangle(cornerRadius: 44)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.22), Color(white: 0.08), Color(white: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 430)
                    .overlay(
                        RoundedRectangle(cornerRadius: 44)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(white: 0.35), Color(white: 0.15)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                    )
                    .mpShadow(.large)

                // Side buttons for realism
                // Volume buttons (left side)
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: 0.25))
                        .frame(width: 3, height: 25)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(white: 0.25))
                        .frame(width: 3, height: 45)
                }
                .offset(x: -99, y: -60)

                // Power button (right side)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(white: 0.25))
                    .frame(width: 3, height: 55)
                    .offset(x: 99, y: -50)

                // Screen content area
                RoundedRectangle(cornerRadius: 38)
                    .fill(MPColors.background)
                    .frame(width: 184, height: 410)
                    .overlay(
                        ZStack {
                            // Scrolling social feed OR locked state
                            if !showLockdown {
                                // Doom scrolling feed
                                DoomScrollFeed(
                                    feedItems: feedItems,
                                    scrollOffset: scrollOffset,
                                    isScrolling: isScrolling
                                )
                            }

                            // Morning Proof lockdown overlay
                            if showLockdown {
                                LockdownOverlay(lockSlammed: lockSlammed)
                            }

                            // Dynamic Island at top
                            VStack {
                                Capsule()
                                    .fill(Color.black)
                                    .frame(width: 85, height: 26)
                                    .padding(.top, 10)
                                Spacer()
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 38))
                    )
            }
            .scaleEffect(showPhone ? 1 : 0.8)
            .opacity(showPhone ? 1 : 0)

            Spacer()

            MPButton(title: "Protect My Mornings", style: .primary, icon: "shield.lefthalf.filled") {
                HapticManager.shared.medium()
                onContinue()
            }
            .disabled(!lockSlammed)
            .opacity(lockSlammed ? 1 : 0.4)
            .animation(.easeInOut(duration: 0.3), value: lockSlammed)
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            startSequence()
        }
    }

    private func startSequence() {
        // Phase 1: Show phone with scrolling feed
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showPhone = true
        }

        // Start scroll animation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            scrollOffset = -400
        }

        // Phase 2: After showing doom scrolling, slam down the lock
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // Stop scrolling
            withAnimation(.easeOut(duration: 0.3)) {
                isScrolling = false
            }

            // Show lockdown overlay
            withAnimation(.easeIn(duration: 0.2)) {
                showLockdown = true
            }

            // Slam the lock with heavy haptic
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                // HEAVY THUD haptic - the dramatic slam
                HapticManager.shared.flameSlamImpact()

                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    lockSlammed = true
                }
            }
        }
    }
}

// MARK: - Doom Scroll Feed (Simulated Social Media)

private struct DoomScrollFeed: View {
    let feedItems: [(icon: String, color: Color, title: String)]
    let scrollOffset: CGFloat
    let isScrolling: Bool

    var body: some View {
        VStack(spacing: 0) {
            // App header bar
            HStack {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                Text("Instagram")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textPrimary)
            }
            .padding(.horizontal, MPSpacing.sm)
            .padding(.vertical, 8)
            .padding(.top, 30) // Space for Dynamic Island
            .background(MPColors.surface)

            // Scrolling feed
            GeometryReader { geo in
                VStack(spacing: MPSpacing.sm) {
                    ForEach(0..<12, id: \.self) { index in
                        FeedPostPlaceholder(
                            item: feedItems[index % feedItems.count],
                            index: index
                        )
                    }
                }
                .offset(y: scrollOffset)
            }
            .clipped()
        }
        .saturation(isScrolling ? 1 : 0.3)
        .brightness(isScrolling ? 0 : -0.1)
    }
}

// MARK: - Feed Post Placeholder

private struct FeedPostPlaceholder: View {
    let item: (icon: String, color: Color, title: String)
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // User header
            HStack(spacing: 6) {
                Circle()
                    .fill(item.color.opacity(0.3))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 11))
                            .foregroundColor(item.color)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MPColors.textTertiary.opacity(0.3))
                        .frame(width: 60, height: 8)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MPColors.textTertiary.opacity(0.2))
                        .frame(width: 40, height: 6)
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .font(.system(size: 12))
                    .foregroundColor(MPColors.textTertiary)
            }
            .padding(.horizontal, MPSpacing.sm)

            // Post image placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [item.color.opacity(0.15), item.color.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 140)
                .overlay(
                    Image(systemName: item.icon)
                        .font(.system(size: 32))
                        .foregroundColor(item.color.opacity(0.4))
                )

            // Action bar
            HStack(spacing: MPSpacing.md) {
                Image(systemName: "heart")
                Image(systemName: "bubble.right")
                Image(systemName: "paperplane")
                Spacer()
                Image(systemName: "bookmark")
            }
            .font(.system(size: 14))
            .foregroundColor(MPColors.textSecondary)
            .padding(.horizontal, MPSpacing.sm)
        }
    }
}

// MARK: - Lockdown Overlay

private struct LockdownOverlay: View {
    let lockSlammed: Bool

    var body: some View {
        ZStack {
            // Dark overlay with subtle gradient
            LinearGradient(
                colors: [Color.black.opacity(0.9), Color.black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Locked content
            VStack(spacing: 0) {
                Spacer().frame(height: 50)

                // Lock icon that slams in at top of overlay
                ZStack {
                    // Glow effect behind lock
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .blur(radius: 15)

                    // Lock circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red, Color(red: 0.8, green: 0.1, blue: 0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 4)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(lockSlammed ? 1 : 2.5)
                .opacity(lockSlammed ? 1 : 0)

                Spacer().frame(height: MPSpacing.lg)

                // App locked text
                VStack(spacing: 6) {
                    Text("Apps Locked")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("Complete your routine to unlock Instagram")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .opacity(lockSlammed ? 1 : 0)

                Spacer()

                // CTA button
                if lockSlammed {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            Text("Finish your routine")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(white: 0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, MPSpacing.xl)

                        Text("Verify habits to unlock")
                            .font(.system(size: 9))
                            .foregroundColor(Color.white.opacity(0.4))
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer().frame(height: MPSpacing.lg)
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
                        badge: nil
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

            MPButton(title: "That's my goal", style: .primary, isDisabled: data.desiredOutcomes.isEmpty) {
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

            MPButton(title: "Help Me Overcome This", style: .primary, isDisabled: data.obstacles.isEmpty) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
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

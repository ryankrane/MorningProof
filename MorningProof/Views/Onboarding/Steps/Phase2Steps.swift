import SwiftUI

// MARK: - Phase 2: Problem Agitation (Steps 4-5)

// MARK: - Step 4: The Guardrail (Why Morning Proof Works)

struct GuardrailStep: View {
    let onContinue: () -> Void
    @State private var showHeadline = false
    @State private var headlinePunch = false
    @State private var showSubtextLine1 = false
    @State private var showCards = [false, false, false]
    @State private var cardRotations = [Double](repeating: -8, count: 3)
    @State private var pulseIcons = false
    @State private var showButton = false

    private let guardrails: [(title: String, description: String, icon: String, gradient: [Color])] = [
        (
            "Earn Your Dopamine",
            "We block distracting apps until your morning routine is done.",
            "lock.shield.fill",
            [Color(red: 0.4, green: 0.5, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0)]
        ),
        (
            "Require Real Proof",
            "No more lying to yourself. AI verifies your morning routine with photo evidence.",
            "camera.viewfinder",
            [Color(red: 1.0, green: 0.6, blue: 0.3), Color(red: 1.0, green: 0.4, blue: 0.5)]
        ),
        (
            "Create Friction",
            "Make the wrong choice hard. We add just enough resistance to keep you on track.",
            "figure.run",
            [MPColors.primary, Color(red: 0.5, green: 0.8, blue: 0.9)]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(minHeight: 40, maxHeight: 80)

            // Hero headline - "Systems Work." in chalk style
            ChalkText(text: "Systems Work.")
                .opacity(showHeadline ? 1 : 0)
                .scaleEffect(showHeadline ? 1 : 0.8)
                .scaleEffect(headlinePunch ? 1.08 : 1.0)
                .padding(.horizontal, MPSpacing.xl)

            Spacer()
                .frame(height: 80)

            // Guardrail cards - drop in from top with spring bounce
            VStack(spacing: MPSpacing.md) {
                ForEach(0..<3, id: \.self) { index in
                    let item = guardrails[index]
                    GuardrailCard(
                        title: item.title,
                        description: item.description,
                        icon: item.icon,
                        gradient: item.gradient,
                        isPulsing: pulseIcons
                    )
                    .opacity(showCards[index] ? 1 : 0)
                    .offset(y: showCards[index] ? 0 : -80)
                    .scaleEffect(showCards[index] ? 1 : 0.85)
                    .rotation3DEffect(
                        .degrees(showCards[index] ? 0 : cardRotations[index]),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.5
                    )
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()
                .frame(height: 60)

            // Explanatory text below the cards - both lines animate together smoothly
            VStack(spacing: 6) {
                Text("Your brain will always choose easy over hard —")
                    .font(.system(size: 15))
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)

                Text("So we remove the choice entirely.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .lineSpacing(4)
            .padding(.horizontal, MPSpacing.xl)
            .opacity(showSubtextLine1 ? 1 : 0)
            .offset(y: showSubtextLine1 ? 0 : 12)
            .blur(radius: showSubtextLine1 ? 0 : 4)

            Spacer()

            MPButton(title: "Show Me How", style: .primary, icon: "arrow.right") {
                onContinue()
            }
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 20)
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            startAnimationSequence()
        }
    }

    private func startAnimationSequence() {
        // Phase 1: Headline appears with spring
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showHeadline = true
        }

        // 0.3s - Punch effect with haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            HapticManager.shared.medium()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                headlinePunch = true
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.2)) {
                headlinePunch = false
            }
        }

        // Phase 2: Cards drop in one at a time
        for i in 0..<3 {
            let delay = 0.8 + Double(i) * 0.5
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(delay)) {
                showCards[i] = true
                cardRotations[i] = 0
            }
        }

        // Phase 3: Subtext fades in after cards
        withAnimation(.easeOut(duration: 0.8).delay(2.4)) {
            showSubtextLine1 = true
        }

        // Phase 4: Button appears
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(3.4)) {
            showButton = true
        }

        // Phase 5: Start icon pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.6) {
            pulseIcons = true
        }
    }
}

// MARK: - Chalk Text Component

private struct ChalkText: View {
    let text: String

    var body: some View {
        ZStack {
            // Subtle chalk dust glow behind
            Text(text)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .blur(radius: 12)
                .opacity(0.3)

            // Main chalk text with texture overlay
            Text(text)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.92),
                            Color.white.opacity(0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .white.opacity(0.4), radius: 1, x: 0, y: 0)
        }
    }
}

// MARK: - Guardrail Card Component

struct GuardrailCard: View {
    let title: String
    let description: String
    let icon: String
    let gradient: [Color]
    let isPulsing: Bool

    @State private var glowPulse = false

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            // Glowing icon orb
            ZStack {
                // Animated glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [gradient[0].opacity(0.5), gradient[1].opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(glowPulse ? 1.15 : 1.0)
                    .opacity(glowPulse ? 0.8 : 0.5)

                // Icon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 52, height: 52)
            .onChange(of: isPulsing) { _, pulsing in
                if pulsing {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        glowPulse = true
                    }
                }
            }

            // Content
            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(MPSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .fill(MPColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [gradient[0], gradient[1].opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: gradient[0].opacity(glowPulse ? 0.4 : 0.15),
            radius: glowPulse ? 12 : 6
        )
    }
}

// MARK: - Step 5: Doom Scrolling Simulator (The "Villain" Reveal)

struct DoomScrollingSimulatorStep: View {
    let onContinue: () -> Void

    @State private var showPhone = false
    @State private var isScrolling = true
    @State private var showLockdown = false
    @State private var lockSlammed = false
    @State private var scrollOffset: CGFloat = 0
    @State private var feedVisible = true  // Controls feed visibility for clean resets
    @State private var hasShownOnce = false  // Track if animation has completed once (for button)
    @State private var animationCycleID = 0  // Forces fresh animation state on each loop
    @State private var isActive = true  // Track if view is still on screen to cancel looping animation

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

                Text("Finish your routine to unlock your apps")
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
                ZStack {
                    RoundedRectangle(cornerRadius: 38)
                        .fill(MPColors.background)

                    // Scrolling social feed OR locked state
                    if !showLockdown {
                        // Doom scrolling feed with fade for clean loop resets
                        DoomScrollFeed(
                            feedItems: feedItems,
                            scrollOffset: scrollOffset,
                            isScrolling: isScrolling
                        )
                        .id(animationCycleID)  // Forces fresh view/animation on each cycle
                        .opacity(feedVisible ? 1 : 0)
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
                .frame(width: 184, height: 410)
                .clipShape(RoundedRectangle(cornerRadius: 38))
            }
            .scaleEffect(showPhone ? 1 : 0.8)
            .opacity(showPhone ? 1 : 0)

            Spacer()

            MPButton(title: "Protect My Mornings", style: .primary, icon: "shield.lefthalf.filled") {
                HapticManager.shared.medium()
                onContinue()
            }
            .disabled(!hasShownOnce)
            .opacity(hasShownOnce ? 1 : 0.4)
            .animation(.easeInOut(duration: 0.3), value: hasShownOnce)
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            startSequence()
        }
        .onDisappear {
            isActive = false
        }
    }

    private func startSequence() {
        // Phase 1: Show phone with scrolling feed
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showPhone = true
        }

        // Start scroll animation
        withAnimation(.linear(duration: 8)) {
            scrollOffset = -400
        }

        // Phase 2: After showing doom scrolling, slam down the lock
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            guard self.isActive else { return }

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
                guard self.isActive else { return }

                // HEAVY THUD haptic - the dramatic slam
                HapticManager.shared.flameSlamImpact()

                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    lockSlammed = true
                }

                // Mark that we've shown the animation once (enables button)
                hasShownOnce = true

                // Phase 3: Wait 4 seconds at locked screen, then loop
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    guard self.isActive else { return }
                    self.resetAndReplay()
                }
            }
        }
    }

    private func resetAndReplay() {
        guard isActive else { return }

        // IMMEDIATELY hide feed while lockdown is still fully opaque (user won't see this)
        feedVisible = false

        // Reset scroll position with explicit animation cancellation
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            scrollOffset = 0
        }
        isScrolling = true

        // Increment cycle ID to force SwiftUI to create a fresh view with clean animation state
        animationCycleID += 1

        // Now fade out lockdown overlay (feed is already hidden and reset behind it)
        withAnimation(.easeOut(duration: 0.3)) {
            showLockdown = false
            lockSlammed = false
        }

        // After lockdown fades, fade feed back in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            guard self.isActive else { return }

            withAnimation(.easeIn(duration: 0.25)) {
                self.feedVisible = true
            }

            // Start fresh scroll animation
            withAnimation(.linear(duration: 8)) {
                scrollOffset = -400
            }

            // Schedule next lockdown
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
                guard self.isActive else { return }

                // Stop scrolling
                withAnimation(.easeOut(duration: 0.3)) {
                    self.isScrolling = false
                }

                // Show lockdown overlay
                withAnimation(.easeIn(duration: 0.2)) {
                    showLockdown = true
                }

                // Slam the lock
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    guard self.isActive else { return }

                    HapticManager.shared.flameSlamImpact()

                    withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                        lockSlammed = true
                    }

                    // Wait 4 seconds then loop again
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        guard self.isActive else { return }
                        self.resetAndReplay()
                    }
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

    // Post types - cycle through all 6 clipart scenes
    private static let postTypes: [PostImageType] = [
        .sunset, .dog, .mountains, .cat, .beach, .forest
    ]

    var body: some View {
        VStack(spacing: 0) {
            // App header bar
            HStack {
                Image(systemName: "camera")
                    .font(.system(size: 14))
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                Text("Instagram")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                Image(systemName: "paperplane")
                    .font(.system(size: 14))
                    .foregroundColor(MPColors.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .padding(.top, 38) // Space for Dynamic Island
            .background(Color(white: 0.08))

            // Scrolling feed - contained within remaining space
            VStack(spacing: 0) {
                ForEach(0..<8, id: \.self) { index in
                    CompactFeedPost(
                        postType: Self.postTypes[index % Self.postTypes.count],
                        index: index
                    )
                }
            }
            .offset(y: scrollOffset)
        }
        .saturation(isScrolling ? 1 : 0.3)
        .brightness(isScrolling ? 0 : -0.1)
    }
}

// MARK: - Post Image Types

private enum PostImageType: CaseIterable {
    case sunset
    case mountains
    case beach
    case forest
    case dog
    case cat
}

// MARK: - Clipart Post Images

private struct SunsetImage: View {
    var body: some View {
        ZStack {
            // Sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.5, blue: 0.3),
                    Color(red: 1.0, green: 0.7, blue: 0.4),
                    Color(red: 0.95, green: 0.4, blue: 0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Sun
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 1.0, green: 0.95, blue: 0.6), Color(red: 1.0, green: 0.7, blue: 0.3)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .frame(width: 50, height: 50)
                .offset(y: 25)

            // Horizon water/land
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Color(red: 0.2, green: 0.15, blue: 0.25).opacity(0.8))
                    .frame(height: 35)
            }

            // Sun reflection on water
            Ellipse()
                .fill(Color(red: 1.0, green: 0.8, blue: 0.4).opacity(0.4))
                .frame(width: 20, height: 50)
                .offset(y: 55)
        }
    }
}

private struct MountainsImage: View {
    var body: some View {
        ZStack {
            // Sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.5, blue: 0.7),
                    Color(red: 0.7, green: 0.6, blue: 0.75),
                    Color(red: 0.9, green: 0.7, blue: 0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Back mountain
            Triangle()
                .fill(Color(red: 0.35, green: 0.35, blue: 0.45))
                .frame(width: 140, height: 80)
                .offset(x: 30, y: 30)

            // Front mountain
            Triangle()
                .fill(Color(red: 0.25, green: 0.25, blue: 0.35))
                .frame(width: 120, height: 90)
                .offset(x: -20, y: 25)

            // Snow cap on front mountain
            Triangle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 30, height: 22)
                .offset(x: -20, y: -20)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct BeachImage: View {
    var body: some View {
        ZStack {
            // Sky
            LinearGradient(
                colors: [
                    Color(red: 0.5, green: 0.7, blue: 0.9),
                    Color(red: 0.7, green: 0.85, blue: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                Spacer()

                // Ocean
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.2, green: 0.5, blue: 0.7), Color(red: 0.3, green: 0.6, blue: 0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 50)

                // Wave line
                WavyLine()
                    .stroke(Color.white.opacity(0.6), lineWidth: 2)
                    .frame(height: 8)
                    .offset(y: -20)

                // Sand
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.85, blue: 0.65), Color(red: 0.9, green: 0.8, blue: 0.55)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 35)
            }

            // Sun
            Circle()
                .fill(Color(red: 1.0, green: 0.95, blue: 0.7))
                .frame(width: 25, height: 25)
                .offset(x: 50, y: -35)
        }
    }
}

private struct WavyLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waveHeight: CGFloat = 4
        let waveLength: CGFloat = 20

        path.move(to: CGPoint(x: 0, y: rect.midY))

        var x: CGFloat = 0
        while x < rect.width {
            path.addQuadCurve(
                to: CGPoint(x: x + waveLength / 2, y: rect.midY),
                control: CGPoint(x: x + waveLength / 4, y: rect.midY - waveHeight)
            )
            path.addQuadCurve(
                to: CGPoint(x: x + waveLength, y: rect.midY),
                control: CGPoint(x: x + 3 * waveLength / 4, y: rect.midY + waveHeight)
            )
            x += waveLength
        }

        return path
    }
}

private struct ForestImage: View {
    var body: some View {
        ZStack {
            // Sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.55, blue: 0.5),
                    Color(red: 0.6, green: 0.7, blue: 0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Ground
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color(red: 0.2, green: 0.3, blue: 0.2))
                    .frame(height: 30)
            }

            // Trees - back row
            HStack(spacing: 15) {
                TreeShape()
                    .fill(Color(red: 0.15, green: 0.3, blue: 0.2))
                    .frame(width: 35, height: 70)
                TreeShape()
                    .fill(Color(red: 0.15, green: 0.3, blue: 0.2))
                    .frame(width: 40, height: 80)
                TreeShape()
                    .fill(Color(red: 0.15, green: 0.3, blue: 0.2))
                    .frame(width: 35, height: 65)
            }
            .offset(y: 10)

            // Trees - front row
            HStack(spacing: 25) {
                TreeShape()
                    .fill(Color(red: 0.1, green: 0.25, blue: 0.15))
                    .frame(width: 45, height: 90)
                TreeShape()
                    .fill(Color(red: 0.1, green: 0.25, blue: 0.15))
                    .frame(width: 50, height: 100)
            }
            .offset(y: 20)
        }
    }
}

private struct TreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Simple pine tree shape
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 10))
        path.addLine(to: CGPoint(x: rect.midX + 5, y: rect.maxY - 10))
        path.addLine(to: CGPoint(x: rect.midX + 5, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - 5, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - 5, y: rect.maxY - 10))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 10))
        path.closeSubpath()
        return path
    }
}

private struct DogImage: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.85, green: 0.8, blue: 0.75), Color(red: 0.75, green: 0.7, blue: 0.65)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Dog face
            VStack(spacing: 0) {
                // Ears
                HStack(spacing: 40) {
                    DogEar()
                        .fill(Color(red: 0.6, green: 0.45, blue: 0.3))
                        .frame(width: 25, height: 35)
                        .rotationEffect(.degrees(-15))
                    DogEar()
                        .fill(Color(red: 0.6, green: 0.45, blue: 0.3))
                        .frame(width: 25, height: 35)
                        .rotationEffect(.degrees(15))
                }
                .offset(y: 15)

                // Head
                Ellipse()
                    .fill(Color(red: 0.75, green: 0.6, blue: 0.45))
                    .frame(width: 70, height: 60)

                // Snout
                Ellipse()
                    .fill(Color(red: 0.85, green: 0.75, blue: 0.65))
                    .frame(width: 35, height: 25)
                    .offset(y: -20)
            }
            .offset(y: 10)

            // Eyes
            HStack(spacing: 20) {
                Circle()
                    .fill(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .frame(width: 10, height: 10)
                Circle()
                    .fill(Color(red: 0.2, green: 0.15, blue: 0.1))
                    .frame(width: 10, height: 10)
            }
            .offset(y: -5)

            // Nose
            Ellipse()
                .fill(Color(red: 0.15, green: 0.1, blue: 0.1))
                .frame(width: 12, height: 9)
                .offset(y: 15)

            // Tongue
            Ellipse()
                .fill(Color(red: 0.9, green: 0.5, blue: 0.5))
                .frame(width: 10, height: 15)
                .offset(y: 30)
        }
    }
}

private struct DogEar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX + 5, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.maxY + 5)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX - 5, y: rect.midY)
        )
        return path
    }
}

private struct CatImage: View {
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.75, green: 0.75, blue: 0.8), Color(red: 0.65, green: 0.65, blue: 0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Cat face
            VStack(spacing: 0) {
                // Ears
                HStack(spacing: 35) {
                    CatEar()
                        .fill(Color(red: 0.5, green: 0.5, blue: 0.55))
                        .frame(width: 25, height: 30)
                        .rotationEffect(.degrees(-10))
                    CatEar()
                        .fill(Color(red: 0.5, green: 0.5, blue: 0.55))
                        .frame(width: 25, height: 30)
                        .rotationEffect(.degrees(10))
                        .scaleEffect(x: -1)
                }
                .offset(y: 20)

                // Head
                Ellipse()
                    .fill(Color(red: 0.6, green: 0.6, blue: 0.65))
                    .frame(width: 65, height: 55)
            }
            .offset(y: 5)

            // Inner ears
            HStack(spacing: 35) {
                CatEar()
                    .fill(Color(red: 0.85, green: 0.7, blue: 0.7))
                    .frame(width: 12, height: 15)
                    .rotationEffect(.degrees(-10))
                CatEar()
                    .fill(Color(red: 0.85, green: 0.7, blue: 0.7))
                    .frame(width: 12, height: 15)
                    .rotationEffect(.degrees(10))
                    .scaleEffect(x: -1)
            }
            .offset(y: -25)

            // Eyes
            HStack(spacing: 18) {
                CatEye()
                    .fill(Color(red: 0.4, green: 0.6, blue: 0.3))
                    .frame(width: 14, height: 16)
                CatEye()
                    .fill(Color(red: 0.4, green: 0.6, blue: 0.3))
                    .frame(width: 14, height: 16)
            }
            .offset(y: -2)

            // Pupils
            HStack(spacing: 22) {
                Capsule()
                    .fill(Color.black)
                    .frame(width: 3, height: 10)
                Capsule()
                    .fill(Color.black)
                    .frame(width: 3, height: 10)
            }
            .offset(y: -2)

            // Nose
            CatNose()
                .fill(Color(red: 0.85, green: 0.6, blue: 0.6))
                .frame(width: 10, height: 8)
                .offset(y: 12)

            // Whiskers
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Capsule().fill(Color.white.opacity(0.6)).frame(width: 20, height: 1.5).rotationEffect(.degrees(-10))
                    Capsule().fill(Color.white.opacity(0.6)).frame(width: 22, height: 1.5)
                    Capsule().fill(Color.white.opacity(0.6)).frame(width: 20, height: 1.5).rotationEffect(.degrees(10))
                }
                VStack(spacing: 4) {
                    Capsule().fill(Color.white.opacity(0.6)).frame(width: 20, height: 1.5).rotationEffect(.degrees(10))
                    Capsule().fill(Color.white.opacity(0.6)).frame(width: 22, height: 1.5)
                    Capsule().fill(Color.white.opacity(0.6)).frame(width: 20, height: 1.5).rotationEffect(.degrees(-10))
                }
            }
            .offset(y: 18)
        }
    }
}

private struct CatEar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct CatEye: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect)
        return path
    }
}

private struct CatNose: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Post Image View

private struct PostImage: View {
    let type: PostImageType

    var body: some View {
        Group {
            switch type {
            case .sunset:
                SunsetImage()
            case .mountains:
                MountainsImage()
            case .beach:
                BeachImage()
            case .forest:
                ForestImage()
            case .dog:
                DogImage()
            case .cat:
                CatImage()
            }
        }
        .clipped()
    }
}

// MARK: - Profile Pic Image (Mini themed clipart for 18x18 profile pictures)

private struct ProfilePicImage: View {
    let type: PostImageType

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                switch type {
                case .sunset:
                    // Orange/pink gradient with small sun
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.5, blue: 0.3),
                            Color(red: 0.95, green: 0.4, blue: 0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    // Sun
                    Circle()
                        .fill(Color(red: 1.0, green: 0.9, blue: 0.5))
                        .frame(width: size * 0.45, height: size * 0.45)
                        .offset(y: size * 0.15)
                    // Horizon
                    Rectangle()
                        .fill(Color(red: 0.2, green: 0.15, blue: 0.25).opacity(0.7))
                        .frame(height: size * 0.25)
                        .offset(y: size * 0.38)

                case .mountains:
                    // Blue-gray gradient with mountain peak
                    LinearGradient(
                        colors: [
                            Color(red: 0.5, green: 0.55, blue: 0.7),
                            Color(red: 0.8, green: 0.65, blue: 0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    // Mountain
                    MiniMountain()
                        .fill(Color(red: 0.3, green: 0.3, blue: 0.4))
                        .frame(width: size * 0.9, height: size * 0.6)
                        .offset(y: size * 0.2)
                    // Snow cap
                    MiniMountain()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: size * 0.35, height: size * 0.22)
                        .offset(y: -size * 0.1)

                case .beach:
                    // Sky/sand split with tiny sun
                    VStack(spacing: 0) {
                        // Sky
                        Color(red: 0.5, green: 0.75, blue: 0.95)
                        // Ocean
                        Color(red: 0.3, green: 0.55, blue: 0.7)
                            .frame(height: size * 0.25)
                        // Sand
                        Color(red: 0.95, green: 0.85, blue: 0.65)
                            .frame(height: size * 0.2)
                    }
                    // Sun
                    Circle()
                        .fill(Color(red: 1.0, green: 0.95, blue: 0.7))
                        .frame(width: size * 0.25, height: size * 0.25)
                        .offset(x: size * 0.2, y: -size * 0.25)

                case .forest:
                    // Green gradient with pine tree
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.55, blue: 0.45),
                            Color(red: 0.25, green: 0.4, blue: 0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    // Pine tree
                    MiniTree()
                        .fill(Color(red: 0.12, green: 0.25, blue: 0.15))
                        .frame(width: size * 0.6, height: size * 0.75)
                        .offset(y: size * 0.1)

                case .dog:
                    // Warm tan gradient with dog face
                    LinearGradient(
                        colors: [
                            Color(red: 0.85, green: 0.8, blue: 0.72),
                            Color(red: 0.75, green: 0.68, blue: 0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    // Ears
                    HStack(spacing: size * 0.35) {
                        Ellipse()
                            .fill(Color(red: 0.6, green: 0.45, blue: 0.32))
                            .frame(width: size * 0.28, height: size * 0.35)
                            .rotationEffect(.degrees(-15))
                        Ellipse()
                            .fill(Color(red: 0.6, green: 0.45, blue: 0.32))
                            .frame(width: size * 0.28, height: size * 0.35)
                            .rotationEffect(.degrees(15))
                    }
                    .offset(y: -size * 0.18)
                    // Head
                    Ellipse()
                        .fill(Color(red: 0.75, green: 0.58, blue: 0.42))
                        .frame(width: size * 0.7, height: size * 0.55)
                        .offset(y: size * 0.05)
                    // Snout
                    Ellipse()
                        .fill(Color(red: 0.88, green: 0.78, blue: 0.68))
                        .frame(width: size * 0.35, height: size * 0.22)
                        .offset(y: size * 0.18)
                    // Eyes
                    HStack(spacing: size * 0.18) {
                        Circle().fill(Color(red: 0.18, green: 0.12, blue: 0.08))
                            .frame(width: size * 0.12, height: size * 0.12)
                        Circle().fill(Color(red: 0.18, green: 0.12, blue: 0.08))
                            .frame(width: size * 0.12, height: size * 0.12)
                    }
                    .offset(y: -size * 0.02)
                    // Nose
                    Ellipse()
                        .fill(Color(red: 0.15, green: 0.1, blue: 0.1))
                        .frame(width: size * 0.15, height: size * 0.1)
                        .offset(y: size * 0.14)

                case .cat:
                    // Gray gradient with cat face
                    LinearGradient(
                        colors: [
                            Color(red: 0.72, green: 0.72, blue: 0.78),
                            Color(red: 0.6, green: 0.6, blue: 0.68)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    // Ears
                    HStack(spacing: size * 0.32) {
                        MiniCatEar()
                            .fill(Color(red: 0.5, green: 0.5, blue: 0.55))
                            .frame(width: size * 0.28, height: size * 0.3)
                            .rotationEffect(.degrees(-8))
                        MiniCatEar()
                            .fill(Color(red: 0.5, green: 0.5, blue: 0.55))
                            .frame(width: size * 0.28, height: size * 0.3)
                            .rotationEffect(.degrees(8))
                            .scaleEffect(x: -1)
                    }
                    .offset(y: -size * 0.22)
                    // Head
                    Ellipse()
                        .fill(Color(red: 0.58, green: 0.58, blue: 0.65))
                        .frame(width: size * 0.7, height: size * 0.55)
                        .offset(y: size * 0.08)
                    // Eyes
                    HStack(spacing: size * 0.18) {
                        Ellipse().fill(Color(red: 0.4, green: 0.6, blue: 0.35))
                            .frame(width: size * 0.15, height: size * 0.18)
                        Ellipse().fill(Color(red: 0.4, green: 0.6, blue: 0.35))
                            .frame(width: size * 0.15, height: size * 0.18)
                    }
                    .offset(y: size * 0.02)
                    // Nose
                    MiniCatNose()
                        .fill(Color(red: 0.85, green: 0.6, blue: 0.6))
                        .frame(width: size * 0.12, height: size * 0.08)
                        .offset(y: size * 0.18)
                }
            }
        }
        .clipShape(Circle())
    }
}

// Mini shapes for profile pictures
private struct MiniMountain: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct MiniTree: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Simple pine tree
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.85))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.1, y: rect.maxY * 0.85))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.1, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.1, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.1, y: rect.maxY * 0.85))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY * 0.85))
        path.closeSubpath()
        return path
    }
}

private struct MiniCatEar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct MiniCatNose: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Compact Feed Post (fits better in phone mockup)

private struct CompactFeedPost: View {
    let postType: PostImageType
    let index: Int

    private var likeCount: String {
        ["1,247", "892", "3.4k", "567", "2,103", "438"][index % 6]
    }

    private var usernameWidth: CGFloat {
        [45, 55, 40, 50, 60, 42][index % 6]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User header row
            HStack(spacing: 6) {
                // Profile pic with story ring
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.3, blue: 0.5), Color(red: 1.0, green: 0.6, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 22, height: 22)
                    .overlay(
                        ProfilePicImage(type: postType)
                            .frame(width: 18, height: 18)
                    )

                // Username placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.7))
                    .frame(width: usernameWidth, height: 7)

                Spacer()

                Image(systemName: "ellipsis")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            // Post image - clipart style
            PostImage(type: postType)
                .frame(height: 130)

            // Action bar
            HStack(spacing: 10) {
                Image(systemName: "heart")
                Image(systemName: "bubble.right")
                Image(systemName: "paperplane")
                Spacer()
                Image(systemName: "bookmark")
            }
            .font(.system(size: 13))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.top, 7)
            .padding(.bottom, 4)

            // Like count
            Text("\(likeCount) likes")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.bottom, 3)

            // Caption line
            HStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 35, height: 6)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 70, height: 6)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(white: 0.08))
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

                    Text("Complete your morning routine\nto unlock Instagram")
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

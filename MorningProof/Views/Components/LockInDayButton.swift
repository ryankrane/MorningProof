import SwiftUI

// MARK: - Liquid Progress Shape

/// Custom shape with a wavy leading edge for liquid "charging" effect
struct LiquidProgressShape: Shape {
    var progress: CGFloat
    var wavePhase: CGFloat
    var waveAmplitude: CGFloat  // Scales: 2pt at start → 8pt at end

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(progress, AnimatablePair(wavePhase, waveAmplitude)) }
        set {
            progress = newValue.first
            wavePhase = newValue.second.first
            waveAmplitude = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let fillWidth = rect.width * progress
        guard fillWidth > 0 else { return path }

        let cornerRadius = rect.height / 2

        // Start at bottom-left with rounded corner
        path.move(to: CGPoint(x: 0, y: rect.height - cornerRadius))

        // Left rounded corner (bottom)
        path.addArc(
            center: CGPoint(x: cornerRadius, y: rect.height - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: fillWidth, y: rect.height))

        // Wavy leading edge (moving upward)
        let waveSteps = 20
        for i in stride(from: waveSteps, through: 0, by: -1) {
            let stepY = rect.height * CGFloat(i) / CGFloat(waveSteps)
            let waveOffset = sin((CGFloat(i) / CGFloat(waveSteps)) * .pi * 3 + wavePhase) * waveAmplitude
            let x = fillWidth + waveOffset
            path.addLine(to: CGPoint(x: max(0, x), y: stepY))
        }

        // Top edge back to left
        path.addLine(to: CGPoint(x: cornerRadius, y: 0))

        // Left rounded corner (top)
        path.addArc(
            center: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(180),
            clockwise: true
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Lock In Day Button

struct LockInDayButton: View {
    let isEnabled: Bool           // hasCompletedAllHabitsToday
    let isLockedIn: Bool          // isDayLockedIn
    let onLockIn: () -> Void      // Callback when lock-in completes

    @Environment(\.colorScheme) private var colorScheme

    @State private var holdProgress: CGFloat = 0
    @State private var isHolding: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var shimmerOffset: CGFloat = -1.5
    @State private var lockedGlowPulse: CGFloat = 0.3
    @State private var brushedShimmerOffset: CGFloat = -1.0
    @State private var holdStartTime: Date?
    @State private var holdTimer: Timer?
    @State private var lastHapticTime: Date = Date.distantPast  // For frequency-based haptics
    @State private var chargingShakeX: CGFloat = 0  // Enhanced X shake
    @State private var chargingShakeY: CGFloat = 0  // Enhanced Y shake
    @State private var chargingShakeRotation: Double = 0  // Subtle rotation shake
    @State private var wavePhase: CGFloat = 0  // Liquid wave animation phase
    @State private var waveTimer: Timer?  // Continuous wave animation
    @State private var textScale: CGFloat = 1.0  // Text bounce animation
    @State private var textOffset: CGFloat = 0  // Text bounce offset

    private let holdDuration: Double = 2.75  // Deliberate, earned action (2.5-3.0s range)
    private let buttonWidth: CGFloat = 220
    private let buttonHeight: CGFloat = 56
    private let shimmerDuration: Double = 4.5  // Slow, meditative gleam (4-5s)

    // Transparent gold for enabled state - clear with subtle gold tint
    private var enabledBackground: some ShapeStyle {
        MPColors.accentGold.opacity(0.15)
    }

    // Subtle purple for disabled state - matches app purple but transparent to show "locked"
    private var disabledGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.15), Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.1)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // Shiny gold gradient for locked state - different in light vs dark mode
    private var lockedGoldGradient: LinearGradient {
        if colorScheme == .dark {
            // Dark mode: Muted, metallic brushed gold tones (deeper, less saturated)
            return LinearGradient(
                colors: [
                    Color(red: 0.72, green: 0.58, blue: 0.30),  // Deep brushed gold
                    Color(red: 0.65, green: 0.52, blue: 0.25),  // Muted gold
                    Color(red: 0.75, green: 0.60, blue: 0.32),  // Warm metallic
                    Color(red: 0.68, green: 0.55, blue: 0.28)   // Deep gold
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Light mode: Vibrant celebratory gold
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.84, blue: 0.0),    // Bright gold
                    MPColors.accentGold,                        // Standard gold
                    Color(red: 1.0, green: 0.75, blue: 0.2),    // Warm gold
                    MPColors.accentGold
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        ZStack {
            // Outer glow (enabled state or locked state)
            if isEnabled && !isLockedIn {
                Capsule()
                    .fill(MPColors.accentGold.opacity(glowOpacity * 0.5))
                    .frame(width: buttonWidth + 20, height: buttonHeight + 16)
                    .blur(radius: 20)
            } else if isLockedIn {
                // Golden glow for locked state - pulsing celebration effect
                Capsule()
                    .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(lockedGlowPulse))
                    .frame(width: buttonWidth + 24, height: buttonHeight + 20)
                    .blur(radius: 25)
            }

            // Background capsule
            Capsule()
                .fill(backgroundColor)
                .frame(width: buttonWidth, height: buttonHeight)

            // Progress fill (while holding) - liquid gold with wavy edge
            if isHolding && isEnabled && !isLockedIn {
                ZStack(alignment: .leading) {
                    // Liquid gold progress with wavy leading edge
                    LiquidProgressShape(
                        progress: holdProgress,
                        wavePhase: wavePhase,
                        waveAmplitude: 2 + holdProgress * 6  // 2pt at start → 8pt at end
                    )
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.75, blue: 0.0).opacity(0.65),
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.55),
                                MPColors.accentGold.opacity(0.45)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: buttonWidth, height: buttonHeight)

                    // Glowing edge at progress front - larger glow in dark mode
                    if holdProgress > 0.05 {
                        Circle()
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.45 : 0.35))
                            .frame(width: colorScheme == .dark ? 28 : 24, height: colorScheme == .dark ? 28 : 24)
                            .blur(radius: colorScheme == .dark ? 14 : 10)
                            .offset(x: (buttonWidth * holdProgress) - (colorScheme == .dark ? 14 : 12))
                    }
                }
                .frame(width: buttonWidth, height: buttonHeight)
                .clipShape(Capsule())
            }

            // Shimmer effect - continuous, slow-moving premium gleam
            // Fades out when user touches the button to focus on progress fill
            if isEnabled && !isLockedIn {
                Capsule()
                    .fill(Color.clear)
                    .frame(width: buttonWidth, height: buttonHeight)
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: Color.white.opacity(0.06), location: 0.25),
                                        .init(color: Color.white.opacity(0.20), location: 0.5),  // Hot center
                                        .init(color: Color.white.opacity(0.06), location: 0.75),
                                        .init(color: .clear, location: 1.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: buttonWidth * 0.4, height: buttonHeight * 2.5)
                            .rotationEffect(.degrees(20))
                            .offset(x: shimmerOffset * buttonWidth)
                    )
                    .clipShape(Capsule())  // Perfect clip to button shape
                    .opacity(isHolding || holdProgress > 0 ? 0 : 1)  // Fade out when pressing
                    .animation(.easeOut(duration: 0.15), value: isHolding)
            }

            // Brushed metal shimmer overlay - horizontal striation effect for dark mode locked state
            if isLockedIn && colorScheme == .dark {
                Capsule()
                    .fill(Color.clear)
                    .frame(width: buttonWidth, height: buttonHeight)
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0.0),
                                        .init(color: Color.white.opacity(0.04), location: 0.3),
                                        .init(color: Color.white.opacity(0.12), location: 0.5),  // Subtle center
                                        .init(color: Color.white.opacity(0.04), location: 0.7),
                                        .init(color: .clear, location: 1.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: buttonWidth * 0.3, height: buttonHeight * 2)
                            .rotationEffect(.degrees(15))
                            .offset(x: brushedShimmerOffset * buttonWidth)
                    )
                    .clipShape(Capsule())
            }

            // Border - thicker for enabled state to stand out
            Capsule()
                .stroke(
                    isHolding ? MPColors.accentGold : borderColor,
                    lineWidth: isHolding ? 3 : (isEnabled && !isLockedIn ? 2.5 : 2)
                )
                .frame(width: buttonWidth, height: buttonHeight)

            // Content: Icon + Text
            HStack(spacing: MPSpacing.md) {
                // Lock icon
                Image(systemName: isLockedIn ? "lock.fill" : "lock.open")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .scaleEffect(x: isLockedIn ? 1 : -1, y: 1)
                    .scaleEffect(textScale)
                    .offset(y: textOffset)

                // Label text with bounce animation on lock-in
                Text(buttonText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .scaleEffect(textScale)
                    .offset(y: textOffset)
            }
        }
        .frame(width: buttonWidth, height: buttonHeight)
        .offset(x: chargingShakeX, y: chargingShakeY)  // Enhanced charging shake
        .rotationEffect(.degrees(chargingShakeRotation))  // Subtle rotation shake
        .scaleEffect(isHolding ? 0.97 : pulseScale)  // Gentle physical compression feel
        .animation(.easeOut(duration: 0.12), value: isHolding)
        .opacity(isEnabled || isLockedIn ? 1.0 : 0.6)
        .gesture(
            isEnabled && !isLockedIn ? holdGesture : nil
        )
        .onAppear {
            if isEnabled && !isLockedIn {
                startIdleAnimations()
            }
            if isLockedIn {
                startLockedAnimations()
            }
        }
        .onChange(of: isEnabled) { _, newValue in
            if newValue && !isLockedIn {
                startIdleAnimations()
            }
        }
        .onChange(of: isLockedIn) { _, newValue in
            if newValue {
                startLockedAnimations()
            }
        }
    }

    // MARK: - Computed Properties

    private var backgroundColor: some ShapeStyle {
        if isLockedIn {
            return AnyShapeStyle(lockedGoldGradient)
        } else if isEnabled {
            return AnyShapeStyle(enabledBackground)
        } else {
            return AnyShapeStyle(disabledGradient)
        }
    }

    private var borderColor: Color {
        if isLockedIn {
            return MPColors.accentGold
        } else if isEnabled {
            return MPColors.accentGold  // Strong gold border for enabled state
        } else {
            return Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.3)
        }
    }

    private var iconColor: Color {
        if isLockedIn {
            return .white
        } else if isEnabled {
            return MPColors.accentGold  // Gold text/icon on transparent background
        } else {
            return Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.5)
        }
    }

    private var buttonText: String {
        if isLockedIn {
            return "Day Locked In"
        } else if isEnabled {
            return "Hold to Lock In"
        } else {
            return "Complete all habits"
        }
    }

    // MARK: - Gestures

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isHolding {
                    startHold()
                }
            }
            .onEnded { _ in
                endHold()
            }
    }

    // MARK: - Hold Logic

    private func startHold() {
        isHolding = true
        holdProgress = 0
        holdStartTime = Date()
        lastHapticTime = Date()

        // Initial haptic - satisfying "click down"
        HapticManager.shared.medium()

        // Animate progress fill with linear curve for immediate visual feedback
        // User sees progress right away, making the hold feel responsive
        withAnimation(.linear(duration: holdDuration)) {
            holdProgress = 1.0
        }

        // Start wave animation timer for liquid effect
        waveTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            wavePhase += 0.15  // Continuous wave motion
        }

        // Start timer for frequency-based haptics, sinusoidal shake, and completion check
        let tickInterval: Double = 0.016  // ~60fps for smooth shake
        holdTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { timer in
            guard isHolding, let startTime = holdStartTime else {
                timer.invalidate()
                return
            }

            let now = Date()
            let elapsed = now.timeIntervalSince(startTime)
            let progress = min(elapsed / holdDuration, 1.0)

            // Frequency-based haptics: interval decreases as progress increases
            // 0% → 400ms, 50% → 150ms, 90%+ → 60ms
            let baseInterval = 0.4 * pow(1 - progress, 2) + 0.06  // Quadratic curve
            let timeSinceLastHaptic = now.timeIntervalSince(lastHapticTime)

            if timeSinceLastHaptic >= baseInterval {
                // Intensity also increases: 0.3 at start → 1.0 at end
                let hapticIntensity = 0.3 + progress * 0.7
                HapticManager.shared.chargingTap(intensity: hapticIntensity)
                lastHapticTime = now
            }

            // Enhanced sinusoidal shake - starts at 10%, steeper intensity curve
            if progress > 0.1 {
                let normalizedProgress = (progress - 0.1) / 0.9
                let intensity = pow(normalizedProgress, 2.5) * 5.0  // Steeper curve, max 5pt

                // Frequency increases from 10Hz to 30Hz as progress increases
                let frequency = 10.0 + (progress * 20.0)

                // Sinusoidal oscillation for predictable "vibrating" feel
                chargingShakeX = intensity * sin(elapsed * frequency)
                chargingShakeY = intensity * cos(elapsed * frequency * 1.3) * 0.4  // Subtle Y
                chargingShakeRotation = intensity * sin(elapsed * frequency * 0.7) * 0.3  // Very subtle rotation
            } else {
                chargingShakeX = 0
                chargingShakeY = 0
                chargingShakeRotation = 0
            }

            // Check if hold duration is complete
            if elapsed >= holdDuration {
                timer.invalidate()
                completeHold()
            }
        }
    }

    private func endHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        waveTimer?.invalidate()
        waveTimer = nil

        if isHolding {
            // Check if hold was long enough
            if let startTime = holdStartTime {
                let elapsed = Date().timeIntervalSince(startTime)
                if elapsed >= holdDuration {
                    completeHold()
                    return
                }
            }
            // Not long enough - cancel with haptic
            cancelHold()
        }
    }

    private func completeHold() {
        guard isHolding else { return }

        isHolding = false
        holdProgress = 0
        holdStartTime = nil
        wavePhase = 0
        waveTimer?.invalidate()
        waveTimer = nil

        // Reset shake
        chargingShakeX = 0
        chargingShakeY = 0
        chargingShakeRotation = 0

        // Text bounce animation - start scaled down and offset below
        textScale = 0.3
        textOffset = 20
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            textScale = 1.0
            textOffset = 0
        }

        // Double-thud success haptic (UINotificationFeedbackGenerator.success)
        HapticManager.shared.success()
        onLockIn()
    }

    private func cancelHold() {
        isHolding = false
        holdStartTime = nil
        wavePhase = 0
        waveTimer?.invalidate()
        waveTimer = nil

        // Reset shake
        chargingShakeX = 0
        chargingShakeY = 0
        chargingShakeRotation = 0

        // Spring snap-back - bouncy, satisfying return to zero
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            holdProgress = 0
        }

        // Light haptic feedback on cancel
        HapticManager.shared.light()
    }

    // MARK: - Idle Animations

    private func startIdleAnimations() {
        // Scale pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.02
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }

        // Start continuous shimmer - no delays, always moving
        startContinuousShimmer()
    }

    /// Continuous shimmer animation with no pauses - meditative, premium feel
    private func startContinuousShimmer() {
        shimmerOffset = -1.5

        // Continuous linear animation that repeats forever
        // The shimmer moves at a constant, slow pace for a meditative feel
        withAnimation(.linear(duration: shimmerDuration).repeatForever(autoreverses: false)) {
            shimmerOffset = 1.5
        }
    }

    private func startLockedAnimations() {
        // Celebratory glow pulse - subtle breathing effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            lockedGlowPulse = 0.5
        }

        // Brushed shimmer for dark mode - subtle metallic gleam
        if colorScheme == .dark {
            brushedShimmerOffset = -1.0
            withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                brushedShimmerOffset = 1.0
            }
        }
    }
}

#Preview {
    VStack(spacing: MPSpacing.xxxl) {
        LockInDayButton(isEnabled: false, isLockedIn: false, onLockIn: {})
        LockInDayButton(isEnabled: true, isLockedIn: false, onLockIn: {})
        LockInDayButton(isEnabled: true, isLockedIn: true, onLockIn: {})
    }
    .padding()
    .background(MPColors.background)
}

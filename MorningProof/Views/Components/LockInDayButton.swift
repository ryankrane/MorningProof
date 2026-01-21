import SwiftUI

// MARK: - Clean Progress Shape

/// Simple capsule-clipped rectangle for clean fill effect
struct CleanProgressShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let fillWidth = rect.width * progress
        guard fillWidth > 0 else { return path }

        // Simple rectangle - will be clipped by capsule
        path.addRect(CGRect(x: 0, y: 0, width: fillWidth, height: rect.height))

        return path
    }
}

// MARK: - Lock In Day Button

struct LockInDayButton: View {
    let isEnabled: Bool           // hasCompletedAllHabitsToday
    let isLockedIn: Bool          // isDayLockedIn
    let onLockIn: () -> Void      // Callback when lock-in completes

    // Dynamic sizing (with defaults for backward compatibility)
    var buttonWidth: CGFloat = 220
    var buttonHeight: CGFloat = 56

    @Environment(\.colorScheme) private var colorScheme

    @State private var holdProgress: CGFloat = 0
    @State private var isHolding: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    // shimmerOffset removed - now using TimelineView for smooth continuous animation
    @State private var lockedGlowPulse: CGFloat = 0.3
    // brushedShimmerOffset removed - now using TimelineView for smooth continuous animation
    @State private var holdStartTime: Date?
    @State private var holdTimer: Timer?
    @State private var lastHapticTime: Date = Date.distantPast  // For frequency-based haptics
    @State private var chargingShakeX: CGFloat = 0  // Enhanced X shake
    @State private var chargingShakeY: CGFloat = 0  // Enhanced Y shake
    @State private var chargingShakeRotation: Double = 0  // Subtle rotation shake
    @State private var textScale: CGFloat = 1.0  // Text bounce animation
    @State private var textOffset: CGFloat = 0  // Text bounce offset

    private let holdDuration: Double = 2.75  // Deliberate, earned action (2.5-3.0s range)
    private let shimmerDuration: Double = 3.0  // Premium gleam (slightly faster)

    // Font size scales with button height
    private var fontSize: CGFloat {
        // Base: 16pt at 56pt height, scale proportionally down to 14pt at 44pt
        let minSize: CGFloat = 14
        let maxSize: CGFloat = 16
        let ratio = (buttonHeight - 44) / (56 - 44) // 0 at 44pt, 1 at 56pt
        return minSize + (maxSize - minSize) * min(1, max(0, ratio))
    }

    private var iconSize: CGFloat {
        // Base: 22pt at 56pt height, scale proportionally down to 18pt at 44pt
        let minSize: CGFloat = 18
        let maxSize: CGFloat = 22
        let ratio = (buttonHeight - 44) / (56 - 44)
        return minSize + (maxSize - minSize) * min(1, max(0, ratio))
    }

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

            // Progress fill (while holding) - clean gold fill with soft glowing edge
            if isHolding && isEnabled && !isLockedIn {
                ZStack(alignment: .leading) {
                    // Clean gold progress fill
                    CleanProgressShape(progress: holdProgress)
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

                    // Soft glowing edge at progress front
                    if holdProgress > 0.03 {
                        // Vertical glow bar at leading edge
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.5 : 0.4))
                            .frame(width: 8, height: buttonHeight * 0.7)
                            .blur(radius: colorScheme == .dark ? 10 : 8)
                            .offset(x: (buttonWidth * holdProgress) - 4)
                    }
                }
                .frame(width: buttonWidth, height: buttonHeight)
                .clipShape(Capsule())
            }

            // Shimmer effect - continuous, smooth-looping premium gleam
            // Uses TimelineView for perfectly smooth continuous animation
            if isEnabled && !isLockedIn {
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    // Calculate position: loops from -1.5 to 1.5 over shimmerDuration
                    let progress = (time.truncatingRemainder(dividingBy: shimmerDuration)) / shimmerDuration
                    let offset = -1.5 + (progress * 3.0)  // -1.5 to 1.5

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
                                            .init(color: Color.white.opacity(0.20), location: 0.5),
                                            .init(color: Color.white.opacity(0.06), location: 0.75),
                                            .init(color: .clear, location: 1.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: buttonWidth * 0.4, height: buttonHeight * 2.5)
                                .rotationEffect(.degrees(20))
                                .offset(x: offset * buttonWidth)
                        )
                        .clipShape(Capsule())
                }
                .opacity(isHolding || holdProgress > 0 ? 0 : 1)
                .animation(.easeOut(duration: 0.15), value: isHolding)
            }

            // Brushed metal shimmer overlay - horizontal striation effect for locked state
            // Uses TimelineView for smooth continuous animation
            if isLockedIn {
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let lockedShimmerDuration = 3.5  // Faster than enabled shimmer
                    let progress = (time.truncatingRemainder(dividingBy: lockedShimmerDuration)) / lockedShimmerDuration
                    let offset = -1.0 + (progress * 2.0)  // -1.0 to 1.0

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
                                            .init(color: Color.white.opacity(0.12), location: 0.5),
                                            .init(color: Color.white.opacity(0.04), location: 0.7),
                                            .init(color: .clear, location: 1.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: buttonWidth * 0.3, height: buttonHeight * 2)
                                .rotationEffect(.degrees(15))
                                .offset(x: offset * buttonWidth)
                        )
                        .clipShape(Capsule())
                }
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
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .scaleEffect(x: isLockedIn ? 1 : -1, y: 1)
                    .scaleEffect(textScale)
                    .offset(y: textOffset)

                // Label text with bounce animation on lock-in
                Text(buttonText)
                    .font(.system(size: fontSize, weight: .semibold))
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

        // Shimmer now uses TimelineView - no manual animation needed
    }

    private func startLockedAnimations() {
        // Celebratory glow pulse - subtle breathing effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            lockedGlowPulse = 0.5
        }
        // Shimmer now uses TimelineView - no manual animation needed
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

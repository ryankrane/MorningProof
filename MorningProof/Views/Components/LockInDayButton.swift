import SwiftUI

struct LockInDayButton: View {
    let isEnabled: Bool           // hasCompletedAllHabitsToday
    let isLockedIn: Bool          // isDayLockedIn
    let onLockIn: () -> Void      // Callback when lock-in completes

    @State private var holdProgress: CGFloat = 0
    @State private var isHolding: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var lockedGlowPulse: CGFloat = 0.4
    @State private var holdStartTime: Date?
    @State private var holdTimer: Timer?

    private let holdDuration: Double = 0.75
    private let buttonWidth: CGFloat = 220
    private let buttonHeight: CGFloat = 56

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

    // Shiny gold gradient for locked state - more vibrant and celebratory
    private var lockedGoldGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.84, blue: 0.0),      // Bright gold
                MPColors.accentGold,                          // Standard gold
                Color(red: 1.0, green: 0.75, blue: 0.2),      // Warm gold
                MPColors.accentGold
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

            // Progress fill (while holding) - fills from left
            if isHolding && isEnabled && !isLockedIn {
                GeometryReader { geo in
                    Capsule()
                        .fill(MPColors.accentGold.opacity(0.4))
                        .frame(width: geo.size.width * holdProgress, height: buttonHeight)
                }
                .frame(width: buttonWidth, height: buttonHeight)
                .clipShape(Capsule())
            }

            // Shimmer effect (enabled state) - full width diagonal sweep
            if isEnabled && !isLockedIn && !isHolding {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.2),
                                .white.opacity(0.3),
                                .white.opacity(0.2),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: buttonWidth * 0.6, height: buttonHeight * 2)
                    .rotationEffect(.degrees(25))
                    .offset(x: shimmerOffset * buttonWidth)
                    .mask(
                        Capsule()
                            .frame(width: buttonWidth, height: buttonHeight)
                    )
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

                // Label text
                Text(buttonText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
        }
        .frame(width: buttonWidth, height: buttonHeight)
        .scaleEffect(isHolding ? 0.98 : pulseScale)
        .animation(.easeInOut(duration: 0.15), value: isHolding)
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

        // Initial haptic
        HapticManager.shared.light()

        // Animate progress
        withAnimation(.linear(duration: holdDuration)) {
            holdProgress = 1.0
        }

        // Start timer for haptic ticks and completion check
        let tickInterval = 0.1
        holdTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { timer in
            guard isHolding, let startTime = holdStartTime else {
                timer.invalidate()
                return
            }

            let elapsed = Date().timeIntervalSince(startTime)

            // Haptic tick every ~0.15s
            if Int(elapsed / 0.15) > Int((elapsed - tickInterval) / 0.15) {
                HapticManager.shared.light()
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
        HapticManager.shared.success()
        onLockIn()
    }

    private func cancelHold() {
        isHolding = false
        holdStartTime = nil

        // Animate progress back to 0
        withAnimation(.easeOut(duration: 0.2)) {
            holdProgress = 0
        }

        // Haptic feedback on cancel
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

        // Shimmer sweep
        shimmerOffset = -1.2
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            shimmerOffset = 1.2
        }
    }

    private func startLockedAnimations() {
        // Celebratory glow pulse - subtle breathing effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            lockedGlowPulse = 0.7
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

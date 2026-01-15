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
    @State private var lockedShimmerOffset: CGFloat = -1.0
    @State private var lockedGlowPulse: CGFloat = 0.4

    private let holdDuration: Double = 0.75
    private let buttonWidth: CGFloat = 220
    private let buttonHeight: CGFloat = 56

    // Gold gradient for enabled state
    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [MPColors.accentGold, MPColors.accent],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // Muted purple-gray for disabled state
    private var disabledGradient: LinearGradient {
        LinearGradient(
            colors: [MPColors.surfaceSecondary, MPColors.border],
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

            // Shimmer effect (enabled state)
            if isEnabled && !isLockedIn && !isHolding {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.15), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 60, height: buttonHeight)
                    .offset(x: shimmerOffset * (buttonWidth / 2))
                    .clipShape(Capsule().size(width: buttonWidth, height: buttonHeight))
            }

            // Celebratory shimmer for locked state - more prominent shine
            if isLockedIn {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.35), .white.opacity(0.5), .white.opacity(0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 80, height: buttonHeight)
                    .offset(x: lockedShimmerOffset * (buttonWidth / 2))
                    .clipShape(Capsule().size(width: buttonWidth, height: buttonHeight))
            }

            // Border
            Capsule()
                .stroke(
                    isHolding ? MPColors.accentGold : borderColor,
                    lineWidth: isHolding ? 3 : 2
                )
                .frame(width: buttonWidth, height: buttonHeight)

            // Content: Icon + Text
            HStack(spacing: MPSpacing.md) {
                // Lock icon
                Image(systemName: isLockedIn ? "lock.fill" : "lock.open")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .scaleEffect(x: isLockedIn ? 1 : -1, y: 1)
                    .rotationEffect(.degrees(isLockedIn ? -15 : 0))

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
            isEnabled && !isLockedIn ? longPressGesture : nil
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
            return AnyShapeStyle(goldGradient)
        } else {
            return AnyShapeStyle(disabledGradient)
        }
    }

    private var borderColor: Color {
        if isLockedIn {
            return MPColors.accentGold
        } else if isEnabled {
            return MPColors.accentGold.opacity(0.6)
        } else {
            return MPColors.border
        }
    }

    private var iconColor: Color {
        if isLockedIn || isEnabled {
            return .white
        } else {
            return MPColors.textMuted
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

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: holdDuration)
            .onChanged { _ in
                if !isHolding {
                    startHold()
                }
            }
            .onEnded { _ in
                completeHold()
            }
            .simultaneously(with:
                DragGesture(minimumDistance: 0)
                    .onEnded { _ in
                        if isHolding && holdProgress < 1.0 {
                            cancelHold()
                        }
                    }
            )
    }

    // MARK: - Hold Logic

    private func startHold() {
        isHolding = true
        HapticManager.shared.light()

        withAnimation(.linear(duration: holdDuration)) {
            holdProgress = 1.0
        }
        startHoldTicks()
    }

    private func completeHold() {
        guard isHolding && holdProgress >= 0.95 else {
            cancelHold()
            return
        }

        isHolding = false
        holdProgress = 0
        onLockIn()
    }

    private func cancelHold() {
        isHolding = false
        withAnimation(.easeOut(duration: 0.2)) {
            holdProgress = 0
        }
        HapticManager.shared.light()
    }

    private func startHoldTicks() {
        let tickInterval = 0.15
        let tickCount = Int(holdDuration / tickInterval)

        for i in 1..<tickCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * tickInterval) {
                if isHolding {
                    HapticManager.shared.light()
                }
            }
        }
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
        shimmerOffset = -1.0
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            shimmerOffset = 1.0
        }
    }

    private func startLockedAnimations() {
        // Celebratory glow pulse - subtle breathing effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            lockedGlowPulse = 0.7
        }

        // Slower, more elegant shimmer for locked state
        lockedShimmerOffset = -1.5
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            lockedShimmerOffset = 1.5
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

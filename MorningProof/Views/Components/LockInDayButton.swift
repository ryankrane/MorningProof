import SwiftUI

struct LockInDayButton: View {
    let isEnabled: Bool           // hasCompletedAllHabitsToday
    let isLockedIn: Bool          // isDayLockedIn
    let onLockIn: () -> Void      // Callback when lock-in completes

    @State private var holdProgress: CGFloat = 0
    @State private var isHolding: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3

    private let holdDuration: Double = 0.75  // seconds
    private let buttonSize: CGFloat = 80
    private let ringLineWidth: CGFloat = 4

    // Gold gradient for enabled state
    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [MPColors.accentGold, MPColors.accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(spacing: MPSpacing.sm) {
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundColor)
                    .frame(width: buttonSize, height: buttonSize)

                // Glow effect (enabled state only)
                if isEnabled && !isLockedIn {
                    Circle()
                        .fill(MPColors.accentGold.opacity(glowOpacity))
                        .frame(width: buttonSize + 20, height: buttonSize + 20)
                        .blur(radius: 15)
                }

                // Progress ring (while holding)
                if isHolding && isEnabled && !isLockedIn {
                    Circle()
                        .trim(from: 0, to: holdProgress)
                        .stroke(
                            MPColors.accentGold,
                            style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                        )
                        .frame(width: buttonSize + ringLineWidth, height: buttonSize + ringLineWidth)
                        .rotationEffect(.degrees(-90))
                }

                // Lock icon
                Image(systemName: isLockedIn ? "lock.fill" : "lock.open")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .rotationEffect(.degrees(isLockedIn ? -15 : 0))
            }
            .scaleEffect(isHolding ? 0.97 : pulseScale)
            .animation(.easeInOut(duration: 0.15), value: isHolding)

            // Label
            Text(labelText)
                .font(MPFont.labelMedium())
                .foregroundColor(labelColor)
        }
        .opacity(isEnabled || isLockedIn ? 1.0 : 0.5)
        .gesture(
            isEnabled && !isLockedIn ? longPressGesture : nil
        )
        .onAppear {
            if isEnabled && !isLockedIn {
                startIdlePulse()
            }
        }
        .onChange(of: isEnabled) { _, newValue in
            if newValue && !isLockedIn {
                startIdlePulse()
            }
        }
    }

    // MARK: - Computed Properties

    private var backgroundColor: some ShapeStyle {
        if isLockedIn {
            return AnyShapeStyle(MPColors.accentGold)
        } else if isEnabled {
            return AnyShapeStyle(goldGradient)
        } else {
            return AnyShapeStyle(MPColors.surfaceSecondary)
        }
    }

    private var iconColor: Color {
        if isLockedIn || isEnabled {
            return .white
        } else {
            return MPColors.textMuted
        }
    }

    private var labelText: String {
        if isLockedIn {
            return "Day Locked In"
        } else if isEnabled {
            return "Hold to Lock In"
        } else {
            return "Complete all habits"
        }
    }

    private var labelColor: Color {
        if isLockedIn {
            return MPColors.accentGold
        } else if isEnabled {
            return MPColors.textPrimary
        } else {
            return MPColors.textMuted
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

        // Animate progress ring
        withAnimation(.linear(duration: holdDuration)) {
            holdProgress = 1.0
        }

        // Tick haptics during hold
        startHoldTicks()
    }

    private func completeHold() {
        guard isHolding && holdProgress >= 0.95 else {
            cancelHold()
            return
        }

        isHolding = false
        holdProgress = 0

        // Trigger lock-in
        onLockIn()
    }

    private func cancelHold() {
        isHolding = false
        withAnimation(.easeOut(duration: 0.2)) {
            holdProgress = 0
        }
    }

    private func startHoldTicks() {
        // Tick every 0.15s during hold
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

    // MARK: - Idle Animation

    private func startIdlePulse() {
        // Scale pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.02
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowOpacity = 0.5
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

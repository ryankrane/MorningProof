import SwiftUI

/// A ButtonStyle that enables "hold to complete" functionality without blocking ScrollView gestures.
/// Uses the isPressed state from ButtonStyle which integrates properly with UIKit's gesture system.
struct HoldToCompleteButtonStyle: ButtonStyle {
    let holdDuration: TimeInterval
    @Binding var progress: CGFloat
    let onHoldStarted: () -> Void
    let onHoldCompleted: () -> Void
    let onHoldCancelled: () -> Void

    init(
        holdDuration: TimeInterval = 1.0,
        progress: Binding<CGFloat>,
        onHoldStarted: @escaping () -> Void = {},
        onHoldCompleted: @escaping () -> Void,
        onHoldCancelled: @escaping () -> Void = {}
    ) {
        self.holdDuration = holdDuration
        self._progress = progress
        self.onHoldStarted = onHoldStarted
        self.onHoldCompleted = onHoldCompleted
        self.onHoldCancelled = onHoldCancelled
    }

    @State private var holdStartDate: Date?
    @State private var holdTimer: Timer?
    @State private var didComplete = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    startHold()
                } else {
                    endHold()
                }
            }
    }

    private func startHold() {
        didComplete = false
        holdStartDate = Date()
        progress = 0
        onHoldStarted()

        // Initial haptic
        HapticManager.shared.lightTap()

        // Start timer to update progress
        let tickInterval = 0.02
        holdTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { timer in
            guard let startDate = holdStartDate else {
                timer.invalidate()
                return
            }

            let elapsed = Date().timeIntervalSince(startDate)
            let newProgress = min(elapsed / holdDuration, 1.0)

            // Update progress on main thread
            DispatchQueue.main.async {
                progress = CGFloat(newProgress)
            }

            // Haptic tick every ~0.2s
            if Int(elapsed / 0.2) > Int((elapsed - tickInterval) / 0.2) {
                HapticManager.shared.lightTap()
            }

            // Check if hold duration is complete
            if elapsed >= holdDuration {
                timer.invalidate()
                DispatchQueue.main.async {
                    completeHold()
                }
            }
        }
    }

    private func endHold() {
        holdTimer?.invalidate()
        holdTimer = nil

        guard !didComplete else { return }

        // Check if hold was long enough
        if let startDate = holdStartDate {
            let elapsed = Date().timeIntervalSince(startDate)
            if elapsed >= holdDuration {
                completeHold()
                return
            }
        }

        // Not long enough - cancel
        cancelHold()
    }

    private func completeHold() {
        guard !didComplete else { return }
        didComplete = true
        holdStartDate = nil
        progress = 0
        onHoldCompleted()
    }

    private func cancelHold() {
        holdStartDate = nil

        // Animate progress back to 0
        let currentProgress = progress
        let unwindDuration = Double(currentProgress) * 0.5 + 0.15
        withAnimation(.easeOut(duration: unwindDuration)) {
            progress = 0
        }

        onHoldCancelled()
        HapticManager.shared.lightTap()
    }
}

/// A view wrapper that makes any content hold-to-complete enabled without blocking scroll.
struct HoldToCompleteButton<Content: View>: View {
    let holdDuration: TimeInterval
    @Binding var progress: CGFloat
    let onHoldStarted: () -> Void
    let onHoldCompleted: () -> Void
    let onHoldCancelled: () -> Void
    let content: () -> Content

    init(
        holdDuration: TimeInterval = 1.0,
        progress: Binding<CGFloat>,
        onHoldStarted: @escaping () -> Void = {},
        onHoldCompleted: @escaping () -> Void,
        onHoldCancelled: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.holdDuration = holdDuration
        self._progress = progress
        self.onHoldStarted = onHoldStarted
        self.onHoldCompleted = onHoldCompleted
        self.onHoldCancelled = onHoldCancelled
        self.content = content
    }

    var body: some View {
        Button(action: {}) {
            content()
        }
        .buttonStyle(HoldToCompleteButtonStyle(
            holdDuration: holdDuration,
            progress: $progress,
            onHoldStarted: onHoldStarted,
            onHoldCompleted: onHoldCompleted,
            onHoldCancelled: onHoldCancelled
        ))
    }
}

/// A view modifier that conditionally wraps content in a hold-to-complete button.
/// When disabled, just passes through the content unchanged.
struct HoldToCompleteModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var progress: CGFloat
    let holdDuration: TimeInterval
    let onCompleted: () -> Void

    init(
        isEnabled: Bool,
        progress: Binding<CGFloat>,
        holdDuration: TimeInterval = 1.0,
        onCompleted: @escaping () -> Void
    ) {
        self.isEnabled = isEnabled
        self._progress = progress
        self.holdDuration = holdDuration
        self.onCompleted = onCompleted
    }

    func body(content: Content) -> some View {
        if isEnabled {
            Button(action: {}) {
                content
            }
            .buttonStyle(HoldToCompleteButtonStyle(
                holdDuration: holdDuration,
                progress: $progress,
                onHoldCompleted: onCompleted
            ))
        } else {
            content
        }
    }
}

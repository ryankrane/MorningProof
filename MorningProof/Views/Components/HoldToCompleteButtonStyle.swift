import SwiftUI

/// A view modifier that enables "hold to complete" functionality without blocking ScrollView gestures.
/// Uses DragGesture with simultaneousGesture and movement detection to allow scrolling.
struct HoldToCompleteModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var progress: CGFloat
    let holdDuration: TimeInterval
    let onCompleted: () -> Void

    // Movement threshold - if user moves more than this, they're scrolling
    private let scrollThreshold: CGFloat = 10

    @State private var isHolding = false
    @State private var holdStartDate: Date?
    @State private var holdTimer: Timer?
    @State private var startLocation: CGPoint?
    @State private var didComplete = false

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
            content
                // Empty tap gesture is a SwiftUI trick to allow scroll priority
                .onTapGesture {}
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleDragChanged(value)
                        }
                        .onEnded { _ in
                            handleDragEnded()
                        }
                )
        } else {
            content
        }
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        // First touch - record start location
        if startLocation == nil {
            startLocation = value.startLocation
            // Don't start hold immediately - wait a tiny bit to see if scrolling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                // Only start if we haven't been cancelled and haven't moved much
                if startLocation != nil && !didComplete {
                    startHold()
                }
            }
            return
        }

        // Check if user has moved too far (trying to scroll)
        if let start = startLocation {
            let distance = sqrt(
                pow(value.location.x - start.x, 2) +
                pow(value.location.y - start.y, 2)
            )
            if distance > scrollThreshold {
                // User is scrolling, cancel hold
                cancelHold()
            }
        }
    }

    private func handleDragEnded() {
        guard !didComplete else {
            // Reset for next use
            resetState()
            return
        }

        // Check if hold was long enough
        if isHolding, let startDate = holdStartDate {
            let elapsed = Date().timeIntervalSince(startDate)
            if elapsed >= holdDuration {
                completeHold()
                return
            }
        }

        // Not long enough or not holding - cancel
        if isHolding {
            cancelHold()
        } else {
            resetState()
        }
    }

    private func startHold() {
        guard !isHolding, !didComplete, startLocation != nil else { return }

        isHolding = true
        holdStartDate = Date()
        progress = 0

        // Initial haptic
        HapticManager.shared.lightTap()

        // Start timer to update progress
        let tickInterval = 0.02
        holdTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { timer in
            guard isHolding, let startDate = holdStartDate else {
                timer.invalidate()
                return
            }

            let elapsed = Date().timeIntervalSince(startDate)
            let newProgress = min(elapsed / holdDuration, 1.0)

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

    private func completeHold() {
        guard !didComplete else { return }
        didComplete = true

        holdTimer?.invalidate()
        holdTimer = nil
        isHolding = false
        holdStartDate = nil
        progress = 0

        onCompleted()
    }

    private func cancelHold() {
        holdTimer?.invalidate()
        holdTimer = nil

        let currentProgress = progress
        if currentProgress > 0 {
            let unwindDuration = Double(currentProgress) * 0.5 + 0.15
            withAnimation(.easeOut(duration: unwindDuration)) {
                progress = 0
            }
            HapticManager.shared.lightTap()
        }

        resetState()
    }

    private func resetState() {
        isHolding = false
        holdStartDate = nil
        startLocation = nil
        didComplete = false
    }
}

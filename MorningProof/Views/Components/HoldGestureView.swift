import SwiftUI
import UIKit

/// A UIKit-based hold gesture that works properly with ScrollView.
///
/// The key insight is that SwiftUI gestures don't have access to UIKit's gesture recognizer
/// properties like `cancelsTouchesInView` and `allowableMovement` which are essential for
/// proper coordination with scroll views.
///
/// This implementation uses UILongPressGestureRecognizer configured to:
/// 1. Allow touches to pass through to ScrollView (`cancelsTouchesInView = false`)
/// 2. Cancel the hold if user moves too far (`allowableMovement`)
/// 3. Start recognizing quickly but not immediately (small `minimumPressDuration`)
struct HoldGestureView: UIViewRepresentable {
    let isEnabled: Bool
    let holdDuration: TimeInterval
    let onProgressChanged: (CGFloat) -> Void
    let onCompleted: () -> Void
    let onCancelled: () -> Void

    func makeUIView(context: Context) -> HoldGestureUIView {
        let view = HoldGestureUIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = isEnabled
        view.holdDuration = holdDuration
        view.onProgressChanged = onProgressChanged
        view.onCompleted = onCompleted
        view.onCancelled = onCancelled
        return view
    }

    func updateUIView(_ uiView: HoldGestureUIView, context: Context) {
        uiView.isUserInteractionEnabled = isEnabled
        uiView.holdDuration = holdDuration
        uiView.onProgressChanged = onProgressChanged
        uiView.onCompleted = onCompleted
        uiView.onCancelled = onCancelled
    }
}

/// The UIKit view that handles the hold gesture
class HoldGestureUIView: UIView, UIGestureRecognizerDelegate {
    var holdDuration: TimeInterval = 1.0
    var onProgressChanged: ((CGFloat) -> Void)?
    var onCompleted: (() -> Void)?
    var onCancelled: (() -> Void)?

    private var holdTimer: Timer?
    private var holdStartTime: Date?
    private var longPressGesture: UILongPressGestureRecognizer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGesture()
    }

    private func setupGesture() {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))

        // Key settings that make this work with ScrollView:

        // 1. Start recognizing after a tiny delay - this gives ScrollView a chance
        //    to recognize a scroll gesture first
        gesture.minimumPressDuration = 0.15

        // 2. If user moves more than this many points, the gesture fails
        //    This allows scrolling to take over
        gesture.allowableMovement = 10

        // 3. CRITICAL: Don't cancel touches in the view - this allows ScrollView
        //    to receive the touch events simultaneously
        gesture.cancelsTouchesInView = false

        // 4. Don't delay touch delivery to other views
        gesture.delaysTouchesBegan = false
        gesture.delaysTouchesEnded = false

        gesture.delegate = self

        addGestureRecognizer(gesture)
        longPressGesture = gesture
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            startHold()

        case .ended, .cancelled, .failed:
            endHold(completed: false)

        default:
            break
        }
    }

    private func startHold() {
        holdStartTime = Date()

        // Signal start with progress 0, then immediately signal target of 1.0
        // The view receiving this should animate from 0 to 1 smoothly
        onProgressChanged?(0)

        // Small delay to ensure the 0 is set before animating to 1
        DispatchQueue.main.async {
            self.onProgressChanged?(1.0)
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Timer only for haptics and completion detection (not progress updates)
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
            guard let self = self, let startTime = self.holdStartTime else {
                timer.invalidate()
                return
            }

            let elapsed = Date().timeIntervalSince(startTime)

            // Haptic tick every ~0.2s
            if Int(elapsed / 0.2) > Int((elapsed - 0.02) / 0.2) {
                let tickGenerator = UIImpactFeedbackGenerator(style: .light)
                tickGenerator.impactOccurred()
            }

            // Check if hold is complete
            if elapsed >= self.holdDuration {
                timer.invalidate()
                DispatchQueue.main.async {
                    self.endHold(completed: true)
                }
            }
        }
    }

    private func endHold(completed: Bool) {
        holdTimer?.invalidate()
        holdTimer = nil

        if completed {
            onCompleted?()
        } else if holdStartTime != nil {
            // Only call cancelled if we actually started a hold
            onCancelled?()
        }

        holdStartTime = nil
        onProgressChanged?(0)
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                          shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow our gesture to work simultaneously with scroll gestures
        // Both can recognize at the same time - the coordination happens via:
        // 1. allowableMovement - if user moves too much, our gesture fails
        // 2. cancelsTouchesInView = false - touches pass through to scroll
        return true
    }
}

/// View modifier that adds hold-to-complete functionality using UIKit gestures
struct UIKitHoldToCompleteModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var progress: CGFloat
    let holdDuration: TimeInterval
    let onCompleted: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay {
                if isEnabled {
                    HoldGestureView(
                        isEnabled: true,
                        holdDuration: holdDuration,
                        onProgressChanged: { newProgress in
                            if newProgress == 0 {
                                // Reset immediately without animation
                                progress = 0
                            } else {
                                // Animate smoothly to target progress
                                withAnimation(.linear(duration: holdDuration)) {
                                    progress = newProgress
                                }
                            }
                        },
                        onCompleted: {
                            progress = 0
                            onCompleted()
                        },
                        onCancelled: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                progress = 0
                            }
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    )
                }
            }
    }
}

extension View {
    func holdToComplete(
        isEnabled: Bool,
        progress: Binding<CGFloat>,
        holdDuration: TimeInterval = 1.0,
        onCompleted: @escaping () -> Void
    ) -> some View {
        modifier(UIKitHoldToCompleteModifier(
            isEnabled: isEnabled,
            progress: progress,
            holdDuration: holdDuration,
            onCompleted: onCompleted
        ))
    }
}

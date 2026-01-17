import SwiftUI
import UIKit

struct SwipeBackModifier: ViewModifier {
    let onDismiss: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isDragging = false

    private let edgeWidth: CGFloat = 30      // Left edge detection zone
    private let dismissThreshold: CGFloat = 100  // How far to swipe to trigger dismiss

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only respond to swipes starting from left edge
                        if value.startLocation.x < edgeWidth && value.translation.width > 0 {
                            isDragging = true
                            offset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        if isDragging {
                            if offset > dismissThreshold {
                                // Haptic feedback and dismiss
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                onDismiss()
                            }
                            // Animate back
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                offset = 0
                            }
                            isDragging = false
                        }
                    }
            )
    }
}

extension View {
    func swipeBack(onDismiss: @escaping () -> Void) -> some View {
        modifier(SwipeBackModifier(onDismiss: onDismiss))
    }
}

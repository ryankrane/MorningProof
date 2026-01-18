import SwiftUI

/// Represents a quadratic Bezier curve with a start, control, and end point
struct QuadraticBezier {
    let start: CGPoint
    let control: CGPoint
    let end: CGPoint

    /// Calculate position on the curve at parameter t (0...1)
    func point(at t: CGFloat) -> CGPoint {
        let u = 1 - t
        // Quadratic Bezier formula: B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
        let x = u * u * start.x + 2 * u * t * control.x + t * t * end.x
        let y = u * u * start.y + 2 * u * t * control.y + t * t * end.y
        return CGPoint(x: x, y: y)
    }

    /// Calculate the tangent angle at parameter t (for rotation alignment)
    func tangentAngle(at t: CGFloat) -> Double {
        // Derivative of quadratic Bezier: B'(t) = 2(1-t)(P₁-P₀) + 2t(P₂-P₁)
        let u = 1 - t
        let dx = 2 * u * (control.x - start.x) + 2 * t * (end.x - control.x)
        let dy = 2 * u * (control.y - start.y) + 2 * t * (end.y - control.y)
        return atan2(dy, dx) * 180 / .pi
    }

    /// Creates a swooping arc from start to end
    /// - Control point swings OUT horizontally (left or right based on position) then curves UP
    /// - Creates a dramatic, Disney-esque flight path
    /// - The arc scales proportionally to the distance between start and end
    static func swoopingArc(from start: CGPoint, to end: CGPoint, screenWidth: CGFloat) -> QuadraticBezier {
        // Calculate the distance between start and end points
        let dx = end.x - start.x
        let dy = end.y - start.y
        let distance = sqrt(dx * dx + dy * dy)

        // Determine if start is on left or right half of screen
        let screenCenter = screenWidth / 2
        let isLeftSide = start.x < screenCenter

        // Calculate midpoint for vertical position of control
        let midY = (start.y + end.y) / 2

        // Scale the horizontal offset based on distance (creates consistent arc feel)
        // Base offset is proportional to distance, with min/max bounds for visual consistency
        let baseHorizontalRatio: CGFloat = 0.25  // Arc width as fraction of distance
        let minHorizontalOffset: CGFloat = 60
        let maxHorizontalOffset: CGFloat = 150
        let horizontalOffset = min(maxHorizontalOffset, max(minHorizontalOffset, distance * baseHorizontalRatio))

        // Vertical offset scales with distance too (pushes control point down for dramatic arc)
        // Larger distances get more dramatic arcs
        let baseVerticalRatio: CGFloat = 0.15
        let minVerticalOffset: CGFloat = 30
        let maxVerticalOffset: CGFloat = 100
        let verticalOffset = min(maxVerticalOffset, max(minVerticalOffset, distance * baseVerticalRatio))

        let controlX: CGFloat
        if isLeftSide {
            // Start is on left: swing LEFT then curve UP-RIGHT
            controlX = start.x - horizontalOffset
        } else {
            // Start is on right: swing RIGHT then curve UP-LEFT
            controlX = start.x + horizontalOffset
        }

        // Control point is at mid-height, pushed down slightly for dramatic arc
        let controlY = midY + verticalOffset

        return QuadraticBezier(
            start: start,
            control: CGPoint(x: controlX, y: controlY),
            end: end
        )
    }
}

/// View modifier that animates position along a Bezier curve
struct BezierPathModifier: ViewModifier, Animatable {
    var progress: CGFloat
    let bezier: QuadraticBezier
    let rotateAlongPath: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let position = bezier.point(at: progress)
        let angle = rotateAlongPath ? bezier.tangentAngle(at: progress) : 0

        content
            .rotationEffect(.degrees(angle - 90)) // -90 to point flame tip forward
            .position(position)
    }
}

extension View {
    /// Animates this view along a Bezier path
    func animateAlongBezier(_ bezier: QuadraticBezier, progress: CGFloat, rotateAlongPath: Bool = false) -> some View {
        modifier(BezierPathModifier(progress: progress, bezier: bezier, rotateAlongPath: rotateAlongPath))
    }
}

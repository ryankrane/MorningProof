import SwiftUI

struct AnimatedCheckmark: View {
    let isCompleted: Bool
    let size: CGFloat
    let color: Color

    @State private var drawProgress: CGFloat = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    init(isCompleted: Bool, size: CGFloat = 24, color: Color = Color(red: 0.55, green: 0.75, blue: 0.55)) {
        self.isCompleted = isCompleted
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)

            // Checkmark path
            CheckmarkShape()
                .trim(from: 0, to: drawProgress)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.5, height: size * 0.5)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onChange(of: isCompleted) { _, newValue in
            if newValue {
                animateIn()
            } else {
                animateOut()
            }
        }
        .onAppear {
            if isCompleted {
                // If already completed on appear, show without animation
                drawProgress = 1.0
                scale = 1.0
                opacity = 1.0
            }
        }
    }

    private func animateIn() {
        // Reset state
        drawProgress = 0
        scale = 0.5
        opacity = 0

        // Animate appearance
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }

        // Draw checkmark with slight delay
        withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
            drawProgress = 1.0
        }
    }

    private func animateOut() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            opacity = 0
            drawProgress = 0
        }
    }
}

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Draw checkmark
        let startPoint = CGPoint(x: rect.width * 0.15, y: rect.height * 0.5)
        let midPoint = CGPoint(x: rect.width * 0.4, y: rect.height * 0.75)
        let endPoint = CGPoint(x: rect.width * 0.85, y: rect.height * 0.25)

        path.move(to: startPoint)
        path.addLine(to: midPoint)
        path.addLine(to: endPoint)

        return path
    }
}

// Enhanced checkmark with satisfying pop, glow, and burst effects
struct CheckmarkCircle: View {
    let isCompleted: Bool
    let size: CGFloat

    // Animation states
    @State private var ringScale: CGFloat = 1.0
    @State private var fillScale: CGFloat = 0
    @State private var checkScale: CGFloat = 0
    @State private var checkRotation: Double = -45
    @State private var glowScale: CGFloat = 0.8
    @State private var glowOpacity: Double = 0
    @State private var burstScale: CGFloat = 1.0
    @State private var burstOpacity: Double = 0

    private let completedColor = Color(red: 0.55, green: 0.75, blue: 0.55)
    private let incompleteColor = Color(red: 0.8, green: 0.75, blue: 0.7)

    var body: some View {
        ZStack {
            // Layer 1: Glow burst (behind everything)
            Circle()
                .fill(completedColor.opacity(0.6))
                .frame(width: size * 1.8, height: size * 1.8)
                .scaleEffect(glowScale)
                .opacity(glowOpacity)
                .blur(radius: 8)

            // Layer 2: Expanding burst ring
            Circle()
                .stroke(completedColor, lineWidth: 2)
                .frame(width: size, height: size)
                .scaleEffect(burstScale)
                .opacity(burstOpacity)

            // Layer 3: Outer ring with pop effect
            Circle()
                .stroke(isCompleted ? completedColor : incompleteColor, lineWidth: 2)
                .frame(width: size, height: size)
                .scaleEffect(ringScale)

            // Layer 4: Fill circle
            Circle()
                .fill(completedColor)
                .frame(width: size, height: size)
                .scaleEffect(fillScale)

            // Layer 5: Checkmark with rotation
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(checkScale)
                .rotationEffect(.degrees(checkRotation))
        }
        .onChange(of: isCompleted) { _, newValue in
            if newValue {
                animateCompletion()
            } else {
                animateReset()
            }
        }
        .onAppear {
            if isCompleted {
                fillScale = 1.0
                checkScale = 1.0
                checkRotation = 0
            }
        }
    }

    private func animateCompletion() {
        // Phase 1: Ring pop (0-0.15s)
        withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
            ringScale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                ringScale = 1.0
            }
        }

        // Phase 2: Glow burst (0.05-0.25s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.2)) {
                glowScale = 1.5
                glowOpacity = 0.6
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.15)) {
                    glowOpacity = 0
                }
            }
        }

        // Phase 3: Fill wave (0.1-0.35s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                fillScale = 1.0
            }
        }

        // Phase 4: Burst ring expands (0.15-0.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            burstOpacity = 0.8
            withAnimation(.easeOut(duration: 0.25)) {
                burstScale = 2.0
                burstOpacity = 0
            }
        }

        // Phase 5: Checkmark draws and rotates (0.2-0.45s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.55)) {
                checkScale = 1.15
                checkRotation = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                    checkScale = 1.0
                }
            }
        }
    }

    private func animateReset() {
        withAnimation(.easeOut(duration: 0.2)) {
            checkScale = 0
            checkRotation = -45
            fillScale = 0
            ringScale = 1.0
            glowOpacity = 0
            burstScale = 1.0
            burstOpacity = 0
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        AnimatedCheckmark(isCompleted: true, size: 32)
        AnimatedCheckmark(isCompleted: false, size: 32)

        CheckmarkCircle(isCompleted: true, size: 28)
        CheckmarkCircle(isCompleted: false, size: 28)
    }
    .padding()
    .background(Color(red: 0.98, green: 0.96, blue: 0.93))
}

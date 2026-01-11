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
        .onChange(of: isCompleted) { newValue in
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

// Simple checkmark icon with fill animation
struct CheckmarkCircle: View {
    let isCompleted: Bool
    let size: CGFloat

    @State private var fillScale: CGFloat = 0
    @State private var checkScale: CGFloat = 0

    private let completedColor = Color(red: 0.55, green: 0.75, blue: 0.55)
    private let incompleteColor = Color(red: 0.8, green: 0.75, blue: 0.7)

    var body: some View {
        ZStack {
            // Outer ring (always visible when incomplete)
            Circle()
                .stroke(isCompleted ? completedColor : incompleteColor, lineWidth: 2)
                .frame(width: size, height: size)

            // Fill circle (scales in when completed)
            Circle()
                .fill(completedColor)
                .frame(width: size, height: size)
                .scaleEffect(fillScale)

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(.white)
                .scaleEffect(checkScale)
        }
        .onChange(of: isCompleted) { newValue in
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
            }
        }
    }

    private func animateCompletion() {
        // Fill scales in with bounce
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            fillScale = 1.0
        }

        // Checkmark scales in with slight delay
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
            checkScale = 1.0
        }
    }

    private func animateReset() {
        withAnimation(.easeOut(duration: 0.2)) {
            checkScale = 0
            fillScale = 0
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

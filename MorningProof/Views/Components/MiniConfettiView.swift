import SwiftUI

// Shape types for confetti variety
enum ConfettiShapeType: CaseIterable {
    case rectangle
    case circle
    case star
    case diamond
}

struct MiniConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var scale: CGFloat
    var opacity: Double
    var color: Color
    var velocityX: CGFloat
    var velocityY: CGFloat
    var rotationSpeed: Double
    var shapeType: ConfettiShapeType
}

struct MiniConfettiView: View {
    let particleCount: Int
    let colors: [Color]

    @State private var particles: [MiniConfettiParticle] = []
    @State private var isAnimating = false

    // Default colors - celebration palette
    private static let defaultColors: [Color] = [
        Color(red: 0.9, green: 0.6, blue: 0.35),   // Orange
        Color(red: 0.55, green: 0.75, blue: 0.55), // Green
        Color(red: 0.85, green: 0.65, blue: 0.2),  // Gold
        Color(red: 0.7, green: 0.5, blue: 0.4),    // Brown
        Color(red: 0.95, green: 0.8, blue: 0.6)    // Cream
    ]

    init(particleCount: Int = 25, colors: [Color]? = nil) {
        self.particleCount = particleCount
        self.colors = colors ?? Self.defaultColors
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPieceView(shapeType: particle.shapeType, color: particle.color)
                        .frame(width: CGFloat.random(in: 5...12), height: CGFloat.random(in: 5...12))
                        .scaleEffect(particle.scale)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2

        particles = (0..<particleCount).map { _ in
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 100...200) // Increased velocity

            return MiniConfettiParticle(
                x: centerX,
                y: centerY,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.6...1.4),
                opacity: 1.0,
                color: colors.randomElement() ?? .orange,
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed - 60, // Stronger upward bias
                rotationSpeed: Double.random(in: -400...400),
                shapeType: ConfettiShapeType.allCases.randomElement() ?? .rectangle
            )
        }
    }

    private func animateParticles() {
        withAnimation(.easeOut(duration: 1.0)) { // Longer duration
            for i in particles.indices {
                particles[i].x += particles[i].velocityX * 0.9
                particles[i].y += particles[i].velocityY * 0.9 + 50 // Add gravity
                particles[i].rotation += particles[i].rotationSpeed
                particles[i].scale *= 0.4
                particles[i].opacity = 0
            }
        }
    }
}

// Individual confetti piece with shape variety
struct ConfettiPieceView: View {
    let shapeType: ConfettiShapeType
    let color: Color

    var body: some View {
        switch shapeType {
        case .rectangle:
            RoundedRectangle(cornerRadius: 1)
                .fill(color)
        case .circle:
            Circle()
                .fill(color)
        case .star:
            StarShape()
                .fill(color)
        case .diamond:
            DiamondShape()
                .fill(color)
        }
    }
}

// Star shape for confetti
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4
        var path = Path()

        for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
            let r = i % 2 == 0 ? radius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * r,
                y: center.y + CGFloat(sin(angle)) * r
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// Diamond shape for confetti
struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// Legacy support
struct ConfettiPiece: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(color)
    }
}

// Full screen confetti for Perfect Morning celebration
struct FullScreenConfettiView: View {
    @Binding var isShowing: Bool

    @State private var particles: [MiniConfettiParticle] = []

    private let colors: [Color] = [
        Color(red: 0.9, green: 0.6, blue: 0.35),   // Orange
        Color(red: 0.55, green: 0.75, blue: 0.55), // Green
        Color(red: 0.85, green: 0.65, blue: 0.2),  // Gold
        Color(red: 0.7, green: 0.5, blue: 0.4),    // Brown
        Color(red: 0.95, green: 0.8, blue: 0.6),   // Cream
        Color.orange,
        Color.yellow
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPieceView(shapeType: particle.shapeType, color: particle.color)
                        .frame(width: 10, height: 10)
                        .scaleEffect(particle.scale)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<50).map { _ in
            MiniConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.5),
                opacity: 1.0,
                color: colors.randomElement() ?? .orange,
                velocityX: CGFloat.random(in: -50...50),
                velocityY: CGFloat.random(in: 200...400),
                rotationSpeed: Double.random(in: -180...180),
                shapeType: ConfettiShapeType.allCases.randomElement() ?? .rectangle
            )
        }
    }

    private func animateParticles(in size: CGSize) {
        // Animate falling
        withAnimation(.easeIn(duration: 2.0)) {
            for i in particles.indices {
                particles[i].y = size.height + 50
                particles[i].x += particles[i].velocityX
                particles[i].rotation += particles[i].rotationSpeed * 2
            }
        }

        // Fade out and dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                for i in particles.indices {
                    particles[i].opacity = 0
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isShowing = false
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.98, green: 0.96, blue: 0.93)
            .ignoresSafeArea()

        VStack {
            Text("Confetti Test")

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .frame(width: 300, height: 80)

                MiniConfettiView()
            }
            .frame(width: 300, height: 80)
        }
    }
}

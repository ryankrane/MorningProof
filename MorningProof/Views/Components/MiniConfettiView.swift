import SwiftUI

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
}

struct MiniConfettiView: View {
    let particleCount: Int
    let colors: [Color]

    @State private var particles: [MiniConfettiParticle] = []
    @State private var isAnimating = false

    init(particleCount: Int = 15, colors: [Color]? = nil) {
        self.particleCount = particleCount
        self.colors = colors ?? [
            Color(red: 0.9, green: 0.6, blue: 0.35),   // Orange
            Color(red: 0.55, green: 0.75, blue: 0.55), // Green
            Color(red: 0.85, green: 0.65, blue: 0.2),  // Gold
            Color(red: 0.7, green: 0.5, blue: 0.4),    // Brown
            Color(red: 0.95, green: 0.8, blue: 0.6)    // Cream
        ]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(color: particle.color)
                        .frame(width: 8, height: 8)
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
            let speed = CGFloat.random(in: 80...150)

            return MiniConfettiParticle(
                x: centerX,
                y: centerY,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.6...1.2),
                opacity: 1.0,
                color: colors.randomElement() ?? .orange,
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed - 50, // Bias upward
                rotationSpeed: Double.random(in: -360...360)
            )
        }
    }

    private func animateParticles() {
        withAnimation(.easeOut(duration: 0.8)) {
            for i in particles.indices {
                particles[i].x += particles[i].velocityX * 0.8
                particles[i].y += particles[i].velocityY * 0.8 + 40 // Add gravity
                particles[i].rotation += particles[i].rotationSpeed
                particles[i].scale *= 0.5
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiPiece: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(color)
    }
}

// Full screen confetti for Perfect Morning
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
                    ConfettiShape(type: Int.random(in: 0...2))
                        .fill(particle.color)
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
                rotationSpeed: Double.random(in: -180...180)
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

struct ConfettiShape: Shape {
    let type: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch type {
        case 0: // Rectangle
            path.addRect(rect)
        case 1: // Circle
            path.addEllipse(in: rect)
        default: // Triangle
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }

        return path
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

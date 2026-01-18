import SwiftUI

// MARK: - Particle Types

enum GrandFinaleParticleType {
    case goldFoil
    case microSpark
    case atmosphericOrb
}

struct GrandFinaleParticle: Identifiable {
    let id = UUID()
    let type: GrandFinaleParticleType

    // Position
    var x: CGFloat
    var y: CGFloat

    // Velocity
    var velocityX: CGFloat
    var velocityY: CGFloat

    // 3D rotation (for gold foil tumbling)
    var rotationX: Double
    var rotationY: Double
    var rotationZ: Double
    var rotationSpeedX: Double
    var rotationSpeedY: Double
    var rotationSpeedZ: Double

    // Visual properties
    var scale: CGFloat
    var opacity: Double
    var drag: CGFloat  // Air resistance factor (0.92-0.96)

    // Size
    var width: CGFloat
    var height: CGFloat
}

struct GrandFinaleConfettiView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var particles: [GrandFinaleParticle] = []
    @State private var timer: Timer?
    @State private var elapsedTime: Double = 0

    private let duration: Double = 2.5
    private let frameRate: Double = 60.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    particleView(for: particle)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                startPhysicsLoop()
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Particle Views

    @ViewBuilder
    private func particleView(for particle: GrandFinaleParticle) -> some View {
        switch particle.type {
        case .goldFoil:
            goldFoilView(particle: particle)
        case .microSpark:
            microSparkView(particle: particle)
        case .atmosphericOrb:
            atmosphericOrbView(particle: particle)
        }
    }

    private func goldFoilView(particle: GrandFinaleParticle) -> some View {
        let color = colorScheme == .dark
            ? Color(red: 1.0, green: 0.95, blue: 0.85)  // White-hot center
            : Color(red: 1.0, green: 0.84, blue: 0.0)   // Saturated gold

        return RoundedRectangle(cornerRadius: 1)
            .fill(color)
            .frame(width: particle.width, height: particle.height)
            .rotation3DEffect(.degrees(particle.rotationX), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
            .rotation3DEffect(.degrees(particle.rotationY), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .rotation3DEffect(.degrees(particle.rotationZ), axis: (x: 0, y: 0, z: 1), perspective: 0.5)
            .scaleEffect(particle.scale)
            .shadow(
                color: colorScheme == .dark
                    ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6)  // Gold tint glow
                    : Color.black.opacity(0.35),  // Tighter drop shadow for light mode
                radius: colorScheme == .dark ? 8 : 1.5,
                x: 0,
                y: colorScheme == .dark ? 0 : 0.5
            )
            .position(x: particle.x, y: particle.y)
            .opacity(particle.opacity)
    }

    private func microSparkView(particle: GrandFinaleParticle) -> some View {
        let color = colorScheme == .dark
            ? Color.white  // Pure white with glow
            : Color(red: 1.0, green: 0.84, blue: 0.0)  // Gold

        return Circle()
            .fill(color)
            .frame(width: particle.width, height: particle.height)
            .shadow(
                color: colorScheme == .dark
                    ? Color.white.opacity(0.8)
                    : Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5),
                radius: colorScheme == .dark ? 4 : 2
            )
            .position(x: particle.x, y: particle.y)
            .opacity(particle.opacity)
    }

    private func atmosphericOrbView(particle: GrandFinaleParticle) -> some View {
        Circle()
            .fill(Color(red: 0.6, green: 0.4, blue: 0.8).opacity(0.4))  // Semi-transparent purple
            .frame(width: particle.width, height: particle.height)
            .blur(radius: 8)
            .position(x: particle.x, y: particle.y)
            .opacity(particle.opacity)
    }

    // MARK: - Particle Creation (Double-Ring Burst)

    private func createParticles(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2

        var newParticles: [GrandFinaleParticle] = []

        // Inner Ring: ~12 gold foil particles at 350-500 pts/sec (enhanced velocity)
        for _ in 0..<12 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 350...500)
            // Velocity-dependent drag: faster particles get more air resistance
            let baseDrag: CGFloat = 0.94
            let velocityDragFactor = (speed - 350) / 150 * 0.02  // 0-2% extra drag

            newParticles.append(GrandFinaleParticle(
                type: .goldFoil,
                x: centerX,
                y: centerY,
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed - 140,  // Enhanced upward bias
                rotationX: Double.random(in: 0...360),
                rotationY: Double.random(in: 0...360),
                rotationZ: Double.random(in: 0...360),
                rotationSpeedX: Double.random(in: -800...800),
                rotationSpeedY: Double.random(in: -800...800),
                rotationSpeedZ: Double.random(in: -500...500),
                scale: CGFloat.random(in: 0.8...1.2),
                opacity: 1.0,
                drag: baseDrag - velocityDragFactor,
                width: 14,
                height: 6
            ))
        }

        // Outer Ring: ~13 gold foil particles at 550-800 pts/sec (enhanced velocity)
        for _ in 0..<13 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 550...800)
            // Velocity-dependent drag: faster particles get more air resistance
            let baseDrag: CGFloat = 0.92
            let velocityDragFactor = (speed - 550) / 250 * 0.03  // 0-3% extra drag

            newParticles.append(GrandFinaleParticle(
                type: .goldFoil,
                x: centerX,
                y: centerY,
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed - 180,  // Stronger upward bias
                rotationX: Double.random(in: 0...360),
                rotationY: Double.random(in: 0...360),
                rotationZ: Double.random(in: 0...360),
                rotationSpeedX: Double.random(in: -1000...1000),
                rotationSpeedY: Double.random(in: -1000...1000),
                rotationSpeedZ: Double.random(in: -600...600),
                scale: CGFloat.random(in: 0.9...1.3),
                opacity: 1.0,
                drag: baseDrag - velocityDragFactor,
                width: 14,
                height: 6
            ))
        }

        // Micro-Sparks: ~40 particles at 800-1100 pts/sec (enhanced velocity)
        for _ in 0..<40 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 800...1100)
            // Velocity-dependent drag for micro-sparks
            let baseDrag: CGFloat = 0.90
            let velocityDragFactor = (speed - 800) / 300 * 0.03

            newParticles.append(GrandFinaleParticle(
                type: .microSpark,
                x: centerX,
                y: centerY,
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed - 120,  // Enhanced upward bias
                rotationX: 0,
                rotationY: 0,
                rotationZ: 0,
                rotationSpeedX: 0,
                rotationSpeedY: 0,
                rotationSpeedZ: 0,
                scale: 1.0,
                opacity: 1.0,
                drag: baseDrag - velocityDragFactor,
                width: 3,
                height: 3
            ))
        }

        // Atmospheric Orbs: ~15 particles, slower movement
        for _ in 0..<15 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 80...160)

            newParticles.append(GrandFinaleParticle(
                type: .atmosphericOrb,
                x: centerX,
                y: centerY,
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed - 40,
                rotationX: 0,
                rotationY: 0,
                rotationZ: 0,
                rotationSpeedX: 0,
                rotationSpeedY: 0,
                rotationSpeedZ: 0,
                scale: CGFloat.random(in: 0.8...1.2),
                opacity: 0.8,
                drag: CGFloat.random(in: 0.96...0.98),  // Less drag for floatiness
                width: 20,
                height: 20
            ))
        }

        particles = newParticles
    }

    // MARK: - Physics Loop

    private func startPhysicsLoop() {
        elapsedTime = 0
        let deltaTime = 1.0 / frameRate

        timer = Timer.scheduledTimer(withTimeInterval: deltaTime, repeats: true) { _ in
            updatePhysics(deltaTime: deltaTime)
        }
    }

    private func updatePhysics(deltaTime: Double) {
        elapsedTime += deltaTime

        // Stop after duration
        if elapsedTime >= duration {
            timer?.invalidate()
            timer = nil
            return
        }

        let dt = CGFloat(deltaTime)
        // Gravity kicks in earlier (0.15s) for more dramatic drift after initial explosion
        let gravityEnabled = elapsedTime > 0.15
        let gravityStrength: CGFloat = 100  // Slightly stronger gravity for dramatic arc

        for i in particles.indices {
            // Apply air resistance
            particles[i].velocityX *= particles[i].drag
            particles[i].velocityY *= particles[i].drag

            // Apply gentle gravity drift after 0.3s
            if gravityEnabled {
                particles[i].velocityY += gravityStrength * dt
            }

            // Update position
            particles[i].x += particles[i].velocityX * dt
            particles[i].y += particles[i].velocityY * dt

            // Update 3D rotation (for gold foil tumbling)
            if particles[i].type == .goldFoil {
                particles[i].rotationX += particles[i].rotationSpeedX * deltaTime
                particles[i].rotationY += particles[i].rotationSpeedY * deltaTime
                particles[i].rotationZ += particles[i].rotationSpeedZ * deltaTime

                // Slow down rotation over time
                particles[i].rotationSpeedX *= 0.995
                particles[i].rotationSpeedY *= 0.995
                particles[i].rotationSpeedZ *= 0.995
            }

            // Fade out based on particle type and elapsed time
            let fadeProgress = elapsedTime / duration
            switch particles[i].type {
            case .microSpark:
                // Micro-sparks fade quickly (fully gone by 40% of duration)
                let sparkFade = min(1.0, elapsedTime / (duration * 0.4))
                particles[i].opacity = max(0, 1.0 - sparkFade)
            case .goldFoil:
                // Gold foil fades gradually (starts at 50%, gone by 100%)
                if fadeProgress > 0.5 {
                    let foilFade = (fadeProgress - 0.5) / 0.5
                    particles[i].opacity = max(0, 1.0 - foilFade)
                }
            case .atmosphericOrb:
                // Orbs fade slowly (starts at 60%, gone by 100%)
                if fadeProgress > 0.6 {
                    let orbFade = (fadeProgress - 0.6) / 0.4
                    particles[i].opacity = max(0, 0.8 - orbFade * 0.8)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        GrandFinaleConfettiView()
    }
}

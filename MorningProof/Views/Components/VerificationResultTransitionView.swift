import SwiftUI

/// Dramatic transition view that shows between scanning completion and result display
/// For approval: particle explosion, unlock animation, success haptics
/// For denial: red laser freeze, glitch effect, "security breach" feel
struct VerificationResultTransitionView: View {
    let image: UIImage
    let isApproved: Bool
    let accentColor: Color
    let onComplete: () -> Void

    @State private var laserPosition: CGFloat = 0.5
    @State private var laserColor: Color = .purple
    @State private var showGlitch: Bool = false
    @State private var glitchOffset: CGFloat = 0
    @State private var rgbShift: CGFloat = 0
    @State private var showParticles: Bool = false
    @State private var showUnlock: Bool = false
    @State private var unlockScale: CGFloat = 0.5
    @State private var unlockOpacity: Double = 0
    @State private var bracketColor: Color = .purple
    @State private var imageOpacity: Double = 1.0
    @State private var statusText: String = "Analyzing..."
    @State private var statusColor: Color = .white

    private let imageCornerRadius: CGFloat = MPRadius.xl

    var body: some View {
        ZStack {
            // Background
            MPColors.background
                .ignoresSafeArea()

            VStack(spacing: MPSpacing.xl) {
                Spacer()

                // Image with effects
                ZStack {
                    // Glitch layers (for denial)
                    if showGlitch {
                        glitchLayers
                    }

                    // Main image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 450)
                        .cornerRadius(imageCornerRadius)
                        .opacity(showGlitch ? 0.8 : imageOpacity)
                        .offset(x: showGlitch ? glitchOffset : 0)

                    // Scanning overlay
                    GeometryReader { geometry in
                        ZStack {
                            // Corner brackets
                            cornerBrackets(in: geometry.size)

                            // Frozen laser line
                            frozenLaserLine(in: geometry.size)

                            // Particles (for approval)
                            if showParticles {
                                ApprovalParticlesView(accentColor: accentColor)
                            }

                            // Unlock icon (for approval)
                            if showUnlock {
                                unlockIcon
                                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            }
                        }
                    }
                    .frame(maxHeight: 450)
                    .aspectRatio(image.size, contentMode: .fit)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, MPSpacing.lg)

                // Status text
                Text(statusText)
                    .font(MPFont.headingSmall())
                    .foregroundColor(statusColor)
                    .multilineTextAlignment(.center)

                Spacer()
            }
        }
        .onAppear {
            laserColor = accentColor
            bracketColor = accentColor
            startTransition()
        }
    }

    // MARK: - Glitch Effect Layers

    @ViewBuilder
    private var glitchLayers: some View {
        // Red channel offset
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 450)
            .cornerRadius(imageCornerRadius)
            .colorMultiply(.red)
            .opacity(0.5)
            .offset(x: rgbShift, y: -rgbShift / 2)
            .blendMode(.screen)

        // Cyan channel offset
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 450)
            .cornerRadius(imageCornerRadius)
            .colorMultiply(Color(red: 0, green: 1, blue: 1))
            .opacity(0.5)
            .offset(x: -rgbShift, y: rgbShift / 2)
            .blendMode(.screen)
    }

    // MARK: - Frozen Laser Line

    @ViewBuilder
    private func frozenLaserLine(in size: CGSize) -> some View {
        let lineY = size.height * laserPosition

        ZStack {
            // Main laser line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            laserColor.opacity(0),
                            laserColor,
                            laserColor,
                            laserColor.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width, height: isApproved ? 3 : 4)

            // Intense glow for denial
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            laserColor.opacity(0),
                            laserColor.opacity(isApproved ? 0.6 : 0.9),
                            laserColor.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width, height: isApproved ? 30 : 50)
                .blur(radius: isApproved ? 10 : 15)
        }
        .position(x: size.width / 2, y: lineY)
    }

    // MARK: - Corner Brackets

    @ViewBuilder
    private func cornerBrackets(in size: CGSize) -> some View {
        let bracketLength: CGFloat = 35
        let bracketWidth: CGFloat = 4
        let padding: CGFloat = 4

        Group {
            bracketShape(length: bracketLength, width: bracketWidth)
                .position(x: padding + bracketLength / 2, y: padding + bracketLength / 2)

            bracketShape(length: bracketLength, width: bracketWidth)
                .rotationEffect(.degrees(90))
                .position(x: size.width - padding - bracketLength / 2, y: padding + bracketLength / 2)

            bracketShape(length: bracketLength, width: bracketWidth)
                .rotationEffect(.degrees(-90))
                .position(x: padding + bracketLength / 2, y: size.height - padding - bracketLength / 2)

            bracketShape(length: bracketLength, width: bracketWidth)
                .rotationEffect(.degrees(180))
                .position(x: size.width - padding - bracketLength / 2, y: size.height - padding - bracketLength / 2)
        }
    }

    @ViewBuilder
    private func bracketShape(length: CGFloat, width: CGFloat) -> some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: length, y: 0))
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: length))
            }
            .stroke(bracketColor, style: StrokeStyle(lineWidth: width, lineCap: .round))

            // Glow
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: length, y: 0))
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: length))
            }
            .stroke(bracketColor.opacity(0.5), style: StrokeStyle(lineWidth: width + 4, lineCap: .round))
            .blur(radius: 4)
        }
        .frame(width: length, height: length)
    }

    // MARK: - Unlock Icon

    @ViewBuilder
    private var unlockIcon: some View {
        ZStack {
            // Glow background
            Circle()
                .fill(accentColor.opacity(0.3))
                .frame(width: 120, height: 120)
                .blur(radius: 20)

            // Icon background
            Circle()
                .fill(MPColors.surface)
                .frame(width: 80, height: 80)

            // Unlock icon
            Image(systemName: "lock.open.fill")
                .font(.system(size: 35, weight: .semibold))
                .foregroundColor(accentColor)
        }
        .scaleEffect(unlockScale)
        .opacity(unlockOpacity)
    }

    // MARK: - Transition Logic

    private func startTransition() {
        if isApproved {
            runApprovalTransition()
        } else {
            runDenialTransition()
        }
    }

    private func runApprovalTransition() {
        // Initial state
        statusText = "Complete"
        statusColor = accentColor

        // Quick laser sweep to center
        withAnimation(.easeOut(duration: 0.3)) {
            laserPosition = 0.5
        }

        // Change to success color
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.2)) {
                laserColor = MPColors.success
                bracketColor = MPColors.success
            }
            statusText = "Verified!"
            statusColor = MPColors.success
        }

        // Show particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showParticles = true
            HapticManager.shared.habitBurst()
        }

        // Show unlock icon
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showUnlock = true
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                unlockScale = 1.0
                unlockOpacity = 1.0
            }
        }

        // Double-tap success haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            HapticManager.shared.success()
        }

        // Complete transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onComplete()
        }
    }

    private func runDenialTransition() {
        // Laser moves to a "problem area" (random spot in middle)
        let freezePosition = CGFloat.random(in: 0.35...0.65)

        // Move laser to freeze point
        withAnimation(.easeOut(duration: 0.3)) {
            laserPosition = freezePosition
        }

        // Turn red and trigger glitch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.15)) {
                laserColor = MPColors.error
                bracketColor = MPColors.error
            }

            // Trigger glitch effect
            showGlitch = true
            HapticManager.shared.error()

            // Animate glitch
            animateGlitch()

            statusText = "Verification Failed"
            statusColor = MPColors.error
        }

        // Complete transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onComplete()
        }
    }

    private func animateGlitch() {
        // Rapid shake and RGB shift
        let iterations = 6
        let duration = 0.08

        for i in 0..<iterations {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * duration) {
                withAnimation(.linear(duration: duration / 2)) {
                    glitchOffset = CGFloat.random(in: -8...8)
                    rgbShift = CGFloat.random(in: 3...8)
                }
            }
        }

        // Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(iterations) * duration) {
            withAnimation(.easeOut(duration: 0.1)) {
                glitchOffset = 0
                rgbShift = 2
            }
        }
    }
}

// MARK: - Approval Particles View

struct ApprovalParticlesView: View {
    let accentColor: Color

    @State private var particles: [ApprovalParticle] = []

    private let particleColors: [Color] = [
        Color(red: 0.6, green: 0.4, blue: 0.8),   // Purple
        Color(red: 0.85, green: 0.65, blue: 0.2), // Gold
        Color(red: 0.4, green: 0.7, blue: 0.9),   // Cyan
        Color.white,
        Color(red: 0.9, green: 0.5, blue: 0.6)    // Pink
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    sparkParticle(particle)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func sparkParticle(_ particle: ApprovalParticle) -> some View {
        Group {
            if particle.isStar {
                // Star/spark shape
                Image(systemName: "sparkle")
                    .font(.system(size: particle.size))
                    .foregroundColor(particle.color)
            } else {
                // Circle
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            }
        }
        .position(x: particle.x, y: particle.y)
        .opacity(particle.opacity)
        .scaleEffect(particle.scale)
        .blur(radius: particle.blur)
    }

    private func createParticles(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2

        particles = (0..<40).map { _ in
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 80...200)
            let isStar = Bool.random()

            return ApprovalParticle(
                x: centerX,
                y: centerY,
                velocityX: cos(angle) * speed,
                velocityY: sin(angle) * speed - 50,
                size: CGFloat.random(in: isStar ? 10...20 : 4...10),
                color: particleColors.randomElement() ?? accentColor,
                opacity: 1.0,
                scale: 1.0,
                blur: 0,
                isStar: isStar
            )
        }
    }

    private func animateParticles() {
        withAnimation(.easeOut(duration: 1.0)) {
            for i in particles.indices {
                particles[i].x += particles[i].velocityX
                particles[i].y += particles[i].velocityY + 30
                particles[i].opacity = 0
                particles[i].scale = 0.3
                particles[i].blur = 2
            }
        }
    }
}

struct ApprovalParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var velocityX: CGFloat
    var velocityY: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
    var scale: CGFloat
    var blur: CGFloat
    var isStar: Bool
}

#Preview("Approval") {
    VerificationResultTransitionView(
        image: UIImage(systemName: "photo.fill")!,
        isApproved: true,
        accentColor: MPColors.accent,
        onComplete: {}
    )
}

#Preview("Denial") {
    VerificationResultTransitionView(
        image: UIImage(systemName: "photo.fill")!,
        isApproved: false,
        accentColor: MPColors.accent,
        onComplete: {}
    )
}

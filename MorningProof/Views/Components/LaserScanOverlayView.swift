import SwiftUI

/// A premium "Cyber-Audit" scanning animation overlay
/// Features: laser line, pulsing brackets, scanning callouts, circular progress, haptic feedback
struct LaserScanOverlayView: View {
    let image: UIImage
    let accentColor: Color
    let statusText: String

    @State private var scanProgress: CGFloat = 0
    @State private var scanPhase: Int = 1
    @State private var bracketOpacity: Double = 0.6
    @State private var bracketScale: CGFloat = 1.05
    @State private var dotCount: Int = 0
    @State private var progressValue: CGFloat = 0
    @State private var isLockingOn: Bool = false

    // Scanning callouts
    @State private var activeCallout: ScanCallout?
    @State private var calloutOpacity: Double = 0

    // Timer references
    @State private var dotTimer: Timer?
    @State private var progressTimer: Timer?
    @State private var hapticTimer: Timer?
    @State private var calloutTimer: Timer?
    @State private var progressStartTime: Date?

    private let scanDuration: Double = 2.5
    private let imageCornerRadius: CGFloat = MPRadius.xl

    // Scanning callout messages
    private let calloutMessages = [
        "Scanning textures...",
        "Detecting fabric folds...",
        "Checking pillow alignment...",
        "Analyzing sheet tightness...",
        "Evaluating overall tidiness...",
        "Processing corners...",
        "Measuring symmetry..."
    ]

    var body: some View {
        VStack(spacing: MPSpacing.xl) {
            Spacer()

            // Photo with scanning overlay
            ZStack {
                // The captured photo
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 450)
                    .cornerRadius(imageCornerRadius)
                    .mpShadow(.large)

                // Scanning overlay
                GeometryReader { geometry in
                    ZStack {
                        // Corner brackets with lock-on effect
                        cornerBrackets(in: geometry.size)

                        // Laser scan line
                        laserLine(in: geometry.size)

                        // Scan region highlight
                        scanHighlight(in: geometry.size)

                        // Scanning callout
                        if let callout = activeCallout {
                            scanningCallout(callout, in: geometry.size)
                        }
                    }
                }
                .frame(maxHeight: 450)
                .aspectRatio(image.size, contentMode: .fit)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, MPSpacing.lg)

            // Status section with circular progress
            VStack(spacing: MPSpacing.md) {
                // Circular progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(MPColors.progressBg, lineWidth: 6)
                        .frame(width: 70, height: 70)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(
                            AngularGradient(
                                colors: [accentColor.opacity(0.5), accentColor, accentColor],
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    // Glow effect on progress end
                    Circle()
                        .trim(from: max(0, progressValue - 0.02), to: progressValue)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 4)
                        .opacity(0.8)

                    // Percentage text
                    Text("\(Int(progressValue * 100))%")
                        .font(MPFont.labelMedium())
                        .foregroundColor(MPColors.textPrimary)
                }

                // Phase indicators
                HStack(spacing: MPSpacing.sm) {
                    ForEach(1...3, id: \.self) { phase in
                        Circle()
                            .fill(phase <= scanPhase ? accentColor : MPColors.progressBg)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: scanPhase)
                    }
                }

                Text("Scanning\(String(repeating: ".", count: dotCount))")
                    .font(MPFont.headingSmall())
                    .foregroundColor(MPColors.textPrimary)
                    .frame(width: 130, alignment: .center)

                Text(statusText)
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
    }

    // MARK: - Laser Line

    @ViewBuilder
    private func laserLine(in size: CGSize) -> some View {
        let lineY = size.height * scanProgress

        ZStack {
            // Main laser line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0),
                            accentColor,
                            accentColor,
                            accentColor.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width, height: 2)

            // Glow effect
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0),
                            accentColor.opacity(0.6),
                            accentColor.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size.width, height: 30)
                .blur(radius: 10)
        }
        .position(x: size.width / 2, y: lineY)
    }

    // MARK: - Corner Brackets

    @ViewBuilder
    private func cornerBrackets(in size: CGSize) -> some View {
        let bracketLength: CGFloat = isLockingOn ? 35 : 30
        let bracketWidth: CGFloat = isLockingOn ? 4 : 3
        let padding: CGFloat = isLockingOn ? 4 : 8

        Group {
            // Top-left
            bracketShape(length: bracketLength, width: bracketWidth)
                .position(x: padding + bracketLength / 2, y: padding + bracketLength / 2)

            // Top-right
            bracketShape(length: bracketLength, width: bracketWidth)
                .rotationEffect(.degrees(90))
                .position(x: size.width - padding - bracketLength / 2, y: padding + bracketLength / 2)

            // Bottom-left
            bracketShape(length: bracketLength, width: bracketWidth)
                .rotationEffect(.degrees(-90))
                .position(x: padding + bracketLength / 2, y: size.height - padding - bracketLength / 2)

            // Bottom-right
            bracketShape(length: bracketLength, width: bracketWidth)
                .rotationEffect(.degrees(180))
                .position(x: size.width - padding - bracketLength / 2, y: size.height - padding - bracketLength / 2)
        }
        .opacity(bracketOpacity)
        .scaleEffect(bracketScale)
    }

    @ViewBuilder
    private func bracketShape(length: CGFloat, width: CGFloat) -> some View {
        ZStack {
            // Main bracket
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: length, y: 0))
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: length))
            }
            .stroke(accentColor, style: StrokeStyle(lineWidth: width, lineCap: .round))

            // Glow when locking on
            if isLockingOn {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: length, y: 0))
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: length))
                }
                .stroke(accentColor.opacity(0.5), style: StrokeStyle(lineWidth: width + 4, lineCap: .round))
                .blur(radius: 4)
            }
        }
        .frame(width: length, height: length)
    }

    // MARK: - Scan Highlight

    @ViewBuilder
    private func scanHighlight(in size: CGSize) -> some View {
        let highlightHeight: CGFloat = 60
        let lineY = size.height * scanProgress

        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        accentColor.opacity(0),
                        accentColor.opacity(0.15),
                        accentColor.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size.width, height: highlightHeight)
            .position(x: size.width / 2, y: lineY)
    }

    // MARK: - Scanning Callout

    @ViewBuilder
    private func scanningCallout(_ callout: ScanCallout, in size: CGSize) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(accentColor)
                .frame(width: 6, height: 6)

            Text(callout.message)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(accentColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(accentColor.opacity(0.5), lineWidth: 1)
                )
        )
        .position(x: callout.x * size.width, y: callout.y * size.height)
        .opacity(calloutOpacity)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Scan animation
        animateScan()

        // Bracket pulse with lock-on effect
        animateBrackets()

        // Dot animation
        dotTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            dotCount = (dotCount + 1) % 4
        }

        // Haptic feedback loop - rhythmic thumping
        startHapticLoop()

        // Scanning callouts
        startCalloutAnimation()

        // Progress animation
        progressStartTime = Date()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let startTime = progressStartTime else { return }

            let elapsed = Date().timeIntervalSince(startTime)

            let newProgress: CGFloat
            if elapsed < 2 {
                newProgress = CGFloat(elapsed / 2) * 0.40
            } else if elapsed < 5 {
                newProgress = 0.40 + CGFloat((elapsed - 2) / 3) * 0.25
            } else if elapsed < 15 {
                newProgress = 0.65 + CGFloat((elapsed - 5) / 10) * 0.20
            } else {
                let extraTime = elapsed - 15
                newProgress = 0.85 + CGFloat(min(extraTime / 30, 1.0)) * 0.07
            }

            withAnimation(.linear(duration: 0.1)) {
                progressValue = min(newProgress, 0.92)
            }
        }
    }

    private func animateScan() {
        scanProgress = 0
        scanPhase = 1

        withAnimation(.easeInOut(duration: 1.5)) {
            scanProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            scanPhase = 2
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            scanPhase = 3
            withAnimation(.easeInOut(duration: 1.0)) {
                scanProgress = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + scanDuration) {
            animateScan()
        }
    }

    private func animateBrackets() {
        // Pulse opacity
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            bracketOpacity = 1.0
        }

        // Lock-on effect every few seconds
        triggerLockOn()
    }

    private func triggerLockOn() {
        // Lock on
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isLockingOn = true
                bracketScale = 0.98
            }

            // Play lock-on haptic
            HapticManager.shared.rigid()

            // Release lock
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isLockingOn = false
                    bracketScale = 1.05
                }
            }
        }

        // Repeat
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            triggerLockOn()
        }
    }

    private func startHapticLoop() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()

        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
            generator.impactOccurred(intensity: 0.4)
            generator.prepare()
        }
    }

    private func startCalloutAnimation() {
        var usedIndices: Set<Int> = []

        func showNextCallout() {
            // Pick a random unused message
            var availableIndices = Set(0..<calloutMessages.count).subtracting(usedIndices)
            if availableIndices.isEmpty {
                usedIndices.removeAll()
                availableIndices = Set(0..<calloutMessages.count)
            }

            guard let index = availableIndices.randomElement() else { return }
            usedIndices.insert(index)

            let message = calloutMessages[index]

            // Random position (avoid edges)
            let x = CGFloat.random(in: 0.2...0.8)
            let y = CGFloat.random(in: 0.2...0.8)

            activeCallout = ScanCallout(message: message, x: x, y: y)

            // Fade in
            withAnimation(.easeOut(duration: 0.2)) {
                calloutOpacity = 1.0
            }

            // Fade out after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeIn(duration: 0.2)) {
                    calloutOpacity = 0
                }
            }

            // Clear and schedule next
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                activeCallout = nil
            }
        }

        // Show first callout after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showNextCallout()
        }

        // Schedule recurring callouts
        calloutTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            showNextCallout()
        }
    }

    private func stopAnimations() {
        dotTimer?.invalidate()
        dotTimer = nil
        progressTimer?.invalidate()
        progressTimer = nil
        hapticTimer?.invalidate()
        hapticTimer = nil
        calloutTimer?.invalidate()
        calloutTimer = nil
        progressStartTime = nil
    }
}

// MARK: - Supporting Types

struct ScanCallout {
    let message: String
    let x: CGFloat
    let y: CGFloat
}

#Preview {
    ZStack {
        MPColors.background
            .ignoresSafeArea()

        LaserScanOverlayView(
            image: UIImage(systemName: "bed.double.fill")!,
            accentColor: MPColors.accent,
            statusText: "AI is checking if it's made"
        )
    }
}

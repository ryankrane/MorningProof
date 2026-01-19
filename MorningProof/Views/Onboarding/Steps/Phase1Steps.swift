import SwiftUI
import AuthenticationServices

// MARK: - Phase 1: Hook & Identity (Steps 0-3)

// MARK: - Step 0: Welcome Hero

struct WelcomeHeroStep: View {
    let onContinue: () -> Void
    private var authManager: AuthenticationManager { AuthenticationManager.shared }
    @State private var animateContent = false
    @State private var animateOrb = false
    @State private var pulseOrb = false
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        VStack(spacing: 0) {
            // Top half - branding content, vertically centered in its space
            VStack(spacing: 0) {
                Spacer()

                // App branding - centered
                VStack(spacing: MPSpacing.xl) {
                    // Animated orb with sunrise - gentle 5% pulse
                    ZStack {
                        // Outer glow - subtle pulse
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        MPColors.primary.opacity(pulseOrb ? 0.55 : 0.45),
                                        MPColors.primary.opacity(pulseOrb ? 0.25 : 0.18),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 90
                                )
                            )
                            .frame(width: 180, height: 180)
                            .scaleEffect(pulseOrb ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulseOrb)

                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 52))
                            .foregroundColor(MPColors.primary)
                            .offset(y: animateOrb ? -5 : 5)
                            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateOrb)
                    }

                    // Headlines - centered, same font size
                    VStack(spacing: MPSpacing.sm) {
                        // Primary headline with shimmer
                        Text("Lock Your Distractions")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(MPColors.textPrimary)
                            .fixedSize(horizontal: true, vertical: false)
                            .overlay(
                                // Subtle shimmer highlight
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .white.opacity(0.4), location: 0.45),
                                        .init(color: .white.opacity(0.6), location: 0.5),
                                        .init(color: .white.opacity(0.4), location: 0.55),
                                        .init(color: .clear, location: 1)
                                    ],
                                    startPoint: UnitPoint(x: shimmerPhase, y: 0.5),
                                    endPoint: UnitPoint(x: shimmerPhase + 0.3, y: 0.5)
                                )
                                .mask(
                                    Text("Lock Your Distractions")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .fixedSize(horizontal: true, vertical: false)
                                )
                            )
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 12)

                        // Secondary tagline - vibrant gradient with glow
                        ZStack {
                            // Glow layer
                            Text("Take Back Your Morning")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.75, green: 0.55, blue: 1.0),
                                            MPColors.primary
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .blur(radius: 12)
                                .opacity(0.6)

                            // Main text
                            Text("Take Back Your Morning")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.8, green: 0.6, blue: 1.0),
                                            MPColors.primary,
                                            Color(red: 0.6, green: 0.4, blue: 0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 10)
                        .animation(.easeOut(duration: 0.8).delay(0.15), value: animateContent)
                    }
                }
                .padding(.horizontal, MPSpacing.xl)

                Spacer()
            }

            // Sign-in options
            VStack(spacing: MPSpacing.md) {
                SignInWithAppleButton(.signIn) { request in
                    authManager.handleAppleSignInRequest(request)
                } onCompletion: { result in
                    authManager.handleAppleSignInCompletion(result) { success in
                        if success { onContinue() }
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .cornerRadius(MPRadius.lg)

                Button {
                    authManager.signInWithGoogle { success in
                        if success { onContinue() }
                    }
                } label: {
                    HStack(spacing: MPSpacing.md) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))
                        Text("Sign in with Google")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(MPColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: MPRadius.lg)
                            .stroke(MPColors.border, lineWidth: 1)
                    )
                }

                HStack {
                    Rectangle().fill(MPColors.divider).frame(height: 1)
                    Text("or")
                        .font(.system(size: 13))
                        .foregroundColor(MPColors.textTertiary)
                        .padding(.horizontal, MPSpacing.md)
                    Rectangle().fill(MPColors.divider).frame(height: 1)
                }
                .padding(.vertical, MPSpacing.xs)

                Button {
                    authManager.continueAnonymously()
                    onContinue()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MPColors.primary)
                }
            }
            .padding(.horizontal, MPSpacing.xl)
            .padding(.bottom, 50)
            .opacity(animateContent ? 1 : 0)

            if let error = authManager.errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MPSpacing.xl)
                    .padding(.bottom, MPSpacing.md)
            }
        }
        .onAppear {
            animateOrb = true
            pulseOrb = true
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
            // Start shimmer after content fades in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 1.5)) {
                    shimmerPhase = 1.5
                }
            }
        }
    }
}

// MARK: - Step 1: Name

struct NameStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void
    @FocusState private var isNameFocused: Bool
    @State private var hasConfirmedName = false
    @State private var showGreeting = false
    @State private var iconDeparting = false
    @State private var sparkles: [SparkleParticle] = []
    @State private var fadeOut = false
    @State private var previousNameLength = 0

    struct SparkleParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var rotation: Double
    }

    var body: some View {
        ZStack {
            // Sparkle particles layer
            ForEach(sparkles) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: 12))
                    .foregroundColor(MPColors.primary)
                    .scaleEffect(sparkle.scale)
                    .opacity(sparkle.opacity)
                    .rotationEffect(.degrees(sparkle.rotation))
                    .position(x: sparkle.x, y: sparkle.y)
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: MPSpacing.lg) {
                    // Animated icon that floats away
                    GeometryReader { geo in
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(MPColors.primary)
                            .frame(maxWidth: .infinity)
                            .scaleEffect(iconDeparting ? 0.3 : 1.0)
                            .opacity(iconDeparting ? 0 : 1)
                            .offset(y: iconDeparting ? -150 : 0)
                            .blur(radius: iconDeparting ? 2 : 0)
                            .onChange(of: iconDeparting) { _, departing in
                                if departing {
                                    // Create sparkles at icon position
                                    let centerX = geo.frame(in: .global).midX
                                    let centerY = geo.frame(in: .global).midY
                                    createSparkles(at: centerX, y: centerY)
                                }
                            }
                    }
                    .frame(height: 60)

                    // Morphing text - switches between prompt and greeting
                    ZStack {
                    // Initial prompt
                    VStack(spacing: MPSpacing.sm) {
                        Text("Let's make this personal")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(MPColors.textPrimary)

                        Text("What should we call you?")
                            .font(.system(size: 16))
                            .foregroundColor(MPColors.textSecondary)
                    }
                    .opacity(showGreeting ? 0 : 1)
                    .scaleEffect(showGreeting ? 0.8 : 1)
                    .offset(y: showGreeting ? -20 : 0)

                    // Greeting after name confirmed
                    Text("Great to meet you, \(data.userName)!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)
                        .opacity(showGreeting ? 1 : 0)
                        .scaleEffect(showGreeting ? 1 : 0.8)
                        .offset(y: showGreeting ? 0 : 20)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showGreeting)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            // Input section - fades out when name confirmed
            VStack(spacing: MPSpacing.sm) {
                TextField("", text: $data.userName, prompt: Text("First name").foregroundColor(MPColors.textTertiary))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .textContentType(.givenName)
                    .padding(MPSpacing.xl)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.lg)
                    .mpShadow(.small)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if !data.userName.isEmpty {
                            confirmName()
                        }
                    }
                    .onChange(of: data.userName) { oldValue, newValue in
                        // Detect autofill: name length increases by more than 1 character at once
                        let lengthDifference = newValue.count - previousNameLength
                        if lengthDifference > 1 && !newValue.isEmpty && !hasConfirmedName {
                            // Autofill detected - auto-proceed after a brief delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if !hasConfirmedName {
                                    confirmName()
                                }
                            }
                        }
                        previousNameLength = newValue.count
                    }

                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Stored locally. Never shared.")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(MPColors.textMuted)
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .opacity(hasConfirmedName ? 0 : 1)
            .scaleEffect(hasConfirmedName ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.4), value: hasConfirmedName)

            Spacer()

            // Button section - fades out when name confirmed
            VStack(spacing: MPSpacing.md) {
                MPButton(
                    title: data.userName.isEmpty ? "Skip for now" : "Let's go!",
                    style: .primary
                ) {
                    if data.userName.isEmpty {
                        // Skip without animation
                        isNameFocused = false
                        onContinue()
                    } else {
                        confirmName()
                    }
                }

                if data.userName.isEmpty {
                    Text("You can add your name later")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.textTertiary)
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
            .opacity(hasConfirmedName ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: hasConfirmedName)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
        } // Close VStack
        .opacity(fadeOut ? 0 : 1)
        .scaleEffect(fadeOut ? 0.95 : 1)
        .animation(.easeOut(duration: 0.4), value: fadeOut)
    }

    private func confirmName() {
        isNameFocused = false
        hasConfirmedName = true

        // Start icon departure animation
        withAnimation(.easeOut(duration: 0.6)) {
            iconDeparting = true
        }

        // Show greeting after input fades
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showGreeting = true
        }

        // Fade out before advancing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            fadeOut = true
        }

        // Auto-advance after fade out completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            onContinue()
        }
    }

    private func createSparkles(at x: CGFloat, y: CGFloat) {
        // Create 8 sparkles that burst outward
        for i in 0..<8 {
            let angle = Double(i) * (360.0 / 8.0) * .pi / 180.0
            let distance: CGFloat = CGFloat.random(in: 40...80)
            let targetX = x + cos(angle) * distance
            let targetY = y + sin(angle) * distance

            let sparkle = SparkleParticle(
                x: x,
                y: y,
                scale: 0.5,
                opacity: 1.0,
                rotation: Double.random(in: 0...360)
            )
            sparkles.append(sparkle)
            let index = sparkles.count - 1

            // Animate sparkle outward
            withAnimation(.easeOut(duration: 0.5)) {
                sparkles[index].x = targetX
                sparkles[index].y = targetY
                sparkles[index].scale = CGFloat.random(in: 0.8...1.2)
                sparkles[index].rotation += Double.random(in: 90...180)
            }

            // Fade out sparkle
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                sparkles[index].opacity = 0
            }
        }

        // Clean up sparkles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            sparkles.removeAll()
        }
    }
}

// MARK: - Step 2: Morning Struggle

struct MorningStruggleStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.md) {
                Text("What's your biggest\nmorning struggle?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Select all that apply")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MPSpacing.md) {
                ForEach(OnboardingData.MorningStruggle.allCases, id: \.rawValue) { struggle in
                    OnboardingGridButton(
                        title: struggle.rawValue,
                        icon: struggle.icon,
                        isSelected: data.morningStruggles.contains(struggle)
                    ) {
                        if data.morningStruggles.contains(struggle) {
                            data.morningStruggles.remove(struggle)
                        } else {
                            data.morningStruggles.insert(struggle)
                        }
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(title: "That's me", style: .primary, isDisabled: data.morningStruggles.isEmpty) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.easeOut(duration: 0.4), value: appeared)
        .onAppear {
            appeared = true
        }
    }
}

// MARK: - Step 3: Desired Outcome

struct DesiredOutcomeStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var selectedAnimating: Set<OnboardingData.DesiredOutcome> = []

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.md) {
                TargetWithArrowIcon(size: 60)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.5)

                Text("What would you like\nto accomplish?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Select all that apply")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxl)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MPSpacing.md) {
                ForEach(Array(OnboardingData.DesiredOutcome.allCases.enumerated()), id: \.element.rawValue) { index, outcome in
                    OnboardingGridButtonWithBadge(
                        title: outcome.rawValue,
                        icon: outcome.icon,
                        isSelected: data.desiredOutcomes.contains(outcome),
                        badge: nil
                    ) {
                        // Haptic feedback
                        HapticManager.shared.light()

                        // Toggle selection with bounce animation
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if data.desiredOutcomes.contains(outcome) {
                                data.desiredOutcomes.remove(outcome)
                            } else {
                                data.desiredOutcomes.insert(outcome)
                            }
                            selectedAnimating.insert(outcome)
                        }

                        // Remove from animating set after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedAnimating.remove(outcome)
                        }
                    }
                    .scaleEffect(selectedAnimating.contains(outcome) ? 1.05 : 1.0)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08),
                        value: appeared
                    )
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(title: "That's my goal", style: .primary, isDisabled: data.desiredOutcomes.isEmpty) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}

// MARK: - Target with Arrow Icon

private struct TargetWithArrowIcon: View {
    let size: CGFloat

    private let targetRed = Color(red: 0.85, green: 0.2, blue: 0.2)
    private let arrowColor = Color(white: 0.15)

    var body: some View {
        ZStack {
            // Outer red ring
            Circle()
                .fill(targetRed)
                .frame(width: size, height: size)

            // White ring
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.75, height: size * 0.75)

            // Middle red ring
            Circle()
                .fill(targetRed)
                .frame(width: size * 0.5, height: size * 0.5)

            // Inner white ring
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.28, height: size * 0.28)

            // Center bullseye (red)
            Circle()
                .fill(targetRed)
                .frame(width: size * 0.12, height: size * 0.12)

            // Arrow hitting the bullseye (diagonal from top-right)
            DartArrow(size: size, color: arrowColor)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Dart Arrow Component

private struct DartArrow: View {
    let size: CGFloat
    let color: Color

    var body: some View {
        // Arrow shaft with arrowhead
        Path { path in
            let scale = size / 60.0 // Base scale factor

            // Arrow tip lands at center, shaft extends to upper-right
            let tipX = size * 0.5
            let tipY = size * 0.5
            let endX = size * 0.92
            let endY = size * 0.08

            // Main shaft line
            path.move(to: CGPoint(x: endX, y: endY))
            path.addLine(to: CGPoint(x: tipX + 2 * scale, y: tipY - 2 * scale))
        }
        .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

        // Arrowhead (filled triangle)
        Path { path in
            let scale = size / 60.0
            let tipX = size * 0.5
            let tipY = size * 0.5

            // Triangle pointing toward center
            path.move(to: CGPoint(x: tipX, y: tipY))
            path.addLine(to: CGPoint(x: tipX + 12 * scale, y: tipY - 6 * scale))
            path.addLine(to: CGPoint(x: tipX + 6 * scale, y: tipY - 12 * scale))
            path.closeSubpath()
        }
        .fill(color)

        // Fletching (tail feathers) - two small triangles at back
        Path { path in
            let scale = size / 60.0
            let endX = size * 0.92
            let endY = size * 0.08

            // Upper-left feather
            path.move(to: CGPoint(x: endX - 4 * scale, y: endY + 4 * scale))
            path.addLine(to: CGPoint(x: endX - 12 * scale, y: endY - 2 * scale))
            path.addLine(to: CGPoint(x: endX - 6 * scale, y: endY + 2 * scale))
            path.closeSubpath()

            // Lower-right feather
            path.move(to: CGPoint(x: endX - 4 * scale, y: endY + 4 * scale))
            path.addLine(to: CGPoint(x: endX + 2 * scale, y: endY + 12 * scale))
            path.addLine(to: CGPoint(x: endX - 2 * scale, y: endY + 6 * scale))
            path.closeSubpath()
        }
        .fill(color)
    }
}

import SwiftUI
import AuthenticationServices

// MARK: - Phase 1: Hook & Personalization

// MARK: - Step 1: Welcome Hero

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
                        Text("Lock Your Distractions.")
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
                                    Text("Lock Your Distractions.")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .fixedSize(horizontal: true, vertical: false)
                                )
                            )
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 12)

                        // Secondary tagline - same font size, accented color
                        Text("Take Back Your Morning.")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        MPColors.primary.opacity(0.9),
                                        MPColors.primary.opacity(0.7)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
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
                    Text("Continue without account")
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

// MARK: - Step 2: Name

struct NameStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void
    @FocusState private var isNameFocused: Bool
    @State private var hasConfirmedName = false
    @State private var showGreeting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.lg) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(MPColors.primary)

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
                    title: data.userName.isEmpty ? "Skip" : "Continue",
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
    }

    private func confirmName() {
        isNameFocused = false
        hasConfirmedName = true

        // Show greeting after input fades
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showGreeting = true
        }

        // Auto-advance after greeting is shown (1.7s = 25% faster than 2.25s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            onContinue()
        }
    }
}

// MARK: - Step 3: Gender

struct GenderStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.md) {
                Text("What's your gender?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("This helps us personalize your experience")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            VStack(spacing: MPSpacing.md) {
                ForEach(OnboardingData.Gender.allCases, id: \.rawValue) { gender in
                    OnboardingOptionButton(
                        title: gender.rawValue,
                        icon: gender.icon,
                        isSelected: data.gender == gender
                    ) {
                        data.gender = gender
                    }
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            VStack(spacing: MPSpacing.md) {
                MPButton(title: "Continue", style: .primary, isDisabled: data.gender == nil) {
                    onContinue()
                }

                Button {
                    data.gender = .preferNotToSay
                    onContinue()
                } label: {
                    Text("Skip")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textTertiary)
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 4: Morning Struggle

struct MorningStruggleStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

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

            MPButton(title: "Continue", style: .primary, isDisabled: data.morningStruggles.isEmpty) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
    }
}

import SwiftUI
import AuthenticationServices

// MARK: - Phase 1: Hook & Personalization

// MARK: - Step 1: Welcome Hero

struct WelcomeHeroStep: View {
    let onContinue: () -> Void
    private var authManager: AuthenticationManager { AuthenticationManager.shared }
    @State private var animateContent = false
    @State private var animateOrb = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App branding
            VStack(spacing: MPSpacing.lg) {
                // Animated orb with sunrise
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    MPColors.primary.opacity(0.6),
                                    MPColors.primary.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(animateOrb ? 1.1 : 1.0)

                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 60))
                        .foregroundColor(MPColors.primary)
                        .offset(y: animateOrb ? -4 : 4)
                }
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateOrb)

                VStack(spacing: MPSpacing.sm) {
                    Text("Earn Your Morning")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Build daily habits that stick")
                        .font(.system(size: 17))
                        .foregroundColor(MPColors.textSecondary)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            }

            Spacer().frame(height: MPSpacing.xxxl)

            Spacer()

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
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Step 2: Name

struct NameStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.lg) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(MPColors.primary)

                Text("Let's make this personal")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("What should we call you?")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer().frame(height: MPSpacing.xxxl)

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

                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Stored locally. Never shared.")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(MPColors.textMuted)
            }
            .padding(.horizontal, MPSpacing.xxxl)

            Spacer()

            VStack(spacing: MPSpacing.md) {
                MPButton(
                    title: data.userName.isEmpty ? "Skip" : "Continue",
                    style: .primary
                ) {
                    isNameFocused = false
                    onContinue()
                }

                if data.userName.isEmpty {
                    Text("You can add your name later")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.textTertiary)
                }
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
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

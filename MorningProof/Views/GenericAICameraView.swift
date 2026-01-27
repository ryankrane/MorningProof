import SwiftUI

/// A reusable camera verification view for predefined AI-verified habits
/// Supports: healthyBreakfast, morningJournal, vitamins, skincare, mealPrep
struct GenericAICameraView: View {
    @ObservedObject var manager: MorningProofManager
    let habitType: HabitType
    @Environment(\.dismiss) var dismiss

    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var result: CustomVerificationResult?
    @State private var errorMessage: String?
    @State private var errorIcon: String = "exclamationmark.triangle"

    // Animation states for result view
    @State private var showCheckmark = false
    @State private var showTitle = false
    @State private var showFeedback = false
    @State private var showConfetti = false
    @State private var showButton = false

    // Apps unlocked celebration
    @State private var showAppsUnlockedCelebration = false
    @State private var wasLastHabitToComplete = false

    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    MPColors.background
                        .ignoresSafeArea()

                    if isAnalyzing {
                        analyzingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else if let result = result {
                        resultView(result)
                    } else {
                        captureView
                    }
                }
                .navigationTitle("Verify \(habitType.displayName)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(MPColors.textTertiary)
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }

            // Apps Unlocked celebration (shown after successful verification that completes routine)
            if showAppsUnlockedCelebration {
                AppsUnlockedCelebrationView(isShowing: $showAppsUnlockedCelebration) {
                    // Celebration complete - dismiss the camera view
                    dismiss()
                }
            }
        }
    }

    var captureView: some View {
        VStack(spacing: MPSpacing.xxl) {
            Spacer()

            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 350)
                    .cornerRadius(MPRadius.xl)
                    .mpShadow(.medium)
                    .padding(.horizontal, MPSpacing.xxl)

                HStack(spacing: MPSpacing.md) {
                    MPButton(title: "Retake", style: .secondary) {
                        selectedImage = nil
                    }

                    MPButton(title: "Verify", style: .primary) {
                        Task {
                            await verifyHabit(image: image)
                        }
                    }
                }
                .padding(.horizontal, MPSpacing.xxl)
            } else {
                VStack(spacing: MPSpacing.xl) {
                    VStack(spacing: MPSpacing.xl) {
                        Image(systemName: habitType.icon)
                            .font(.system(size: 80))
                            .foregroundColor(MPColors.textTertiary)

                        Text(capturePrompt)
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textTertiary)

                        Text(captureSubtitle)
                            .font(MPFont.bodySmall())
                            .foregroundColor(MPColors.textTertiary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.xl)
                    .mpShadow(.medium)
                    .padding(.horizontal, MPSpacing.xxl)

                    MPButton(title: "Open Camera", style: .primary, icon: "camera.fill") {
                        showingCamera = true
                    }
                    .padding(.horizontal, MPSpacing.xxl)
                }
            }

            Spacer()
        }
    }

    private var capturePrompt: String {
        switch habitType {
        case .healthyBreakfast: return "Take a photo of your breakfast"
        case .morningJournal: return "Show your journal entry"
        case .vitamins: return "Snap your vitamins"
        case .skincare: return "Show your skincare routine"
        case .mealPrep: return "Take a photo of your prep"
        default: return "Take a photo"
        }
    }

    private var captureSubtitle: String {
        switch habitType {
        case .healthyBreakfast: return "Show us a nutritious meal to start your day!"
        case .morningJournal: return "Open your journal so we can see today's writing."
        case .vitamins: return "Show your supplements or pill organizer."
        case .skincare: return "Let's see those skincare products!"
        case .mealPrep: return "Show your prepared meals or lunch."
        default: return "Take a photo to verify."
        }
    }

    private var successTitle: String {
        switch habitType {
        case .healthyBreakfast: return "Healthy Choice!"
        case .morningJournal: return "Journal Verified!"
        case .vitamins: return "Vitamins Verified!"
        case .skincare: return "Skincare Verified!"
        case .mealPrep: return "Meal Prep Verified!"
        default: return "Verified!"
        }
    }

    private var failureTitle: String {
        switch habitType {
        case .healthyBreakfast: return "Not Quite Healthy..."
        case .morningJournal: return "Can't See Your Writing..."
        case .vitamins: return "No Vitamins Found..."
        case .skincare: return "No Skincare Found..."
        case .mealPrep: return "No Meal Prep Found..."
        default: return "Not Verified..."
        }
    }

    @ViewBuilder
    var analyzingView: some View {
        if let image = selectedImage {
            VerificationLoadingView(
                image: image,
                accentColor: accentColor,
                statusText: "Verifying..."
            )
        } else {
            ProgressView()
                .scaleEffect(1.5)
        }
    }

    private var accentColor: Color {
        switch habitType {
        case .healthyBreakfast: return MPColors.success
        case .morningJournal: return MPColors.accent
        case .vitamins: return MPColors.primary
        case .skincare: return MPColors.accentGold
        case .mealPrep: return MPColors.success
        default: return MPColors.primary
        }
    }

    func resultView(_ result: CustomVerificationResult) -> some View {
        ZStack {
            VStack(spacing: MPSpacing.xxl) {
                Spacer()

                if result.isVerified {
                    // Success - with sequenced animations
                    ZStack {
                        Circle()
                            .fill(MPColors.successLight)
                            .frame(width: 120, height: 120)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(MPColors.success)
                    }
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0)

                    Text(successTitle)
                        .font(MPFont.headingMedium())
                        .foregroundColor(MPColors.textPrimary)
                        .offset(y: showTitle ? 0 : 20)
                        .opacity(showTitle ? 1.0 : 0)

                    Text(result.feedback)
                        .font(MPFont.bodyLarge())
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MPSpacing.xxxl)
                        .offset(y: showFeedback ? 0 : 15)
                        .opacity(showFeedback ? 1.0 : 0)
                } else {
                    // Failure
                    ZStack {
                        Circle()
                            .fill(MPColors.errorLight)
                            .frame(width: 120, height: 120)

                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(MPColors.error)
                    }
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0)

                    Text(failureTitle)
                        .font(MPFont.headingMedium())
                        .foregroundColor(MPColors.textPrimary)
                        .offset(y: showTitle ? 0 : 20)
                        .opacity(showTitle ? 1.0 : 0)

                    Text(result.feedback)
                        .font(MPFont.bodyLarge())
                        .foregroundColor(MPColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MPSpacing.xxxl)
                        .offset(y: showFeedback ? 0 : 15)
                        .opacity(showFeedback ? 1.0 : 0)
                }

                Spacer()

                VStack(spacing: MPSpacing.md) {
                    if !result.isVerified {
                        MPButton(title: "Try Again", style: .primary, icon: "arrow.clockwise") {
                            resetResultAnimations()
                            self.result = nil
                            selectedImage = nil
                        }
                        .offset(y: showButton ? 0 : 30)
                        .opacity(showButton ? 1.0 : 0)
                    }

                    MPButton(title: result.isVerified ? "Done" : "Cancel", style: .secondary) {
                        // If this was the last habit to complete, show celebration first
                        if wasLastHabitToComplete && result.isVerified {
                            showAppsUnlockedCelebration = true
                        } else {
                            dismiss()
                        }
                    }
                    .offset(y: showButton ? 0 : 30)
                    .opacity(showButton ? 1.0 : 0)
                }
                .padding(.horizontal, MPSpacing.xxl)
                .padding(.bottom, MPSpacing.xxxl)
            }

            // Confetti overlay for success
            if showConfetti && result.isVerified {
                MiniConfettiView(particleCount: 30)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            startResultAnimations(isVerified: result.isVerified)
        }
    }

    private func startResultAnimations(isVerified: Bool) {
        // Haptic feedback
        if isVerified {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.warning()
        }

        // Step 1: Checkmark/X scales in (0.0s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCheckmark = true
        }

        // Step 2: Title fades up (0.15s)
        withAnimation(.easeOut(duration: 0.3).delay(0.15)) {
            showTitle = true
        }

        // Step 3: Feedback text (0.3s)
        withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
            showFeedback = true
        }

        // Step 4: Confetti burst (0.4s) - only for success
        if isVerified {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showConfetti = true
                HapticManager.shared.habitCompleted()
            }
        }

        // Step 5: Button slides up (0.5s)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.5)) {
            showButton = true
        }
    }

    private func resetResultAnimations() {
        showCheckmark = false
        showTitle = false
        showFeedback = false
        showConfetti = false
        showButton = false
    }

    func errorView(_ message: String) -> some View {
        VStack(spacing: MPSpacing.xxl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(MPColors.errorLight)
                    .frame(width: 120, height: 120)

                Image(systemName: errorIcon)
                    .font(.system(size: 50))
                    .foregroundColor(MPColors.error)
            }

            Text("Verification Failed")
                .font(MPFont.headingMedium())
                .foregroundColor(MPColors.textPrimary)

            Text(message)
                .font(MPFont.bodyMedium())
                .foregroundColor(MPColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MPSpacing.xxxl)

            Spacer()

            VStack(spacing: MPSpacing.md) {
                if let image = selectedImage {
                    MPButton(title: "Try Again", style: .primary, icon: "arrow.clockwise") {
                        errorMessage = nil
                        errorIcon = "exclamationmark.triangle"
                        Task {
                            await verifyHabit(image: image)
                        }
                    }
                }

                MPButton(title: "Retake Photo", style: .secondary, icon: "camera.fill") {
                    errorMessage = nil
                    errorIcon = "exclamationmark.triangle"
                    selectedImage = nil
                }

                MPButton(title: "Cancel", style: .secondary) {
                    dismiss()
                }
            }
            .padding(.horizontal, MPSpacing.xxl)
            .padding(.bottom, MPSpacing.xxxl)
        }
        .onAppear {
            HapticManager.shared.error()
        }
    }

    func verifyHabit(image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        errorIcon = "exclamationmark.triangle"

        // Check if completing this habit will finish all habits (for celebration)
        let willCompleteAllHabits = (manager.completedCount == manager.totalEnabled - 1)
        let appLockingEnabled = manager.settings.appLockingEnabled

        do {
            result = try await manager.completePredefinedHabitVerification(habitType: habitType, image: image)
            isAnalyzing = false

            // If verification succeeded AND this was the last habit AND app locking is enabled, trigger celebration
            if result?.isVerified == true && willCompleteAllHabits && appLockingEnabled {
                wasLastHabitToComplete = true
            }
        } catch let apiError as APIError {
            errorMessage = apiError.localizedDescription
            errorIcon = apiError.iconName
            isAnalyzing = false
        } catch {
            errorMessage = error.localizedDescription
            errorIcon = "exclamationmark.triangle"
            isAnalyzing = false
        }
    }
}

#Preview {
    GenericAICameraView(manager: MorningProofManager.shared, habitType: .healthyBreakfast)
}

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

    // Animation states for initial capture view
    @State private var showIcon = false
    @State private var showText = false
    @State private var showCameraButton = false

    // Animation states for result view
    @State private var showCheckmark = false
    @State private var showTitle = false
    @State private var showFeedback = false
    @State private var showButton = false

    // Apps unlocked inline
    @State private var showAppsUnlocked = false
    @State private var wasLastHabitToComplete = false
    @State private var lockIconUnlocked = false

    var body: some View {
        ZStack {
            NavigationStack {
                GeometryReader { geometry in
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
                            captureView(geometry: geometry)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(MPColors.textTertiary)
                    }

                    ToolbarItem(placement: .principal) {
                        HStack(spacing: MPSpacing.sm) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            Text("Morning Proof")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(MPColors.textPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }

        }
    }

    // MARK: - Capture View

    func captureView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            if let image = selectedImage {
                photoSelectedView(image: image, geometry: geometry)
            } else {
                initialCaptureView
            }
        }
    }

    // MARK: - Initial Capture View (No Image)

    var initialCaptureView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Habit icon - clean, no rings
            Image(systemName: habitType.icon)
                .font(.system(size: 80))
                .foregroundColor(accentColor)
                .scaleEffect(showIcon ? 1.0 : 0.5)
                .opacity(showIcon ? 1.0 : 0)
                .frame(height: 120)

            Spacer()
                .frame(height: MPSpacing.xxxl)

            // Text content
            VStack(spacing: MPSpacing.sm) {
                Text(capturePrompt)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                Text(captureSubtitle)
                    .font(.system(size: 15))
                    .foregroundColor(MPColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MPSpacing.lg)
            }
            .offset(y: showText ? 0 : 15)
            .opacity(showText ? 1.0 : 0)

            Spacer()

            // Camera shutter button (iOS Camera style)
            CameraShutterButton {
                showingCamera = true
            }
            .scaleEffect(showCameraButton ? 1.0 : 0.7)
            .opacity(showCameraButton ? 1.0 : 0)

            Spacer()
                .frame(height: MPSpacing.xxxl + MPSpacing.lg)
        }
        .onAppear {
            startEntranceAnimations()
        }
    }

    private func startEntranceAnimations() {
        showIcon = false
        showText = false
        showCameraButton = false

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showIcon = true
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
            showText = true
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3)) {
            showCameraButton = true
        }
    }

    // MARK: - Photo Selected View

    func photoSelectedView(image: UIImage, geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: geometry.size.height * 0.55)
                .cornerRadius(MPRadius.xl)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                .padding(.horizontal, MPSpacing.xxl)

            Spacer()

            VStack(spacing: MPSpacing.md) {
                MPButton(title: "Verify Photo", style: .primary, icon: "checkmark") {
                    Task {
                        await verifyHabit(image: image)
                    }
                }
                .padding(.horizontal, MPSpacing.xxl)

                Button {
                    selectedImage = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        startEntranceAnimations()
                    }
                } label: {
                    Text("Retake Photo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
                .padding(.vertical, MPSpacing.sm)
            }
            .padding(.bottom, MPSpacing.xxxl)
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

    // MARK: - Analyzing View

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

    // MARK: - Result View

    func resultView(_ result: CustomVerificationResult) -> some View {
        ZStack {
            VStack(spacing: MPSpacing.xxl) {
                Spacer()

                if result.isVerified {
                    ZStack {
                        Circle()
                            .fill(MPColors.successLight)
                            .frame(width: 120, height: 120)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
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

                    // Inline "Apps Unlocked" indicator
                    if wasLastHabitToComplete {
                        HStack(spacing: 10) {
                            Image(systemName: lockIconUnlocked ? "lock.open.fill" : "lock.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(lockIconUnlocked ? MPColors.success : .white)
                                .contentTransition(.symbolEffect(.replace.downUp))
                                .scaleEffect(lockIconUnlocked ? 1.15 : 1.0)
                            Text("Apps Unlocked")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(lockIconUnlocked ? 1.0 : 0)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .scaleEffect(showAppsUnlocked ? 1.0 : 0.5)
                        .opacity(showAppsUnlocked ? 1.0 : 0)
                        .padding(.top, 16)
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(MPColors.errorLight)
                            .frame(width: 120, height: 120)

                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 80))
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
                        MPButton(title: "Fix & Rescan", style: .primary, icon: "arrow.clockwise") {
                            resetResultAnimations()
                            self.result = nil
                            selectedImage = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                startEntranceAnimations()
                            }
                        }
                        .offset(y: showButton ? 0 : 30)
                        .opacity(showButton ? 1.0 : 0)
                    }

                    MPButton(title: result.isVerified ? "Done" : "Cancel", style: .secondary) {
                        dismiss()
                    }
                    .offset(y: showButton ? 0 : 30)
                    .opacity(showButton ? 1.0 : 0)
                }
                .padding(.horizontal, MPSpacing.xxl)
                .padding(.bottom, MPSpacing.xxxl)
            }
        }
        .onAppear {
            startResultAnimations(isVerified: result.isVerified)
        }
    }

    private func startResultAnimations(isVerified: Bool) {
        if isVerified {
            HapticManager.shared.success()
        } else {
            HapticManager.shared.warning()
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCheckmark = true
        }

        withAnimation(.easeOut(duration: 0.3).delay(0.15)) {
            showTitle = true
        }

        withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
            showFeedback = true
        }

        if isVerified {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                HapticManager.shared.habitCompleted()
            }
        }

        // Apps Unlocked inline (0.55s) - only when last habit
        if isVerified && wasLastHabitToComplete {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.55)) {
                showAppsUnlocked = true
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.85)) {
                lockIconUnlocked = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                HapticManager.shared.light()
            }
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.7)) {
            showButton = true
        }
    }

    private func resetResultAnimations() {
        showCheckmark = false
        showTitle = false
        showFeedback = false
        showAppsUnlocked = false
        showButton = false
    }

    // MARK: - Error View

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
                MPButton(title: "Try Again", style: .primary, icon: "arrow.clockwise") {
                    errorMessage = nil
                    errorIcon = "exclamationmark.triangle"
                    if let image = selectedImage {
                        Task {
                            await verifyHabit(image: image)
                        }
                    } else {
                        showingCamera = true
                    }
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

    // MARK: - Verification

    func verifyHabit(image: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        errorIcon = "exclamationmark.triangle"

        let willCompleteAllHabits = (manager.completedCount == manager.totalEnabled - 1)


        do {
            result = try await manager.completePredefinedHabitVerification(habitType: habitType, image: image)
            isAnalyzing = false

            if result?.isVerified == true && willCompleteAllHabits {
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

import SwiftUI
import AVFoundation

struct VideoVerificationView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    let customHabit: CustomHabit

    // Video capture state
    @State private var showingVideoPicker = false
    @State private var capturedVideoURL: URL?
    @State private var videoThumbnail: UIImage?
    @State private var videoDuration: TimeInterval = 0

    // Processing state
    @State private var isExtracting = false
    @State private var isAnalyzing = false
    @State private var extractedFrames: [UIImage]?

    // Results state
    @State private var result: VideoVerificationResult?
    @State private var errorMessage: String?
    @State private var errorIcon: String = "exclamationmark.triangle"

    // Animation states for initial capture view
    @State private var showIcon = false
    @State private var showText = false
    @State private var showRecordButton = false

    // Animation states for result view
    @State private var showCheckmark = false
    @State private var showTitle = false
    @State private var showFeedback = false
    @State private var showConfetti = false
    @State private var showButton = false

    private let frameExtractor = VideoFrameExtractor()

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    MPColors.background
                        .ignoresSafeArea()

                    if isExtracting {
                        extractingView
                    } else if isAnalyzing {
                        analyzingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else if let result = result {
                        resultView(result)
                    } else if capturedVideoURL != nil {
                        videoPreviewView(geometry: geometry)
                    } else {
                        initialCaptureView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cleanupVideo()
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
        .fullScreenCover(isPresented: $showingVideoPicker) {
            VideoRecorder(videoURL: $capturedVideoURL, maxDuration: 60.0, minDuration: 2.0)
                .ignoresSafeArea()
        }
        .onChange(of: capturedVideoURL) { _, newURL in
            if let url = newURL {
                generateThumbnail(from: url)
            }
        }
    }

    // MARK: - Initial Capture View

    var initialCaptureView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Custom habit icon
            Image(systemName: customHabit.icon)
                .font(.system(size: 80))
                .foregroundColor(MPColors.accent)
                .scaleEffect(showIcon ? 1.0 : 0.5)
                .opacity(showIcon ? 1.0 : 0)
                .frame(height: 120)

            Spacer()
                .frame(height: MPSpacing.xxxl)

            // Text content
            VStack(spacing: MPSpacing.sm) {
                Text("Record a video to verify")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                if let prompt = customHabit.aiPrompt, !prompt.isEmpty {
                    Text("\"\(prompt)\"")
                        .font(.system(size: 15))
                        .foregroundColor(MPColors.textTertiary)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MPSpacing.lg)
                }

                Text("2-60 seconds")
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textTertiary)
                    .padding(.top, MPSpacing.xs)
            }
            .offset(y: showText ? 0 : 15)
            .opacity(showText ? 1.0 : 0)

            Spacer()

            // Video record button
            VideoRecordButton {
                showingVideoPicker = true
            }
            .scaleEffect(showRecordButton ? 1.0 : 0.7)
            .opacity(showRecordButton ? 1.0 : 0)

            Spacer()
                .frame(height: MPSpacing.xxxl + MPSpacing.lg)
        }
        .onAppear {
            startEntranceAnimations()
        }
    }

    private func startEntranceAnimations() {
        // Reset states first
        showIcon = false
        showText = false
        showRecordButton = false

        // Step 1: Icon scales in (0ms, spring)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showIcon = true
        }

        // Step 2: Text fades up (150ms delay)
        withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
            showText = true
        }

        // Step 3: Record button appears (300ms delay)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.3)) {
            showRecordButton = true
        }
    }

    // MARK: - Video Preview View

    func videoPreviewView(geometry: GeometryProxy) -> some View {
        VStack(spacing: MPSpacing.xl) {
            // Video thumbnail with duration badge
            ZStack(alignment: .bottomTrailing) {
                if let thumbnail = videoThumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: geometry.size.height * 0.55)
                        .cornerRadius(MPRadius.xl)
                        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                } else {
                    // Placeholder while generating thumbnail
                    RoundedRectangle(cornerRadius: MPRadius.xl)
                        .fill(MPColors.surfaceSecondary)
                        .frame(maxHeight: geometry.size.height * 0.55)
                        .overlay {
                            ProgressView()
                                .tint(MPColors.textTertiary)
                        }
                }

                // Duration badge
                if videoDuration > 0 {
                    Text(formatDuration(videoDuration))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, MPSpacing.sm)
                        .padding(.vertical, MPSpacing.xs)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(MPRadius.sm)
                        .padding(MPSpacing.md)
                }

                // Play icon overlay
                Image(systemName: "play.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, MPSpacing.xxl)

            // Button layout
            VStack(spacing: MPSpacing.md) {
                // Primary verify button
                MPButton(title: "Verify Video", style: .primary, icon: "checkmark") {
                    Task {
                        await processAndVerifyVideo()
                    }
                }
                .padding(.horizontal, MPSpacing.xxl)

                // Retake as text link
                Button {
                    retakeVideo()
                } label: {
                    Text("Record Again")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
                .padding(.vertical, MPSpacing.sm)
            }

            Spacer()
        }
        .padding(.top, MPSpacing.lg)
    }

    // MARK: - Extracting View

    var extractingView: some View {
        VStack(spacing: MPSpacing.xxl) {
            Spacer()

            // Show thumbnail dimmed
            if let thumbnail = videoThumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(MPRadius.xl)
                    .opacity(0.6)
                    .overlay {
                        RoundedRectangle(cornerRadius: MPRadius.xl)
                            .fill(Color.black.opacity(0.3))
                    }
                    .padding(.horizontal, MPSpacing.xxl)
            }

            VStack(spacing: MPSpacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(MPColors.accent)

                Text("Preparing video...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()
        }
    }

    // MARK: - Analyzing View

    var analyzingView: some View {
        VStack(spacing: MPSpacing.xxl) {
            Spacer()

            // Show extracted frames in a grid
            if let frames = extractedFrames, !frames.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: MPSpacing.sm),
                    GridItem(.flexible(), spacing: MPSpacing.sm),
                    GridItem(.flexible(), spacing: MPSpacing.sm)
                ], spacing: MPSpacing.sm) {
                    ForEach(frames.indices, id: \.self) { index in
                        Image(uiImage: frames[index])
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(MPRadius.md)
                    }
                }
                .padding(.horizontal, MPSpacing.xxl)
            }

            VStack(spacing: MPSpacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(MPColors.accent)

                Text("Analyzing video...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(MPColors.textTertiary)

                Text("\(extractedFrames?.count ?? 0) frames extracted")
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textTertiary.opacity(0.7))
            }

            Spacer()
        }
    }

    // MARK: - Result View

    func resultView(_ result: VideoVerificationResult) -> some View {
        ZStack {
            VStack(spacing: MPSpacing.xxl) {
                Spacer()

                if result.isVerified {
                    // Success - with sequenced animations
                    ZStack {
                        // Subtle glow behind checkmark
                        Circle()
                            .fill(MPColors.success.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)

                        Circle()
                            .fill(MPColors.successLight)
                            .frame(width: 120, height: 120)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(MPColors.success)
                    }
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0)

                    Text("\(customHabit.name) Verified!")
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
                            .font(.system(size: 80))
                            .foregroundColor(MPColors.error)
                    }
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0)

                    Text("Not Quite...")
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
                            resetForRetry()
                        }
                        .offset(y: showButton ? 0 : 30)
                        .opacity(showButton ? 1.0 : 0)
                    }

                    MPButton(title: result.isVerified ? "Done" : "Cancel", style: .secondary) {
                        cleanupVideo()
                        dismiss()
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
                // Dynamic button based on error type
                if errorIcon == "clock.badge.exclamationmark" {
                    // Duration error - need to record again
                    MPButton(title: "Record Again", style: .primary, icon: "video") {
                        resetForRecording()
                    }
                } else if capturedVideoURL != nil {
                    // Other error with video - can retry processing
                    MPButton(title: "Try Again", style: .primary, icon: "arrow.clockwise") {
                        errorMessage = nil
                        errorIcon = "exclamationmark.triangle"
                        Task {
                            await processAndVerifyVideo()
                        }
                    }
                } else {
                    // No video - need to record
                    MPButton(title: "Record Video", style: .primary, icon: "video") {
                        resetForRecording()
                    }
                }

                MPButton(title: "Cancel", style: .secondary) {
                    cleanupVideo()
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

    // MARK: - Video Processing

    func processAndVerifyVideo() async {
        guard let videoURL = capturedVideoURL else { return }

        // Phase 1: Extract frames
        isExtracting = true
        errorMessage = nil
        errorIcon = "exclamationmark.triangle"

        do {
            let extractionResult = try await frameExtractor.extractFrames(from: videoURL)
            extractedFrames = extractionResult.frames
            videoDuration = extractionResult.duration
            isExtracting = false

            // Phase 2: Analyze with AI
            isAnalyzing = true

            let verificationResult = try await manager.completeCustomHabitVideoVerification(
                habit: customHabit,
                frames: extractionResult.frames,
                duration: extractionResult.duration
            )

            isAnalyzing = false
            result = verificationResult

            // Clean up video file on success
            if verificationResult.isVerified {
                cleanupVideo()
            }
        } catch let extractionError as VideoFrameExtractor.ExtractionError {
            isExtracting = false
            isAnalyzing = false

            switch extractionError {
            case .durationTooShort, .durationTooLong:
                errorIcon = "clock.badge.exclamationmark"
            case .invalidVideo:
                errorIcon = "exclamationmark.triangle"
            case .frameExtractionFailed, .noFramesExtracted:
                errorIcon = "photo.badge.exclamationmark"
            }
            errorMessage = extractionError.localizedDescription
        } catch let apiError as APIError {
            isExtracting = false
            isAnalyzing = false
            errorMessage = apiError.localizedDescription
            errorIcon = apiError.iconName
        } catch {
            isExtracting = false
            isAnalyzing = false
            errorMessage = error.localizedDescription
            errorIcon = "exclamationmark.triangle"
        }
    }

    // MARK: - Helper Methods

    private func generateThumbnail(from url: URL) {
        Task {
            let asset = AVURLAsset(url: url)

            // Get duration
            if let durationValue = try? await asset.load(.duration) {
                let duration = CMTimeGetSeconds(durationValue)
                await MainActor.run {
                    self.videoDuration = duration
                }
            }

            // Generate thumbnail at 0.5s or beginning
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 800, height: 800)

            let time = CMTime(seconds: 0.5, preferredTimescale: 600)

            do {
                let (cgImage, _) = try await imageGenerator.image(at: time)
                let thumbnail = UIImage(cgImage: cgImage)
                await MainActor.run {
                    self.videoThumbnail = thumbnail
                }
            } catch {
                MPLogger.warning("Failed to generate thumbnail: \(error.localizedDescription)", category: MPLogger.general)
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func retakeVideo() {
        cleanupVideo()
        videoThumbnail = nil
        videoDuration = 0
        extractedFrames = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startEntranceAnimations()
        }
    }

    private func resetForRetry() {
        resetResultAnimations()
        result = nil
        cleanupVideo()
        videoThumbnail = nil
        videoDuration = 0
        extractedFrames = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startEntranceAnimations()
        }
    }

    private func resetForRecording() {
        errorMessage = nil
        errorIcon = "exclamationmark.triangle"
        cleanupVideo()
        videoThumbnail = nil
        videoDuration = 0
        extractedFrames = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            startEntranceAnimations()
        }
    }

    private func cleanupVideo() {
        // Remove temporary video file
        if let url = capturedVideoURL {
            try? FileManager.default.removeItem(at: url)
        }
        capturedVideoURL = nil

        // Clear extracted frames to free memory
        extractedFrames = nil
    }
}

// MARK: - Video Record Button

/// Video-style record button (red circle) following iOS Camera conventions
struct VideoRecordButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring (gray)
                Circle()
                    .stroke(Color.gray.opacity(0.4), lineWidth: 4)
                    .frame(width: 72, height: 72)

                // Inner filled circle (red)
                Circle()
                    .fill(Color.red)
                    .frame(width: 52, height: 52)
                    .scaleEffect(isPressed ? 0.85 : 1.0)
            }
        }
        .buttonStyle(VideoRecordButtonStyle(isPressed: $isPressed))
    }
}

/// Custom button style for video record button press animation
struct VideoRecordButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = newValue
                }
            }
    }
}

#Preview {
    VideoVerificationView(
        manager: MorningProofManager.shared,
        customHabit: CustomHabit(
            name: "Push-ups",
            icon: "figure.strengthtraining.traditional",
            verificationType: .aiVerified,
            mediaType: .video,
            aiPrompt: "Show me you doing 10 push-ups"
        )
    )
}

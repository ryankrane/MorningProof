import SwiftUI
import AVKit

struct VideoVerificationView: View {
    @ObservedObject var manager: MorningProofManager
    @Environment(\.dismiss) var dismiss

    let customHabit: CustomHabit

    // Video state
    @State private var showingCamera = false
    @State private var videoURL: URL?
    @State private var player: AVPlayer?
    @State private var videoDuration: TimeInterval?

    // Processing state
    @State private var isExtracting = false
    @State private var isAnalyzing = false
    @State private var extractionProgress: String = ""

    // Result state
    @State private var result: VideoVerificationResult?
    @State private var errorMessage: String?
    @State private var errorIcon: String = "exclamationmark.triangle"
    @State private var showResultTransition = false

    // Animation states for result view
    @State private var showCheckmark = false
    @State private var showTitle = false
    @State private var showFeedback = false
    @State private var showConfetti = false
    @State private var showButton = false

    var body: some View {
        NavigationStack {
            ZStack {
                MPColors.background
                    .ignoresSafeArea()

                if isExtracting {
                    extractingView
                } else if isAnalyzing {
                    analyzingView
                } else if showResultTransition, let result = result {
                    // Video result transition (simplified - no image to show)
                    resultView(result)
                } else if let error = errorMessage {
                    errorView(error)
                } else if let result = result {
                    resultView(result)
                } else {
                    captureView
                }
            }
            .navigationTitle("Verify \(customHabit.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cleanup()
                        dismiss()
                    }
                    .foregroundColor(MPColors.textTertiary)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            VideoPicker(videoURL: $videoURL)
        }
        .onChange(of: videoURL) { _, newURL in
            if let url = newURL {
                player = AVPlayer(url: url)
            }
        }
    }

    // MARK: - Capture View

    var captureView: some View {
        VStack(spacing: MPSpacing.xxl) {
            Spacer()

            if let url = videoURL, let player = player {
                // Video preview
                VStack(spacing: MPSpacing.lg) {
                    VideoPlayer(player: player)
                        .frame(height: 300)
                        .cornerRadius(MPRadius.xl)
                        .mpShadow(.medium)
                        .padding(.horizontal, MPSpacing.xxl)
                        .onAppear {
                            player.play()
                        }
                        .task {
                            videoDuration = await getVideoDuration(url: url)
                        }

                    // Duration indicator
                    if let duration = videoDuration {
                        Text("\(Int(duration)) seconds")
                            .font(MPFont.labelSmall())
                            .foregroundColor(MPColors.textTertiary)
                    }
                }

                HStack(spacing: MPSpacing.md) {
                    MPButton(title: "Retake", style: .secondary) {
                        self.player?.pause()
                        self.player = nil
                        videoURL = nil
                    }

                    MPButton(title: "Verify", style: .primary) {
                        Task {
                            await verifyVideo(url: url)
                        }
                    }
                }
                .padding(.horizontal, MPSpacing.xxl)
            } else {
                VStack(spacing: MPSpacing.xl) {
                    VStack(spacing: MPSpacing.xl) {
                        ZStack {
                            Circle()
                                .fill(MPColors.primaryLight.opacity(0.3))
                                .frame(width: 100, height: 100)

                            Image(systemName: "video.fill")
                                .font(.system(size: 44))
                                .foregroundColor(MPColors.primary)
                        }

                        VStack(spacing: MPSpacing.sm) {
                            Text("Record a video to verify")
                                .font(MPFont.bodyMedium())
                                .foregroundColor(MPColors.textSecondary)

                            Text("2-60 seconds")
                                .font(MPFont.labelSmall())
                                .foregroundColor(MPColors.textTertiary)

                            if let prompt = customHabit.aiPrompt, !prompt.isEmpty {
                                Text("\"\(prompt)\"")
                                    .font(MPFont.bodySmall())
                                    .foregroundColor(MPColors.textTertiary)
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, MPSpacing.lg)
                                    .padding(.top, MPSpacing.xs)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .background(MPColors.surface)
                    .cornerRadius(MPRadius.xl)
                    .mpShadow(.medium)
                    .padding(.horizontal, MPSpacing.xxl)

                    MPButton(title: "Record Video", style: .primary, icon: "video.fill") {
                        showingCamera = true
                    }
                    .padding(.horizontal, MPSpacing.xxl)
                }
            }

            Spacer()
        }
    }

    // MARK: - Extracting View

    var extractingView: some View {
        VStack(spacing: MPSpacing.xxl) {
            Spacer()

            VStack(spacing: MPSpacing.lg) {
                ZStack {
                    Circle()
                        .stroke(MPColors.border, lineWidth: 4)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(MPColors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isExtracting)

                    Image(systemName: "film")
                        .font(.system(size: 28))
                        .foregroundColor(MPColors.primary)
                }

                Text("Extracting frames...")
                    .font(MPFont.headingSmall())
                    .foregroundColor(MPColors.textPrimary)

                Text(extractionProgress)
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }

            Spacer()
        }
    }

    // MARK: - Analyzing View

    var analyzingView: some View {
        VStack(spacing: MPSpacing.xxl) {
            Spacer()

            VStack(spacing: MPSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(MPColors.primaryLight.opacity(0.3))
                        .frame(width: 100, height: 100)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 44))
                        .foregroundColor(MPColors.primary)
                        .symbolEffect(.pulse, options: .repeating)
                }

                Text("AI is analyzing your video...")
                    .font(MPFont.headingSmall())
                    .foregroundColor(MPColors.textPrimary)

                Text("Checking \(customHabit.name.lowercased())")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
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
                    // Success
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

                    Text("\(customHabit.name) Verified!")
                        .font(MPFont.headingMedium())
                        .foregroundColor(MPColors.textPrimary)
                        .offset(y: showTitle ? 0 : 20)
                        .opacity(showTitle ? 1.0 : 0)

                    VStack(spacing: MPSpacing.sm) {
                        Text(result.feedback)
                            .font(MPFont.bodyLarge())
                            .foregroundColor(MPColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MPSpacing.xxxl)

                        if let action = result.detectedAction {
                            Text("Detected: \(action)")
                                .font(MPFont.labelSmall())
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }
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

                    Text("Not Quite...")
                        .font(MPFont.headingMedium())
                        .foregroundColor(MPColors.textPrimary)
                        .offset(y: showTitle ? 0 : 20)
                        .opacity(showTitle ? 1.0 : 0)

                    VStack(spacing: MPSpacing.sm) {
                        Text(result.feedback)
                            .font(MPFont.bodyLarge())
                            .foregroundColor(MPColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MPSpacing.xxxl)

                        if let action = result.detectedAction {
                            Text("Detected: \(action)")
                                .font(MPFont.labelSmall())
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }
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
                        cleanup()
                        dismiss()
                    }
                    .offset(y: showButton ? 0 : 30)
                    .opacity(showButton ? 1.0 : 0)
                }
                .padding(.horizontal, MPSpacing.xxl)
                .padding(.bottom, MPSpacing.xxxl)
            }

            // Confetti for success
            if showConfetti && result.isVerified {
                MiniConfettiView(particleCount: 30)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            startResultAnimations(isVerified: result.isVerified)
        }
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
                if videoURL != nil {
                    MPButton(title: "Try Again", style: .primary, icon: "arrow.clockwise") {
                        errorMessage = nil
                        errorIcon = "exclamationmark.triangle"
                        Task {
                            await verifyVideo(url: videoURL!)
                        }
                    }
                }

                MPButton(title: "Record New Video", style: .secondary, icon: "video.fill") {
                    resetForRetry()
                }

                MPButton(title: "Cancel", style: .secondary) {
                    cleanup()
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

    // MARK: - Verification Logic

    func verifyVideo(url: URL) async {
        isExtracting = true
        extractionProgress = "Loading video..."
        errorMessage = nil
        errorIcon = "exclamationmark.triangle"

        do {
            // Extract frames
            let extractor = VideoFrameExtractor()
            extractionProgress = "Extracting frames..."
            let extraction = try await extractor.extractFrames(from: url)

            extractionProgress = "Extracted \(extraction.frames.count) frames"

            // Switch to analyzing state
            isExtracting = false
            isAnalyzing = true

            // Send to API
            result = try await manager.completeCustomHabitVideoVerification(
                habit: customHabit,
                frames: extraction.frames,
                duration: extraction.duration
            )

            isAnalyzing = false

        } catch let error as VideoFrameExtractor.ExtractionError {
            isExtracting = false
            isAnalyzing = false
            errorMessage = error.localizedDescription
            errorIcon = "exclamationmark.triangle"
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

    // MARK: - Helpers

    func getVideoDuration(url: URL) async -> TimeInterval? {
        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            return nil
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
                showConfetti = true
                HapticManager.shared.habitCompleted()
            }
        }

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

    private func resetForRetry() {
        resetResultAnimations()
        result = nil
        errorMessage = nil
        errorIcon = "exclamationmark.triangle"
        player?.pause()
        player = nil
        videoURL = nil
    }

    private func cleanup() {
        player?.pause()
        player = nil

        // Clean up temp video file
        if let url = videoURL {
            try? FileManager.default.removeItem(at: url)
        }
        videoURL = nil
    }
}

#Preview {
    VideoVerificationView(
        manager: MorningProofManager.shared,
        customHabit: CustomHabit(
            name: "10 Pushups",
            icon: "figure.strengthtraining.traditional",
            verificationType: .aiVerified,
            mediaType: .video,
            aiPrompt: "Do 10 pushups"
        )
    )
}

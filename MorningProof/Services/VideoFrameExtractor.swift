import Foundation
import AVFoundation
import UIKit

/// Extracts frames from video files for AI verification
actor VideoFrameExtractor {

    // MARK: - Types

    struct ExtractionResult {
        let frames: [UIImage]
        let duration: TimeInterval
        let frameTimestamps: [TimeInterval]
    }

    enum ExtractionError: LocalizedError {
        case invalidVideo
        case durationTooShort
        case durationTooLong
        case frameExtractionFailed
        case noFramesExtracted

        var errorDescription: String? {
            switch self {
            case .invalidVideo:
                return "Could not load the video. Please try recording again."
            case .durationTooShort:
                return "Video must be at least 2 seconds long."
            case .durationTooLong:
                return "Video must be 60 seconds or less."
            case .frameExtractionFailed:
                return "Could not extract frames from video. Please try again."
            case .noFramesExtracted:
                return "No frames could be extracted from the video."
            }
        }
    }

    // MARK: - Constants

    private let minDuration: TimeInterval = 2.0
    private let maxDuration: TimeInterval = 60.0
    private let maxFrameDimension: CGFloat = 1024  // Keep frames reasonable for API

    // MARK: - Public Methods

    /// Extracts frames from a video with count based on duration:
    /// - 2-10s: 2 frames
    /// - 10-30s: 4 frames
    /// - 30-60s: 6 frames
    func extractFrames(from videoURL: URL) async throws -> ExtractionResult {
        let asset = AVURLAsset(url: videoURL)

        // Get video duration
        let duration: TimeInterval
        do {
            let durationValue = try await asset.load(.duration)
            duration = CMTimeGetSeconds(durationValue)
        } catch {
            throw ExtractionError.invalidVideo
        }

        // Validate duration
        guard duration >= minDuration else {
            throw ExtractionError.durationTooShort
        }
        guard duration <= maxDuration else {
            throw ExtractionError.durationTooLong
        }

        // Determine frame count based on duration
        let frameCount = calculateFrameCount(for: duration)

        // Calculate evenly distributed timestamps
        let timestamps = calculateTimestamps(duration: duration, frameCount: frameCount)

        // Extract frames at those timestamps
        let frames = try await extractFramesAtTimestamps(asset: asset, timestamps: timestamps)

        guard !frames.isEmpty else {
            throw ExtractionError.noFramesExtracted
        }

        return ExtractionResult(
            frames: frames,
            duration: duration,
            frameTimestamps: timestamps
        )
    }

    // MARK: - Private Methods

    /// Determines how many frames to extract based on video duration
    private func calculateFrameCount(for duration: TimeInterval) -> Int {
        switch duration {
        case 0..<10:
            return 2   // Short clips: start + end
        case 10..<30:
            return 4   // Medium: good coverage
        default:
            return 6   // Longer: comprehensive sampling
        }
    }

    /// Calculates evenly distributed timestamps for frame extraction
    private func calculateTimestamps(duration: TimeInterval, frameCount: Int) -> [TimeInterval] {
        guard frameCount > 1 else {
            return [0]
        }

        var timestamps: [TimeInterval] = []
        let interval = duration / Double(frameCount - 1)

        for i in 0..<frameCount {
            let timestamp = min(Double(i) * interval, duration - 0.1)  // Avoid exact end
            timestamps.append(timestamp)
        }

        return timestamps
    }

    /// Extracts frames from the video at specified timestamps
    private func extractFramesAtTimestamps(asset: AVURLAsset, timestamps: [TimeInterval]) async throws -> [UIImage] {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 0.1, preferredTimescale: 600)
        imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 0.1, preferredTimescale: 600)

        // Set maximum size to keep images reasonable
        imageGenerator.maximumSize = CGSize(width: maxFrameDimension, height: maxFrameDimension)

        var frames: [UIImage] = []

        for timestamp in timestamps {
            let cmTime = CMTime(seconds: timestamp, preferredTimescale: 600)

            do {
                let (cgImage, _) = try await imageGenerator.image(at: cmTime)
                let uiImage = UIImage(cgImage: cgImage)

                // Resize if needed
                if let resizedImage = resizeImageIfNeeded(uiImage) {
                    frames.append(resizedImage)
                } else {
                    frames.append(uiImage)
                }
            } catch {
                // Log but continue - we might get other frames
                MPLogger.warning("Failed to extract frame at \(timestamp)s: \(error.localizedDescription)", category: MPLogger.general)
            }
        }

        return frames
    }

    /// Resizes image if it exceeds maximum dimensions
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage? {
        let maxDimension = maxFrameDimension

        guard image.size.width > maxDimension || image.size.height > maxDimension else {
            return image
        }

        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }
}

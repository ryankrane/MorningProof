import SwiftUI
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
    @Environment(\.dismiss) var dismiss

    /// Maximum video duration in seconds (enforced at capture time)
    var maxDuration: TimeInterval = 60.0

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeMedium  // Balance quality and file size
        picker.videoMaximumDuration = maxDuration
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: VideoPicker

        init(_ parent: VideoPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let mediaURL = info[.mediaURL] as? URL {
                // Copy to a temporary location that we control
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = UUID().uuidString + ".mov"
                let destinationURL = tempDir.appendingPathComponent(fileName)

                do {
                    // Remove existing file if present
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    // Copy the video
                    try FileManager.default.copyItem(at: mediaURL, to: destinationURL)
                    parent.videoURL = destinationURL
                } catch {
                    MPLogger.error("Failed to copy video: \(error.localizedDescription)", category: MPLogger.general)
                    parent.videoURL = mediaURL  // Fall back to original URL
                }
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

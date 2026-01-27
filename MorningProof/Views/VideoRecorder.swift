import SwiftUI
import UIKit
import AVFoundation

/// Custom video recorder that captures video WITHOUT audio (no microphone permission needed)
/// Uses AVFoundation instead of UIImagePickerController to avoid automatic audio capture
struct VideoRecorder: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
    @Environment(\.dismiss) var dismiss

    var maxDuration: TimeInterval = 60.0
    var minDuration: TimeInterval = 2.0

    func makeUIViewController(context: Context) -> VideoRecorderViewController {
        let controller = VideoRecorderViewController()
        controller.delegate = context.coordinator
        controller.maxDuration = maxDuration
        controller.minDuration = minDuration
        return controller
    }

    func updateUIViewController(_ uiViewController: VideoRecorderViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VideoRecorderDelegate {
        let parent: VideoRecorder

        init(_ parent: VideoRecorder) {
            self.parent = parent
        }

        func videoRecorderDidFinish(with url: URL) {
            parent.videoURL = url
            parent.dismiss()
        }

        func videoRecorderDidCancel() {
            parent.dismiss()
        }
    }
}

// MARK: - Delegate Protocol

protocol VideoRecorderDelegate: AnyObject {
    func videoRecorderDidFinish(with url: URL)
    func videoRecorderDidCancel()
}

// MARK: - Video Recorder View Controller

class VideoRecorderViewController: UIViewController {
    weak var delegate: VideoRecorderDelegate?
    var maxDuration: TimeInterval = 60.0
    var minDuration: TimeInterval = 2.0

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private var isRecording = false
    private var recordingStartTime: Date?
    private var durationTimer: Timer?

    // UI Elements
    private let recordButton = UIButton(type: .custom)
    private let cancelButton = UIButton(type: .system)
    private let flipCameraButton = UIButton(type: .system)
    private let durationLabel = UILabel()
    private let instructionLabel = UILabel()
    private var currentCameraPosition: AVCaptureDevice.Position = .back

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupUI()
        checkCameraPermission()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    // MARK: - Permission Check

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedAlert()
        @unknown default:
            showPermissionDeniedAlert()
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to record videos.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.delegate?.videoRecorderDidCancel()
        })
        present(alert, animated: true)
    }

    // MARK: - Capture Session Setup

    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        // Video input only (NO audio input - avoids microphone permission)
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            showError("Unable to access camera")
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        // Movie output
        let movieOutput = AVCaptureMovieFileOutput()
        movieOutput.maxRecordedDuration = CMTime(seconds: maxDuration, preferredTimescale: 600)

        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        // Preview layer
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)

        self.captureSession = session
        self.videoOutput = movieOutput
        self.previewLayer = preview

        // Start session on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            session.startRunning()
            DispatchQueue.main.async {
                self?.recordButton.isEnabled = true
            }
        }
    }

    private func stopSession() {
        durationTimer?.invalidate()
        durationTimer = nil

        if isRecording {
            videoOutput?.stopRecording()
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Cancel button (top left)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)

        // Flip camera button (top right)
        let flipConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        flipCameraButton.setImage(UIImage(systemName: "camera.rotate", withConfiguration: flipConfig), for: .normal)
        flipCameraButton.tintColor = .white
        flipCameraButton.addTarget(self, action: #selector(flipCameraTapped), for: .touchUpInside)
        flipCameraButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(flipCameraButton)

        // Duration label (top center)
        durationLabel.text = "0:00"
        durationLabel.textColor = .white
        durationLabel.font = .monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        durationLabel.textAlignment = .center
        durationLabel.isHidden = true
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(durationLabel)

        // Instruction label (above record button)
        instructionLabel.text = "Tap to start recording"
        instructionLabel.textColor = .white.withAlphaComponent(0.8)
        instructionLabel.font = .systemFont(ofSize: 15)
        instructionLabel.textAlignment = .center
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)

        // Record button (bottom center)
        setupRecordButton()
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.isEnabled = false
        view.addSubview(recordButton)

        NSLayoutConstraint.activate([
            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            // Flip camera button
            flipCameraButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            flipCameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            flipCameraButton.widthAnchor.constraint(equalToConstant: 44),
            flipCameraButton.heightAnchor.constraint(equalToConstant: 44),

            // Duration label
            durationLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            durationLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Instruction label
            instructionLabel.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: -20),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Record button
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 72),
            recordButton.heightAnchor.constraint(equalToConstant: 72),
        ])
    }

    private func setupRecordButton() {
        // Outer ring
        recordButton.layer.cornerRadius = 36
        recordButton.layer.borderWidth = 4
        recordButton.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        recordButton.backgroundColor = .clear

        // Inner red circle
        let innerCircle = UIView()
        innerCircle.backgroundColor = .red
        innerCircle.layer.cornerRadius = 26
        innerCircle.isUserInteractionEnabled = false
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.tag = 100
        recordButton.addSubview(innerCircle)

        NSLayoutConstraint.activate([
            innerCircle.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 52),
            innerCircle.heightAnchor.constraint(equalToConstant: 52),
        ])

        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
    }

    private func updateRecordButtonAppearance(recording: Bool) {
        guard let innerCircle = recordButton.viewWithTag(100) else { return }

        UIView.animate(withDuration: 0.2) {
            if recording {
                // Square stop button
                innerCircle.layer.cornerRadius = 8
                innerCircle.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            } else {
                // Circle record button
                innerCircle.layer.cornerRadius = 26
                innerCircle.transform = .identity
            }
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        if isRecording {
            videoOutput?.stopRecording()
            // Delete the partial recording
            isRecording = false
        }
        delegate?.videoRecorderDidCancel()
    }

    @objc private func flipCameraTapped() {
        guard !isRecording else { return }

        currentCameraPosition = currentCameraPosition == .back ? .front : .back

        guard let session = captureSession else { return }

        session.beginConfiguration()

        // Remove existing input
        if let currentInput = session.inputs.first as? AVCaptureDeviceInput {
            session.removeInput(currentInput)
        }

        // Add new input
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(newInput) {
            session.addInput(newInput)
        }

        session.commitConfiguration()

        // Flip animation
        UIView.transition(with: view, duration: 0.3, options: .transitionFlipFromLeft) {}
    }

    @objc private func recordTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        guard let output = videoOutput else { return }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".mov"
        let outputURL = tempDir.appendingPathComponent(fileName)

        // Remove existing file if present
        try? FileManager.default.removeItem(at: outputURL)

        output.startRecording(to: outputURL, recordingDelegate: self)
        isRecording = true
        recordingStartTime = Date()

        updateRecordButtonAppearance(recording: true)
        instructionLabel.text = "Tap to stop (min \(Int(minDuration))s)"
        durationLabel.isHidden = false
        flipCameraButton.isEnabled = false
        flipCameraButton.alpha = 0.5

        // Start duration timer
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateDurationDisplay()
        }
    }

    private func stopRecording() {
        guard let startTime = recordingStartTime else { return }

        let duration = Date().timeIntervalSince(startTime)

        if duration < minDuration {
            // Too short - show feedback but keep recording
            instructionLabel.text = "Keep recording... (min \(Int(minDuration))s)"
            UIView.animate(withDuration: 0.1) {
                self.instructionLabel.textColor = .systemYellow
            } completion: { _ in
                UIView.animate(withDuration: 0.3) {
                    self.instructionLabel.textColor = .white.withAlphaComponent(0.8)
                }
            }
            return
        }

        videoOutput?.stopRecording()
        isRecording = false
        durationTimer?.invalidate()
        durationTimer = nil

        updateRecordButtonAppearance(recording: false)
        flipCameraButton.isEnabled = true
        flipCameraButton.alpha = 1.0
    }

    private func updateDurationDisplay() {
        guard let startTime = recordingStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        durationLabel.text = String(format: "%d:%02d", minutes, seconds)

        // Visual feedback when minimum duration reached
        if duration >= minDuration && instructionLabel.text?.contains("min") == true {
            instructionLabel.text = "Tap to stop"
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.delegate?.videoRecorderDidCancel()
        })
        present(alert, animated: true)
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension VideoRecorderViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        isRecording = false
        durationTimer?.invalidate()
        durationTimer = nil

        if let error = error {
            MPLogger.error("Video recording error: \(error.localizedDescription)", category: MPLogger.general)

            // Check if this was a user-initiated stop (not an error)
            let nsError = error as NSError
            if nsError.domain == AVFoundationErrorDomain && nsError.code == AVError.Code.maximumFileSizeReached.rawValue {
                // Max duration reached - this is fine, use the video
                delegate?.videoRecorderDidFinish(with: outputFileURL)
                return
            }

            // Check if recording was cancelled
            if !FileManager.default.fileExists(atPath: outputFileURL.path) {
                return // Recording was cancelled, don't call delegate
            }

            showError("Recording failed: \(error.localizedDescription)")
            return
        }

        delegate?.videoRecorderDidFinish(with: outputFileURL)
    }
}

//
//  RecordingCameraView.swift
//  Hooked Plus iOS
//
//  Created by Spencer Newell on 11/2/25.
//

//
//  RecordingCameraView.swift
//  Hooked Plus iOS
//

import SwiftUI
import AVFoundation
import AVKit

struct RecordingCameraView: View {
    @ObservedObject var camera: CameraManager
    
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // LIVE PREVIEW
            if camera.isAuthorized {
                LazyView {
                    CameraPreview(session: camera.session)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                }
            } else {
                Text("Tap to allow camera")
                    .foregroundColor(.white)
                    .onTapGesture { camera.requestPermission() }
            }
            
            // RECORD BUTTON
            VStack {
                Spacer()
                Button {
                    camera.isRecording ? camera.stopRecording() : camera.startRecording()
                } label: {
                    Circle()
                        .fill(camera.isRecording ? Color.red : Color.white)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .fill(camera.isRecording ? Color.red : Color.clear)
                                .frame(width: camera.isRecording ? 30 : 60)
                        )
                        .shadow(radius: 10)
                }
                .padding(.bottom, 60)
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { onDismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .padding(.vertical, 48)
            .padding(.horizontal, 16)
            
            if camera.pendingVideoURL != nil || camera.lastRecordingURL != nil {
                LazyView {
                    VideoPreviewOverlay(
                        url: camera.pendingVideoURL ?? camera.lastRecordingURL!,
                        dismiss: {
                            camera.lastRecordingURL = nil
                            camera.pendingVideoURL = nil
                        },
                        upload: {
                            if let url = camera.pendingVideoURL ?? camera.lastRecordingURL {
                                Task { await camera.upload(url) }
                            }
                        }
                    )
                    .onAppear {
                        if let pending = camera.pendingVideoURL {
                            camera.pendingVideoURL = nil
                            camera.lastRecordingURL = pending
                        }
                    }
                }
            }
        }
        .alert("Camera access required", isPresented: $camera.showPermissionAlert) {
            Button("Settings") { openSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Go to Settings → Privacy → Camera")
        }
        .loading(isLoading: camera.isLoading)
    }
    
    private func openSettings() {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
}

// MARK: - PREVIEW LAYER
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Always ensure the layer matches bounds when SwiftUI resizes
        uiView.setNeedsLayout()
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = bounds
    }
}

extension View {
    func onFirstAppear(_ action: @escaping () -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }
}

struct FirstAppearModifier: ViewModifier {
    @State private var hasAppeared = false
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
}

// MARK: - PREVIEW + UPLOAD SHEET
struct VideoPreviewOverlay: View {
    let url: URL
    let dismiss: () -> Void
    let upload: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Your Clip")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                VideoPlayerView(url: url)
                    .frame(height: 400)
                    .cornerRadius(16)
                    .padding(.horizontal)
                
                HStack(spacing: 30) {
                    Button("Retake") { dismiss() }
                        .font(.title3.bold())
                        .foregroundColor(.gray)
                    
                    Button("Post") {
                        upload()
                        dismiss()
                    }
                    .buttonStyle(OutlineButtonStyle())
                    .frame(maxWidth: 200)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                }
            }
        }
        .onTapGesture {} // eat taps
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = AVPlayer(url: url)
        vc.player?.play()
        vc.showsPlaybackControls = true
        return vc
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

class CameraManager: NSObject, ObservableObject {
    var isAuthorized: Bool {
        AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    private var isSessionConfigured = false
    @Published var showPermissionAlert = false
    @Published var isRecording = false
    @Published var isLoading = false
    @Published var sessionStarted = false
    @Published var lastRecordingURL: URL?
    @Published var pendingVideoURL: URL? = nil

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.queue", qos: .userInitiated)
    private var movieOutput = AVCaptureMovieFileOutput()
    private var recordingTimer: Timer?

    // MARK: - 1. Configure on serial queue
    func configureSession() {
        
        debugPrint("Configure SESSION!")
        guard !isSessionConfigured else {
            debugPrint("Session already configured — skipping")
            return
        }
        
        session.beginConfiguration()

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let mic = AVCaptureDevice.default(for: .audio),
            let camInput = try? AVCaptureDeviceInput(device: camera),
            let micInput = try? AVCaptureDeviceInput(device: mic),
            session.canAddInput(camInput),
            session.canAddInput(micInput),
            session.canAddOutput(movieOutput)
        else {
            print("=== configureSession() FAILED ===")
            
            // 1. Devices
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            let mic = AVCaptureDevice.default(for: .audio)
            print("Camera exists: \(camera != nil)")
            print("Mic exists: \(mic != nil)")
            
            // 2. Inputs
            if let camera = camera {
                print("Cam input creatable: \(try? AVCaptureDeviceInput(device: camera) != nil)")
            }
            if let mic = mic {
                print("Mic input creatable: \(try? AVCaptureDeviceInput(device: mic) != nil)")
            }
            
            // 3. Session state
//            print("Session is configuring: \(session.isConfiguring)") // iOS 17+
            print("Session inputs count: \(session.inputs.count)")
            print("Session outputs count: \(session.outputs.count)")
            
            // 4. canAdd checks
            if let camera, let camInput = try? AVCaptureDeviceInput(device: camera) {
                print("canAddInput(camInput): \(session.canAddInput(camInput))")
            }
            if let mic, let micInput = try? AVCaptureDeviceInput(device: mic) {
                print("canAddInput(micInput): \(session.canAddInput(micInput))")
            }
            print("canAddOutput(movieOutput): \(session.canAddOutput(movieOutput))")
            
            // 5. Session preset?
            print("Current preset: \(session.sessionPreset.rawValue)")
            
            DispatchQueue.main.async { self.showPermissionAlert = true }
            session.commitConfiguration()
            return
        }

        session.addInput(camInput)
        session.addInput(micInput)
        session.addOutput(movieOutput)
        session.commitConfiguration()
        
        print("Session inputs:", session.inputs)
        print("Session outputs:", session.outputs)
        
        isSessionConfigured = true
    }

    // MARK: - 2. startRunning ONLY on serial queue
    func startSession() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
            debugPrint("Session is RUNNING!")
            debugPrint("Starting session... \(Thread.isMainThread ? "on main" : "on background")")
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            debugPrint("Session STOPPED!")
            debugPrint("Stopping session... \(Thread.isMainThread ? "on main" : "on background")")
        }
    }
    
    func initializeCameraSetup() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        if status == .authorized {
            // If authorized, configure and start running BEFORE the view is loaded.
            sessionQueue.async { [weak self] in
                self?.configureSession() // Make sure this is safe to run multiple times
                self?.startSession()     // This will start running if not already started
            }
        }
        // If status is .notDetermined, we wait for the user to tap in the UI (or the onAppear request).
    }

    // MARK: - 3. Public checkPermission (main-thread safe)
    func checkPermission() {
        isLoading = true
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        Task { @MainActor in
            switch status {
            case .authorized:
                self.startSession()
            case .notDetermined:
                self.requestPermission()
            default:
                self.showPermissionAlert = true
            }
            isLoading = false
        }
    }

    func requestPermission() {
        isLoading = true
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                if granted { self.startSession() }
                else { self.showPermissionAlert = true }
                self.isLoading = false
            }
        }
    }

    // MARK: - Recording (unchanged, but queue-safe)
    func startRecording() {
        guard !isRecording else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mov")

        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.movieOutput.connection(with: .video) != nil else {
                print("No video connection – simulator?")
                DispatchQueue.main.async { self.isRecording = false }
                return
            }
            self.movieOutput.startRecording(to: url, recordingDelegate: self)
        }
        isRecording = true
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
            self.stopRecording()
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        sessionQueue.async {
            self.movieOutput.stopRecording()
        }
        recordingTimer?.invalidate()
        isRecording = false
    }
    
    // MARK: - UPLOAD TO YOUR BACKEND
    func upload(_ url: URL) async {
        do {
            _ = try await StoryService.uploadStory(videoURL: url)
        } catch {
            
        }
    }
}

final class CameraHost: ObservableObject {
    let manager = CameraManager()
    
    init() {
        // Pre-warm the session OFF the main thread
        DispatchQueue.global(qos: .userInitiated).async {
            self.manager.configureSession()
        }
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                        didFinishRecordingTo outputFileURL: URL,
                        from connections: [AVCaptureConnection],
                        error: Error?) {
            guard error == nil else { print("Recording error:", error!); return }
            
            DispatchQueue.main.async {
                self.pendingVideoURL = outputFileURL
            }
        }
}

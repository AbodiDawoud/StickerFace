//
//  SelfieCameraPickerView.swift
//  StickerMaker
//

@preconcurrency import AVFoundation
import Observation
import SwiftUI

struct SelfieCameraPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onImageData: (Data) -> Void

    @State private var camera = SelfieCameraController()

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color(.secondarySystemBackground))

                    switch camera.state {
                    case .ready:
                        CameraPreview(session: camera.session)
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .overlay(alignment: .topTrailing) {
                                switchCameraButton
                                    .padding(14)
                            }

                    case .requestingAccess, .configuring:
                        ProgressView()
                            .controlSize(.large)

                    case .accessDenied:
                        unavailableView(
                            title: "Camera access is off",
                            subtitle: "Enable camera access in Settings to take a selfie photo."
                        )

                    case .unavailable:
                        unavailableView(
                            title: "Camera unavailable",
                            subtitle: "This device does not have a camera available for capture."
                        )

                    case .failed:
                        unavailableView(
                            title: "Camera failed",
                            subtitle: "Close this sheet and try again."
                        )
                    }
                }
                .aspectRatio(0.78, contentMode: .fit)
                .padding(.horizontal, 18)
                .padding(.top, 4)

                Spacer(minLength: 22)

                if camera.state == .ready {
                    captureButton
                        .padding(.bottom, 28)
                }
            }
        }
        .animation(.smooth, value: camera.state)
        .onDisappear(perform: camera.stop)
        .task { await camera.start() }
        .onChange(of: camera.capturedPhotoData) { _, data in
            guard let data else { return }
            onImageData(data)
            dismiss()
        }
    }

    private var header: some View {
        HStack {
            Button("Cancel", action: dismiss.callAsFunction)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            Text("Selfie")
                .font(.system(size: 17, weight: .bold))

            Spacer()

            Color.clear
                .frame(width: 56, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var captureButton: some View {
        Button(action: camera.capturePhoto) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.18), lineWidth: 5)
                    .frame(width: 82, height: 82)

                Circle()
                    .fill(Color.primary)
                    .frame(width: 66, height: 66)
            }
        }
        .accessibilityLabel("Take selfie photo")
        .transition(
            .move(edge: .bottom).combined(with: .blurReplace)
        )
    }

    private var switchCameraButton: some View {
        Button {
            camera.switchCamera()
        } label: {
            Label("Flip", systemImage: "arrow.triangle.2.circlepath.camera")
                .font(.system(size: 13.5, weight: .bold))
                .labelStyle(.iconOnly)
                .foregroundStyle(.primary)
                .frame(width: 38, height: 38)
                .background(Color(.systemBackground).opacity(0.82), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Switch camera")
    }

    private func unavailableView(title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "camera")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
        }
        .transition(
            .scale(0.9).combined(with: .blurReplace)
        )
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

@Observable
private final class SelfieCameraController: NSObject {
    private(set) var state: State = .requestingAccess
    var capturedPhotoData: Data?

    @ObservationIgnored
    let session = AVCaptureSession()

    @ObservationIgnored
    private let photoOutput = AVCapturePhotoOutput()
    
    @ObservationIgnored
    private let sessionQueue = DispatchQueue(label: "com.app.StickerMaker.selfieCamera")
    
    @ObservationIgnored
    private var activePosition: AVCaptureDevice.Position = .front

    
    func start() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()

        case .notDetermined:
            state = .requestingAccess
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            granted ? configureAndStart() : setState(.accessDenied)

        case .denied, .restricted:
            state = .accessDenied

        @unknown default:
            state = .failed
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    func capturePhoto() {
        guard state == .ready else { return }

        sessionQueue.async { [photoOutput, activePosition] in
            if let connection = photoOutput.connection(with: .video),
               connection.isVideoMirroringSupported {
                connection.isVideoMirrored = activePosition == .front
            }

            let settings = AVCapturePhotoSettings()
            
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func switchCamera() {
        guard state == .ready else { return }

        let nextPosition: AVCaptureDevice.Position = activePosition == .front ? .back : .front

        sessionQueue.async { [weak self] in
            guard let self else { return }

            guard let input = self.session.inputs
                .compactMap({ $0 as? AVCaptureDeviceInput })
                .first(where: { $0.device.hasMediaType(.video) }),
                let nextDevice = self.device(for: nextPosition),
                let nextInput = try? AVCaptureDeviceInput(device: nextDevice) else {
                return
            }

            self.session.beginConfiguration()
            self.session.removeInput(input)

            if self.session.canAddInput(nextInput) {
                self.session.addInput(nextInput)
                self.activePosition = nextPosition
                self.updatePreviewMirroring(for: nextPosition)
            } else {
                self.session.addInput(input)
            }

            self.session.commitConfiguration()
        }
    }

    private func configureAndStart() {
        state = .configuring

        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            self.session.inputs.forEach(self.session.removeInput)
            self.session.outputs.forEach(self.session.removeOutput)

            guard let camera = self.device(for: self.activePosition),
                  let input = try? AVCaptureDeviceInput(device: camera),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                self.setState(.unavailable)
                return
            }

            self.session.addInput(input)

            guard self.session.canAddOutput(self.photoOutput) else {
                self.session.commitConfiguration()
                self.setState(.failed)
                return
            }

            self.session.addOutput(self.photoOutput)
            self.updatePreviewMirroring(for: self.activePosition)
            self.session.commitConfiguration()

            self.session.startRunning()
            self.setState(.ready)
        }
    }

    private func device(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let preferredTypes: [AVCaptureDevice.DeviceType] = position == .front
            ? [.builtInTrueDepthCamera, .builtInWideAngleCamera]
            : [.builtInDualWideCamera, .builtInWideAngleCamera]

        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: preferredTypes,
            mediaType: .video,
            position: position
        )

        return session.devices.first
    }

    private func updatePreviewMirroring(for position: AVCaptureDevice.Position) {
        guard let connection = photoOutput.connection(with: .video),
              connection.isVideoMirroringSupported else { return }

        connection.isVideoMirrored = position == .front
    }

    private func setState(_ state: State) {
        Task { @MainActor in
            self.state = state
        }
    }
    
    enum State: Equatable {
        case requestingAccess
        case configuring
        case ready
        case accessDenied
        case unavailable
        case failed
    }
}

extension SelfieCameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil, let data = photo.fileDataRepresentation() else { return }

        Task { @MainActor in
            capturedPhotoData = data
        }
    }
}

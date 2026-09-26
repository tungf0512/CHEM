import AVFoundation
import CoreMedia
import Foundation
import UIKit

protocol CameraSessionControllerDelegate: AnyObject {
  func cameraSessionController(
    _ controller: CameraSessionController,
    didChangeState state: CameraLifecycleState,
    reason: String,
    code: CameraErrorCode?
  )
  func cameraSessionController(_ controller: CameraSessionController, didDiscover lenses: [CameraLens])
  func cameraSessionController(_ controller: CameraSessionController, didActivate lens: CameraLens)
  func cameraSessionController(
    _ controller: CameraSessionController,
    didChangeExposure range: ExposureBiasRange,
    appliedEV: Float
  )
  func cameraSessionController(
    _ controller: CameraSessionController,
    didChangeTelemetry telemetry: [String: Any]
  )
  func cameraSessionController(_ controller: CameraSessionController, didReport failure: CameraOperationFailure)
  func cameraSessionController(
    _ controller: CameraSessionController,
    didFailLens id: String,
    failure: CameraOperationFailure
  )
  func cameraSessionController(
    _ controller: CameraSessionController,
    didCompleteCapture result: Result<CaptureMetadata, CameraOperationFailure>
  )
}

/// The sole owner of AVCaptureSession topology and all session/device mutations.
public final class CameraSessionController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  private let sessionQueue = DispatchQueue(label: "chem.camera.session", qos: .userInitiated)
  private let videoQueue = DispatchQueue(label: "chem.camera.video", qos: .userInteractive)
  private let session = AVCaptureSession()
  private let catalog = CameraDeviceCatalog()
  private let focusController = CameraFocusController()
  private let exposureController = CameraExposureController()
  private let photoCaptureCoordinator: PhotoCaptureCoordinator
  private let onVideoFrame: (CVPixelBuffer) -> Void
  private var activeInput: AVCaptureDeviceInput?
  private var photoOutput: AVCapturePhotoOutput?
  private var videoOutput: AVCaptureVideoDataOutput?
  private var devices: [AVCaptureDevice] = []
  private var lensModels: [CameraLens] = []
  private var activeLens: CameraLens?
  private var isConfigured = false
  private var desiredActive = false
  private var previewGeometry = CameraPreviewGeometry(width: 0, height: 0, orientation: .portrait)
  private var appliedEV: Float = 0
  private var stateMachine = CameraStateMachine()
  private var telemetryTimer: DispatchSourceTimer?
  private var observerTokens: [NSObjectProtocol] = []

  weak var delegate: CameraSessionControllerDelegate?
  init(
    photoCaptureCoordinator: PhotoCaptureCoordinator,
    onVideoFrame: @escaping (CVPixelBuffer) -> Void
  ) {
    self.photoCaptureCoordinator = photoCaptureCoordinator
    self.onVideoFrame = onVideoFrame
    super.init()
    observeLifecycle()
  }

  deinit {
    observerTokens.forEach(NotificationCenter.default.removeObserver)
    telemetryTimer?.cancel()
  }

  public func setActive(_ active: Bool) {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      self.desiredActive = active
      if active {
        self.startIfAuthorized()
      } else {
        self.stopSession()
      }
    }
  }

  /// Synchronously stops capture and breaks AVFoundation delegate retention before teardown.
  public func invalidate() {
    sessionQueue.sync {
      desiredActive = false
      stopSession()
      videoOutput?.setSampleBufferDelegate(nil, queue: nil)
      session.beginConfiguration()
      for input in session.inputs { session.removeInput(input) }
      for output in session.outputs { session.removeOutput(output) }
      session.commitConfiguration()
      activeInput = nil
      photoOutput = nil
      videoOutput = nil
      activeLens = nil
      devices = []
      lensModels = []
      isConfigured = false
    }
  }

  public func updatePreviewGeometry(_ geometry: CameraPreviewGeometry) {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      self.previewGeometry = geometry
      self.updateCaptureOrientation()
    }
  }

  public func selectLens(id: String) {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      guard let lens = self.lensModels.first(where: { $0.id == id }),
            let device = self.devices.first(where: { $0.uniqueID == id }) else {
        self.delegate?.cameraSessionController(
          self,
          didFailLens: id,
          failure: CameraOperationFailure(code: .lensSwitchFailed, message: "The requested rear lens is no longer available.")
        )
        return
      }
      guard self.activeLens?.id != id else { return }

      do {
        let newInput = try AVCaptureDeviceInput(device: device)
        self.session.beginConfiguration()
        defer { self.session.commitConfiguration() }

        if let oldInput = self.activeInput {
          self.session.removeInput(oldInput)
        }
        guard self.session.canAddInput(newInput) else {
          if let oldInput = self.activeInput, self.session.canAddInput(oldInput) {
            self.session.addInput(oldInput)
          }
          throw CameraOperationFailure(code: .lensSwitchFailed, message: "The camera session rejected the selected lens.")
        }
        self.session.addInput(newInput)
        self.activeInput = newInput
        self.activeLens = lens
        self.appliedEV = device.exposureTargetBias
        self.delegate?.cameraSessionController(self, didActivate: lens)
        self.publishExposure(for: device)
      } catch let failure as CameraOperationFailure {
        self.delegate?.cameraSessionController(self, didFailLens: id, failure: failure)
      } catch {
        self.delegate?.cameraSessionController(
          self,
          didFailLens: id,
          failure: CameraOperationFailure(code: .lensSwitchFailed, message: error.localizedDescription)
        )
      }
    }
  }

  public func focusAndExpose(normalizedX: CGFloat, normalizedY: CGFloat) {
    sessionQueue.async { [weak self] in
      guard let self, let device = self.activeInput?.device, self.session.isRunning else {
        return
      }
      do {
        try self.focusController.focusAndExpose(
          device: device,
          normalizedX: normalizedX,
          normalizedY: normalizedY,
          geometry: self.previewGeometry
        )
      } catch {
        self.delegate?.cameraSessionController(self, didReport: CameraOperationFailure(
          code: .focusFailed,
          message: error.localizedDescription
        ))
      }
    }
  }

  public func setExposureCompensation(_ ev: Float) {
    sessionQueue.async { [weak self] in
      guard let self, let device = self.activeInput?.device, self.session.isRunning else {
        return
      }
      self.exposureController.apply(ev: ev, to: device) { [weak self, weak device] result in
        guard let self else { return }
        switch result {
        case .success(let value):
          self.sessionQueue.async {
            guard let device else { return }
            self.appliedEV = value
            self.publishExposure(for: device)
          }
        case .failure(let failure):
          self.delegate?.cameraSessionController(self, didReport: failure)
        }
      }
    }
  }

  public func capture() {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      guard self.desiredActive,
            self.session.isRunning,
            let output = self.photoOutput,
            let lensID = self.activeLens?.id else {
        self.delegate?.cameraSessionController(
          self,
          didCompleteCapture: .failure(CameraOperationFailure(
            code: .captureFailed,
            message: "The camera is not ready to capture a still image."
          ))
        )
        return
      }
      self.photoCaptureCoordinator.capture(using: output, lensID: lensID) { [weak self] result in
        guard let self else { return }
        self.delegate?.cameraSessionController(self, didCompleteCapture: result)
      }
    }
  }

  public func reportRendererFailure(_ message: String) {
    sessionQueue.async { [weak self] in
      guard let self else { return }
      self.desiredActive = false
      self.telemetryTimer?.cancel()
      self.telemetryTimer = nil
      if self.session.isRunning {
        self.session.stopRunning()
      }
      self.transition(to: .failed, reason: message, code: .rendererFailed)
      self.delegate?.cameraSessionController(self, didReport: CameraOperationFailure(
        code: .rendererFailed,
        message: message
      ))
    }
  }

  public func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    onVideoFrame(imageBuffer)
  }

  private func startIfAuthorized() {
    guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
      transition(to: .failed, reason: "Camera permission is not authorized.", code: .permissionDenied)
      return
    }
    guard configureIfNeeded() else { return }
    guard desiredActive else { return }
    if !session.isRunning {
      session.startRunning()
    }
    guard session.isRunning else {
      transition(to: .failed, reason: "AVFoundation did not start the camera session.", code: .sessionConfigurationFailed)
      return
    }
    transition(to: .running)
    if let activeLens {
      delegate?.cameraSessionController(self, didActivate: activeLens)
    }
    if let device = activeInput?.device {
      publishExposure(for: device)
    }
    startTelemetryTimer()
  }

  private func configureIfNeeded() -> Bool {
    if isConfigured { return true }
    transition(to: .configuring)
    let discovered = catalog.availableRearDevices()
    guard let device = catalog.preferredDevice(from: discovered) else {
      transition(to: .failed, reason: "No rear camera is available on this device.", code: .cameraUnavailable)
      return false
    }

    do {
      let input = try AVCaptureDeviceInput(device: device)
      let photo = AVCapturePhotoOutput()
      let video = AVCaptureVideoDataOutput()
      video.alwaysDiscardsLateVideoFrames = true
      video.videoSettings = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
      ]

      session.beginConfiguration()
      defer { session.commitConfiguration() }
      if session.canSetSessionPreset(.photo) {
        session.sessionPreset = .photo
      } else if session.canSetSessionPreset(.high) {
        session.sessionPreset = .high
      }
      guard session.canAddInput(input) else {
        transition(to: .failed, reason: "The rear camera input cannot be added.", code: .sessionConfigurationFailed)
        return false
      }
      session.addInput(input)
      guard session.canAddOutput(photo) else {
        session.removeInput(input)
        transition(to: .failed, reason: "The still-photo output cannot be added.", code: .sessionConfigurationFailed)
        return false
      }
      session.addOutput(photo)
      guard session.canAddOutput(video) else {
        session.removeOutput(photo)
        session.removeInput(input)
        transition(to: .failed, reason: "The live-video output cannot be added.", code: .sessionConfigurationFailed)
        return false
      }
      session.addOutput(video)

      activeInput = input
      photoOutput = photo
      videoOutput = video
      updateCaptureOrientation()
      devices = discovered
      lensModels = catalog.lensModels(from: discovered)
      activeLens = lensModels.first(where: { $0.id == device.uniqueID })
      video.setSampleBufferDelegate(self, queue: videoQueue)
      isConfigured = true
      delegate?.cameraSessionController(self, didDiscover: lensModels)
      if let activeLens {
        delegate?.cameraSessionController(self, didActivate: activeLens)
      }
      return true
    } catch {
      transition(to: .failed, reason: error.localizedDescription, code: .sessionConfigurationFailed)
      return false
    }
  }

  private func stopSession() {
    telemetryTimer?.cancel()
    telemetryTimer = nil
    if session.isRunning {
      session.stopRunning()
    }
    transition(to: .idle)
  }

  private func publishExposure(for device: AVCaptureDevice) {
    let range = exposureController.bounds(for: device)
    delegate?.cameraSessionController(self, didChangeExposure: range, appliedEV: appliedEV)
  }

  /// Photo output follows the current interface orientation; preview buffers stay sensor-oriented
  /// and receive the matching transform in MetalPreviewRenderer.
  private func updateCaptureOrientation() {
    guard let connection = photoOutput?.connection(with: .video),
          connection.isVideoOrientationSupported else { return }
    switch previewGeometry.orientation {
    case .portrait:
      connection.videoOrientation = .portrait
    case .portraitUpsideDown:
      connection.videoOrientation = .portraitUpsideDown
    case .landscapeLeft:
      connection.videoOrientation = .landscapeLeft
    case .landscapeRight:
      connection.videoOrientation = .landscapeRight
    default:
      connection.videoOrientation = .portrait
    }
  }

  private func startTelemetryTimer() {
    telemetryTimer?.cancel()
    let timer = DispatchSource.makeTimerSource(queue: sessionQueue)
    timer.schedule(deadline: .now() + .milliseconds(200), repeating: .milliseconds(500))
    timer.setEventHandler { [weak self] in self?.publishTelemetry() }
    telemetryTimer = timer
    timer.resume()
  }

  private func publishTelemetry() {
    guard desiredActive, session.isRunning,
          let device = activeInput?.device,
          let lens = activeLens else { return }
    let duration = CMTimeGetSeconds(device.exposureDuration)
    delegate?.cameraSessionController(self, didChangeTelemetry: [
      "iso": Double(device.iso),
      "shutterSeconds": duration.isFinite && duration > 0 ? duration : 0,
      "lensDisplay": lens.displayZoom,
      "captureExposureCompensationEV": Double(device.exposureTargetBias),
    ])
  }

  private func transition(
    to state: CameraLifecycleState,
    reason: String = "",
    code: CameraErrorCode? = nil
  ) {
    guard stateMachine.transition(to: state) else { return }
    CameraLogger.lifecycle(state, reason: reason)
    delegate?.cameraSessionController(self, didChangeState: state, reason: reason, code: code)
  }

  private func observeLifecycle() {
    let center = NotificationCenter.default
    observerTokens.append(center.addObserver(
      forName: UIApplication.willResignActiveNotification,
      object: nil,
      queue: nil
    ) { [weak self] _ in
      guard let self else { return }
      self.sessionQueue.async {
        guard self.desiredActive else { return }
        self.stopSession()
      }
    })
    observerTokens.append(center.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: nil
    ) { [weak self] _ in
      guard let self else { return }
      self.sessionQueue.async {
        guard self.desiredActive else { return }
        self.stopSession()
      }
    })
    observerTokens.append(center.addObserver(
      forName: UIApplication.willEnterForegroundNotification,
      object: nil,
      queue: nil
    ) { [weak self] _ in
      guard let self else { return }
      self.sessionQueue.async {
        guard self.desiredActive else { return }
        self.startIfAuthorized()
      }
    })
    observerTokens.append(center.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: nil
    ) { [weak self] _ in
      guard let self else { return }
      self.sessionQueue.async {
        guard self.desiredActive else { return }
        self.startIfAuthorized()
      }
    })
    observerTokens.append(center.addObserver(
      forName: .AVCaptureSessionWasInterrupted,
      object: session,
      queue: nil
    ) { [weak self] notification in
      guard let self else { return }
      self.sessionQueue.async {
        let reason = (notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as? NSNumber)
          .map { "AVFoundation interruption reason \($0.intValue)" } ?? "Camera interrupted by the system."
        self.transition(to: .interrupted, reason: reason, code: .interrupted)
      }
    })
    observerTokens.append(center.addObserver(
      forName: .AVCaptureSessionInterruptionEnded,
      object: session,
      queue: nil
    ) { [weak self] _ in
      guard let self else { return }
      self.sessionQueue.async {
        if self.desiredActive {
          self.startIfAuthorized()
        } else {
          self.transition(to: .idle)
        }
      }
    })
    observerTokens.append(center.addObserver(
      forName: .AVCaptureSessionRuntimeError,
      object: session,
      queue: nil
    ) { [weak self] notification in
      guard let self else { return }
      self.sessionQueue.async {
        let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError
        if error?.code == .mediaServicesWereReset, self.desiredActive {
          self.resetConfiguration()
          self.startIfAuthorized()
        } else {
          self.transition(
            to: .failed,
            reason: error?.localizedDescription ?? "AVFoundation reported a camera session error.",
            code: .sessionConfigurationFailed
          )
        }
      }
    })
  }

  private func resetConfiguration() {
    videoOutput?.setSampleBufferDelegate(nil, queue: nil)
    session.beginConfiguration()
    for input in session.inputs { session.removeInput(input) }
    for output in session.outputs { session.removeOutput(output) }
    session.commitConfiguration()
    activeInput = nil
    photoOutput = nil
    videoOutput = nil
    activeLens = nil
    devices = []
    lensModels = []
    isConfigured = false
  }
}

import AVFoundation
import CoreVideo
import Foundation
import MetalKit
import UIKit

@objc public protocol CHEMCameraEngineDelegate: AnyObject {
  func cameraEngineDidChangeState(_ state: String, reason: String, code: String)
  func cameraEngineDidChangeLenses(_ lenses: [[String: Any]])
  func cameraEngineDidActivateLens(_ lens: [String: Any])
  func cameraEngineDidChangeExposure(_ exposure: [String: NSNumber])
  func cameraEngineDidChangeTelemetry(_ telemetry: [String: Any])
  func cameraEngineDidChangePerformanceMetrics(_ metrics: [String: Any])
  func cameraEngineDidFailCapture(_ failure: [String: String])
  func cameraEngineDidFailLens(_ failure: [String: String])
  func cameraEngineDidReportError(_ failure: [String: String])
  func cameraEngineDidCompleteCapture(_ metadata: [String: Any])
}

/// Per-mounted-preview coordinator; the stable Fabric view retains its session across prop updates.
@objc public final class CHEMCameraEngine: NSObject, CameraSessionControllerDelegate {
  @objc public weak var delegate: CHEMCameraEngineDelegate?

  private let renderer: MetalPreviewRenderer
  private let sessionController: CameraSessionController

  @objc public override init() {
    let applicationSupport = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first?.appendingPathComponent("CHEM/Captures", isDirectory: true)
    let store = CaptureStore(rootURL: applicationSupport)
    let photoCoordinator = PhotoCaptureCoordinator(store: store)
    let previewRenderer = MetalPreviewRenderer()

    renderer = previewRenderer
    sessionController = CameraSessionController(
      photoCaptureCoordinator: photoCoordinator,
      onVideoFrame: { [weak previewRenderer] pixelBuffer in previewRenderer?.enqueue(pixelBuffer) }
    )

    super.init()
    sessionController.delegate = self
    renderer.onFailure = { [weak self] message in
      self?.sessionController.reportRendererFailure(message)
    }
    #if DEBUG
    renderer.onMetrics = { [weak self] metrics in
      self?.onMain { delegate in delegate.cameraEngineDidChangePerformanceMetrics(metrics) }
    }
    #endif
  }

  deinit {
    renderer.attach(to: nil)
    sessionController.invalidate()
  }

  @objc public func attachPreview(_ view: MTKView?) {
    renderer.attach(to: view)
  }

  @objc public func setActive(_ active: Bool) {
    if active, let failureMessage = renderer.failureMessage {
      sessionController.reportRendererFailure(failureMessage)
      return
    }
    renderer.setActive(active)
    sessionController.setActive(active)
  }

  @objc public func selectLens(id: String) {
    sessionController.selectLens(id: id)
  }

  @objc public func focusAndExpose(normalizedX: Double, normalizedY: Double) {
    sessionController.focusAndExpose(
      normalizedX: CGFloat(normalizedX),
      normalizedY: CGFloat(normalizedY)
    )
  }

  @objc public func setExposureCompensation(_ ev: Double) {
    sessionController.setExposureCompensation(Float(ev))
  }

  @objc public func capture() {
    let playHaptic = {
      let generator = UIImpactFeedbackGenerator(style: .light)
      generator.prepare()
      generator.impactOccurred(intensity: 0.72)
    }
    if Thread.isMainThread {
      playHaptic()
    } else {
      DispatchQueue.main.async(execute: playHaptic)
    }
    sessionController.capture()
  }

  @objc public func updatePreviewGeometry(width: Double, height: Double, orientation: Int) {
    let cameraOrientation = CameraOrientation(rawValue: orientation) ?? .portrait
    renderer.setOrientation(cameraOrientation.rawValue)
    sessionController.updatePreviewGeometry(CameraPreviewGeometry(
      width: width,
      height: height,
      orientation: cameraOrientation
    ))
  }

  func cameraSessionController(
    _ controller: CameraSessionController,
    didChangeState state: CameraLifecycleState,
    reason: String,
    code: CameraErrorCode?
  ) {
    let value: String
    switch state {
    case .idle: value = "idle"
    case .configuring: value = "configuring"
    case .running: value = "running"
    case .interrupted: value = "interrupted"
    case .failed: value = "failed"
    }
    #if DEBUG
    renderer.updateCameraContext(state: value)
    #endif
    onMain { delegate in
      delegate.cameraEngineDidChangeState(value, reason: reason, code: code?.rawValue ?? "")
    }
  }

  func cameraSessionController(_ controller: CameraSessionController, didDiscover lenses: [CameraLens]) {
    let payload = lenses.map { lens in
      lensPayload(lens)
    }
    onMain { delegate in delegate.cameraEngineDidChangeLenses(payload) }
  }

  func cameraSessionController(_ controller: CameraSessionController, didActivate lens: CameraLens) {
    let payload = lensPayload(lens)
    #if DEBUG
    renderer.updateCameraContext(activeLens: lens.displayZoom)
    #endif
    onMain { delegate in delegate.cameraEngineDidActivateLens(payload) }
  }

  func cameraSessionController(
    _ controller: CameraSessionController,
    didChangeCaptureFrameRateLimit maximumFPS: Int
  ) {
    renderer.updateCaptureDeviceFrameRateLimit(maximumFPS)
  }

  func cameraSessionController(
    _ controller: CameraSessionController,
    didChangeExposure range: ExposureBiasRange,
    appliedEV: Float
  ) {
    let payload = [
      "minimumEV": NSNumber(value: range.minimum),
      "maximumEV": NSNumber(value: range.maximum),
      "appliedEV": NSNumber(value: appliedEV),
    ]
    onMain { delegate in delegate.cameraEngineDidChangeExposure(payload) }
  }

  func cameraSessionController(
    _ controller: CameraSessionController,
    didChangeTelemetry telemetry: [String: Any]
  ) {
    onMain { delegate in delegate.cameraEngineDidChangeTelemetry(telemetry) }
  }

  func cameraSessionController(_ controller: CameraSessionController, didReport failure: CameraOperationFailure) {
    let payload = ["code": failure.code.rawValue, "message": failure.message]
    onMain { delegate in delegate.cameraEngineDidReportError(payload) }
  }

  func cameraSessionController(
    _ controller: CameraSessionController,
    didFailLens id: String,
    failure: CameraOperationFailure
  ) {
    let payload = ["id": id, "code": failure.code.rawValue, "message": failure.message]
    onMain { delegate in delegate.cameraEngineDidFailLens(payload) }
  }

  func cameraSessionController(
    _ controller: CameraSessionController,
    didCompleteCapture result: Result<CaptureMetadata, CameraOperationFailure>
  ) {
    switch result {
    case .success(let metadata):
      let payload: [String: Any] = [
        "id": metadata.id,
        "sourceUri": metadata.sourceUri,
        "thumbnailUri": metadata.thumbnailUri.map { $0 as Any } ?? NSNull(),
        "width": metadata.width,
        "height": metadata.height,
        "capturedAt": metadata.capturedAt,
        "lensId": metadata.lensId,
        "physicalDeviceId": metadata.physicalDeviceId,
        "captureMode": metadata.captureMode.rawValue,
        "deviceZoomFactor": metadata.deviceZoomFactor,
        "sourceSafe": metadata.sourceSafe,
        "complete": metadata.complete,
        "recoverableError": metadata.recoverableError.map { $0 as Any } ?? NSNull(),
      ]
      onMain { delegate in
        CameraLogger.capture(metadata.id, stage: "event_emitted")
        delegate.cameraEngineDidCompleteCapture(payload)
      }
    case .failure(let failure):
      let payload = ["code": failure.code.rawValue, "message": failure.message]
      onMain { delegate in delegate.cameraEngineDidFailCapture(payload) }
    }
  }

  private func onMain(_ send: @escaping (CHEMCameraEngineDelegate) -> Void) {
    DispatchQueue.main.async { [weak self] in
      guard let delegate = self?.delegate else { return }
      send(delegate)
    }
  }

  private func lensPayload(_ lens: CameraLens) -> [String: Any] {
    [
      "id": lens.id,
      "physicalDeviceId": lens.physicalDeviceID,
      "role": lens.role.rawValue,
      "captureMode": lens.captureMode.rawValue,
      "deviceZoomFactor": lens.deviceZoomFactor,
      "displayZoom": lens.displayZoom,
    ]
  }
}

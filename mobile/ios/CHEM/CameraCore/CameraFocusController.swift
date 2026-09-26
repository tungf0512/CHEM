import AVFoundation
import CoreMedia
import Foundation

public final class CameraFocusController {
  public init() {}

  public func focusAndExpose(
    device: AVCaptureDevice,
    normalizedX: CGFloat,
    normalizedY: CGFloat,
    geometry: CameraPreviewGeometry
  ) throws {
    let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
    let point = CameraCoordinateMapper.sensorPoint(
      fromDisplayPoint: NormalizedCameraPoint(x: Double(normalizedX), y: Double(normalizedY)),
      geometry: geometry,
      sensorWidth: Double(dimensions.width),
      sensorHeight: Double(dimensions.height)
    )

    try device.lockForConfiguration()
    defer { device.unlockForConfiguration() }

    if device.isFocusPointOfInterestSupported {
      device.focusPointOfInterest = CGPoint(x: point.x, y: point.y)
      if device.isFocusModeSupported(.autoFocus) {
        device.focusMode = .autoFocus
      } else if device.isFocusModeSupported(.continuousAutoFocus) {
        device.focusMode = .continuousAutoFocus
      }
    }

    if device.isExposurePointOfInterestSupported {
      device.exposurePointOfInterest = CGPoint(x: point.x, y: point.y)
      if device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure
      } else if device.isExposureModeSupported(.autoExpose) {
        device.exposureMode = .autoExpose
      }
    }
  }
}

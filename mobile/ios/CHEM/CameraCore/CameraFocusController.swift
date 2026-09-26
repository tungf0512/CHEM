import AVFoundation
import CoreMedia
import Foundation
import UIKit

public struct CameraPreviewGeometry {
  public let width: CGFloat
  public let height: CGFloat
  public let orientation: UIInterfaceOrientation

  public init(width: CGFloat, height: CGFloat, orientation: UIInterfaceOrientation) {
    self.width = width
    self.height = height
    self.orientation = orientation
  }
}

public enum CameraCoordinateMapper {
  /// Maps a point in the aspect-filled, upright Metal view into AVFoundation's sensor space.
  public static func devicePoint(
    normalizedX: CGFloat,
    normalizedY: CGFloat,
    geometry: CameraPreviewGeometry,
    sensorWidth: CGFloat,
    sensorHeight: CGFloat
  ) -> CGPoint {
    let x = min(1, max(0, normalizedX))
    let y = min(1, max(0, normalizedY))
    let portrait = geometry.orientation == .portrait || geometry.orientation == .portraitUpsideDown
    let orientedWidth = portrait ? sensorHeight : sensorWidth
    let orientedHeight = portrait ? sensorWidth : sensorHeight
    let sourceAspect = orientedWidth / max(1, orientedHeight)
    let viewAspect = geometry.width / max(1, geometry.height)
    var croppedX = x
    var croppedY = y

    if sourceAspect > viewAspect {
      let visibleWidth = viewAspect / sourceAspect
      croppedX = (x - 0.5) * visibleWidth + 0.5
    } else {
      let visibleHeight = sourceAspect / viewAspect
      croppedY = (y - 0.5) * visibleHeight + 0.5
    }

    let sensorPoint: CGPoint
    switch geometry.orientation {
    case .portrait:
      sensorPoint = CGPoint(x: croppedY, y: 1 - croppedX)
    case .portraitUpsideDown:
      sensorPoint = CGPoint(x: 1 - croppedY, y: croppedX)
    case .landscapeLeft:
      sensorPoint = CGPoint(x: 1 - croppedX, y: 1 - croppedY)
    case .landscapeRight:
      sensorPoint = CGPoint(x: croppedX, y: croppedY)
    default:
      sensorPoint = CGPoint(x: croppedX, y: croppedY)
    }

    return CGPoint(
      x: min(1, max(0, sensorPoint.x)),
      y: min(1, max(0, sensorPoint.y))
    )
  }
}

public final class CameraFocusController {
  public init() {}

  public func focusAndExpose(
    device: AVCaptureDevice,
    normalizedX: CGFloat,
    normalizedY: CGFloat,
    geometry: CameraPreviewGeometry
  ) throws {
    let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
    let point = CameraCoordinateMapper.devicePoint(
      normalizedX: normalizedX,
      normalizedY: normalizedY,
      geometry: geometry,
      sensorWidth: CGFloat(dimensions.width),
      sensorHeight: CGFloat(dimensions.height)
    )

    try device.lockForConfiguration()
    defer { device.unlockForConfiguration() }

    if device.isFocusPointOfInterestSupported {
      device.focusPointOfInterest = point
      if device.isFocusModeSupported(.autoFocus) {
        device.focusMode = .autoFocus
      } else if device.isFocusModeSupported(.continuousAutoFocus) {
        device.focusMode = .continuousAutoFocus
      }
    }

    if device.isExposurePointOfInterestSupported {
      device.exposurePointOfInterest = point
      if device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure
      } else if device.isExposureModeSupported(.autoExpose) {
        device.exposureMode = .autoExpose
      }
    }
  }
}

import Foundation

/// Matches the raw values of `UIInterfaceOrientation` without coupling domain math to UIKit.
public enum CameraOrientation: Int, CaseIterable, Codable, Sendable {
  case portrait = 1
  case portraitUpsideDown = 2
  case landscapeLeft = 3
  case landscapeRight = 4
}

public struct CameraPreviewGeometry: Equatable, Sendable {
  public let width: Double
  public let height: Double
  public let orientation: CameraOrientation

  public init(width: Double, height: Double, orientation: CameraOrientation) {
    self.width = width
    self.height = height
    self.orientation = orientation
  }
}

public struct NormalizedCameraPoint: Equatable, Sendable {
  public let x: Double
  public let y: Double

  public init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }
}

/// Shared definition for the preview shader's aspect-fill transform and inverse focus mapping.
public enum CameraCoordinateMapper {
  public static func sensorPoint(
    fromDisplayPoint point: NormalizedCameraPoint,
    geometry: CameraPreviewGeometry,
    sensorWidth: Double,
    sensorHeight: Double
  ) -> NormalizedCameraPoint {
    let display = clamp(point)
    let crop = aspectFillCrop(
      x: display.x,
      y: display.y,
      geometry: geometry,
      sensorWidth: sensorWidth,
      sensorHeight: sensorHeight
    )

    switch geometry.orientation {
    case .portrait:
      return clamp(NormalizedCameraPoint(x: crop.y, y: 1 - crop.x))
    case .portraitUpsideDown:
      return clamp(NormalizedCameraPoint(x: 1 - crop.y, y: crop.x))
    case .landscapeLeft:
      return clamp(NormalizedCameraPoint(x: 1 - crop.x, y: 1 - crop.y))
    case .landscapeRight:
      return crop
    }
  }

  public static func displayPoint(
    fromSensorPoint point: NormalizedCameraPoint,
    geometry: CameraPreviewGeometry,
    sensorWidth: Double,
    sensorHeight: Double
  ) -> NormalizedCameraPoint {
    let sensor = clamp(point)
    let crop: NormalizedCameraPoint
    switch geometry.orientation {
    case .portrait:
      crop = NormalizedCameraPoint(x: 1 - sensor.y, y: sensor.x)
    case .portraitUpsideDown:
      crop = NormalizedCameraPoint(x: sensor.y, y: 1 - sensor.x)
    case .landscapeLeft:
      crop = NormalizedCameraPoint(x: 1 - sensor.x, y: 1 - sensor.y)
    case .landscapeRight:
      crop = sensor
    }

    let orientedWidth = isPortrait(geometry.orientation) ? sensorHeight : sensorWidth
    let orientedHeight = isPortrait(geometry.orientation) ? sensorWidth : sensorHeight
    let sourceAspect = orientedWidth / max(1, orientedHeight)
    let viewAspect = geometry.width / max(1, geometry.height)
    var x = crop.x
    var y = crop.y
    if sourceAspect > viewAspect {
      let visibleWidth = viewAspect / sourceAspect
      x = (crop.x - 0.5) / visibleWidth + 0.5
    } else {
      let visibleHeight = sourceAspect / viewAspect
      y = (crop.y - 0.5) / visibleHeight + 0.5
    }
    return clamp(NormalizedCameraPoint(x: x, y: y))
  }

  private static func aspectFillCrop(
    x: Double,
    y: Double,
    geometry: CameraPreviewGeometry,
    sensorWidth: Double,
    sensorHeight: Double
  ) -> NormalizedCameraPoint {
    let orientedWidth = isPortrait(geometry.orientation) ? sensorHeight : sensorWidth
    let orientedHeight = isPortrait(geometry.orientation) ? sensorWidth : sensorHeight
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
    return NormalizedCameraPoint(x: croppedX, y: croppedY)
  }

  private static func isPortrait(_ orientation: CameraOrientation) -> Bool {
    orientation == .portrait || orientation == .portraitUpsideDown
  }

  private static func clamp(_ point: NormalizedCameraPoint) -> NormalizedCameraPoint {
    NormalizedCameraPoint(
      x: min(1, max(0, point.x)),
      y: min(1, max(0, point.y))
    )
  }
}

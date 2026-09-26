import Foundation

public struct PhysicalCameraDescriptor: Equatable, Sendable {
  public let id: String
  public let role: LensRole
  /// Optical zoom relative to the physical main camera, independent of its local crop factor.
  public let baseDisplayZoom: Double
  public let videoZoomFactorUpscaleThreshold: Double
  public let maximumVideoZoomFactor: Double

  public init(
    id: String,
    role: LensRole,
    baseDisplayZoom: Double,
    videoZoomFactorUpscaleThreshold: Double,
    maximumVideoZoomFactor: Double
  ) {
    self.id = id
    self.role = role
    self.baseDisplayZoom = baseDisplayZoom
    self.videoZoomFactorUpscaleThreshold = videoZoomFactorUpscaleThreshold
    self.maximumVideoZoomFactor = maximumVideoZoomFactor
  }
}

/// Deterministic strategy: enumerate physical devices only, then expose explicit capture modes.
public enum CameraLensCatalog {
  public static func modes(from cameras: [PhysicalCameraDescriptor]) -> [CameraLens] {
    var modes = cameras.flatMap { camera -> [CameraLens] in
      guard camera.baseDisplayZoom.isFinite, camera.baseDisplayZoom > 0 else { return [] }
      var result = [CameraLens(
        id: modeID(deviceID: camera.id, suffix: "base"),
        physicalDeviceID: camera.id,
        role: camera.role,
        captureMode: .physicalCamera,
        deviceZoomFactor: 1,
        displayZoom: zoomLabel(camera.baseDisplayZoom)
      )]

      if camera.role == .wide,
         camera.videoZoomFactorUpscaleThreshold >= 2,
         camera.maximumVideoZoomFactor >= 2 {
        result.append(CameraLens(
          id: modeID(deviceID: camera.id, suffix: "sensor-crop-2x"),
          physicalDeviceID: camera.id,
          role: camera.role,
          captureMode: .mainSensorCrop,
          deviceZoomFactor: 2,
          displayZoom: "2×"
        ))
      }
      return result
    }

    modes.sort { lhs, rhs in
      let leftZoom = zoomValue(lhs.displayZoom)
      let rightZoom = zoomValue(rhs.displayZoom)
      if leftZoom != rightZoom { return leftZoom < rightZoom }
      if lhs.role != rhs.role { return roleOrder(lhs.role) < roleOrder(rhs.role) }
      if lhs.physicalDeviceID != rhs.physicalDeviceID {
        return lhs.physicalDeviceID < rhs.physicalDeviceID
      }
      return lhs.id < rhs.id
    }
    var semanticButtons = Set<String>()
    return modes.filter { mode in
      semanticButtons.insert(mode.displayZoom).inserted
    }
  }

  public static func modeID(deviceID: String, suffix: String) -> String {
    "\(deviceID)::\(suffix)"
  }

  private static func zoomLabel(_ zoom: Double) -> String {
    let rounded = zoom.rounded()
    return abs(zoom - rounded) < 0.08
      ? String(format: "%.0f×", rounded)
      : String(format: "%.1f×", zoom)
  }

  private static func zoomValue(_ label: String) -> Double {
    Double(label.replacingOccurrences(of: "×", with: "")) ?? .greatestFiniteMagnitude
  }

  private static func roleOrder(_ role: LensRole) -> Int {
    switch role {
    case .ultraWide: return 0
    case .wide: return 1
    case .telephoto: return 2
    }
  }
}

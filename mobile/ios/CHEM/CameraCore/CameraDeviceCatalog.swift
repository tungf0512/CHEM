import AVFoundation
import Foundation

public final class CameraDeviceCatalog {
  private let deviceTypes: [AVCaptureDevice.DeviceType] = [
    .builtInWideAngleCamera,
    .builtInUltraWideCamera,
    .builtInTelephotoCamera,
    .builtInDualWideCamera,
    .builtInTripleCamera,
  ]

  public init() {}

  public func availableRearDevices() -> [AVCaptureDevice] {
    AVCaptureDevice.DiscoverySession(
      deviceTypes: deviceTypes,
      mediaType: .video,
      position: .back
    ).devices.sorted { $0.uniqueID < $1.uniqueID }
  }

  public func preferredDevice(from devices: [AVCaptureDevice]) -> AVCaptureDevice? {
    devices.first(where: { $0.deviceType == .builtInWideAngleCamera }) ?? devices.first
  }

  public func lensModels(from devices: [AVCaptureDevice]) -> [CameraLens] {
    let referenceFieldOfView = devices
      .first(where: { $0.deviceType == .builtInWideAngleCamera })?
      .activeFormat.videoFieldOfView

    return devices.map { device in
      let role = lensRole(for: device.deviceType)
      let zoom = displayZoom(for: device, referenceFieldOfView: referenceFieldOfView)
      return CameraLens(id: device.uniqueID, role: role, displayZoom: zoom)
    }
  }

  public func lensRole(for deviceType: AVCaptureDevice.DeviceType) -> LensRole {
    switch deviceType {
    case .builtInUltraWideCamera:
      return .ultraWide
    case .builtInTelephotoCamera:
      return .telephoto
    case .builtInDualWideCamera:
      return .dualWide
    case .builtInTripleCamera:
      return .triple
    default:
      return .wide
    }
  }

  private func displayZoom(
    for device: AVCaptureDevice,
    referenceFieldOfView: Float?
  ) -> String {
    guard let referenceFieldOfView,
          referenceFieldOfView > 0,
          device.activeFormat.videoFieldOfView > 0 else {
      return device.deviceType == .builtInWideAngleCamera ? "1×" : "OPTICAL"
    }

    let base = tan(Double(referenceFieldOfView) * .pi / 360)
    let candidate = tan(Double(device.activeFormat.videoFieldOfView) * .pi / 360)
    guard candidate > 0 else { return "OPTICAL" }
    let zoom = base / candidate
    let roundedZoom = zoom.rounded()
    if abs(zoom - roundedZoom) < 0.08 {
      return String(format: "%.0f×", roundedZoom)
    }
    return String(format: "%.1f×", zoom)
  }
}

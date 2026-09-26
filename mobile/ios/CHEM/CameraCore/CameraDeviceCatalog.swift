import AVFoundation
import Foundation

/// Discovers physical rear sensors only. Virtual dual/triple devices are deliberately not
/// presented as additional lenses because they can duplicate the same user-facing choices.
public final class CameraDeviceCatalog {
  private let deviceTypes: [AVCaptureDevice.DeviceType] = [
    .builtInUltraWideCamera,
    .builtInWideAngleCamera,
    .builtInTelephotoCamera,
  ]

  public init() {}

  public func availableRearDevices() -> [AVCaptureDevice] {
    AVCaptureDevice.DiscoverySession(
      deviceTypes: deviceTypes,
      mediaType: .video,
      position: .back
    ).devices
      .filter { !$0.isVirtualDevice }
      .sorted {
        let leftOrder = roleOrder(lensRole(for: $0.deviceType))
        let rightOrder = roleOrder(lensRole(for: $1.deviceType))
        if leftOrder != rightOrder { return leftOrder < rightOrder }
        return $0.uniqueID < $1.uniqueID
      }
  }

  public func preferredDevice(from devices: [AVCaptureDevice]) -> AVCaptureDevice? {
    devices.first(where: { $0.deviceType == .builtInWideAngleCamera }) ?? devices.first
  }

  public func lensModels(from devices: [AVCaptureDevice]) -> [CameraLens] {
    let referenceDevice = devices.first(where: { $0.deviceType == .builtInWideAngleCamera }) ?? devices.first
    let referenceFieldOfView = referenceDevice?.activeFormat.videoFieldOfView

    let physicalCameras = devices.compactMap { device -> PhysicalCameraDescriptor? in
      guard !device.isVirtualDevice,
            let role = physicalRole(for: device.deviceType) else { return nil }
      let displayZoom = device.uniqueID == referenceDevice?.uniqueID
        ? 1
        : opticalDisplayZoom(for: device, role: role, referenceFieldOfView: referenceFieldOfView)
      return PhysicalCameraDescriptor(
        id: device.uniqueID,
        role: role,
        baseDisplayZoom: displayZoom,
        videoZoomFactorUpscaleThreshold: Double(device.activeFormat.videoZoomFactorUpscaleThreshold),
        maximumVideoZoomFactor: Double(device.activeFormat.videoMaxZoomFactor)
      )
    }

    return CameraLensCatalog.modes(from: physicalCameras)
  }

  public func lensRole(for deviceType: AVCaptureDevice.DeviceType) -> LensRole {
    physicalRole(for: deviceType) ?? .wide
  }

  private func physicalRole(for deviceType: AVCaptureDevice.DeviceType) -> LensRole? {
    switch deviceType {
    case .builtInUltraWideCamera:
      return .ultraWide
    case .builtInWideAngleCamera:
      return .wide
    case .builtInTelephotoCamera:
      return .telephoto
    default:
      return nil
    }
  }

  private func opticalDisplayZoom(
    for device: AVCaptureDevice,
    role: LensRole,
    referenceFieldOfView: Float?
  ) -> Double {
    guard role == .wide else {
      guard let referenceFieldOfView,
            referenceFieldOfView > 0,
            device.activeFormat.videoFieldOfView > 0 else { return 1 }
      return fieldOfViewZoom(
        referenceDegrees: Double(referenceFieldOfView),
        candidateDegrees: Double(device.activeFormat.videoFieldOfView)
      )
    }
    return 1
  }

  private func fieldOfViewZoom(referenceDegrees: Double, candidateDegrees: Double) -> Double {
    let reference = tan(referenceDegrees * .pi / 360)
    let candidate = tan(candidateDegrees * .pi / 360)
    guard candidate.isFinite, candidate > 0, reference.isFinite else { return 0 }
    return reference / candidate
  }

  private func roleOrder(_ role: LensRole) -> Int {
    switch role {
    case .ultraWide: return 0
    case .wide: return 1
    case .telephoto: return 2
    }
  }
}

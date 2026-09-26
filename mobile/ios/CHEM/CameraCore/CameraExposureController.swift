import AVFoundation
import Foundation

public final class CameraExposureController {
  public init() {}

  public func bounds(for device: AVCaptureDevice) -> ExposureBiasRange {
    ExposureBiasRange(
      minimum: device.minExposureTargetBias,
      maximum: device.maxExposureTargetBias
    )
  }

  public func apply(
    ev: Float,
    to device: AVCaptureDevice,
    completion: @escaping (Result<Float, CameraOperationFailure>) -> Void
  ) {
    do {
      try device.lockForConfiguration()
      let clampedEV = bounds(for: device).clamp(ev)
      device.setExposureTargetBias(clampedEV) { appliedEV in
        completion(.success(appliedEV))
      }
      device.unlockForConfiguration()
    } catch {
      completion(.failure(CameraOperationFailure(
        code: .exposureFailed,
        message: error.localizedDescription
      )))
    }
  }
}

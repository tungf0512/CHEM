import Foundation

public enum LensRole: String, Codable, CaseIterable, Sendable {
  case ultraWide
  case wide
  case telephoto
}

public enum CameraCaptureMode: String, Codable, Sendable {
  case physicalCamera
  case mainSensorCrop
}

/// A user-selectable capture mode, not an assertion that each button is a separate sensor.
public struct CameraLens: Codable, Equatable, Sendable {
  public let id: String
  public let physicalDeviceID: String
  public let role: LensRole
  public let captureMode: CameraCaptureMode
  /// Zoom applied to this physical device. Calibration also keys on `physicalDeviceID` and mode.
  public let deviceZoomFactor: Double
  public let displayZoom: String

  public init(
    id: String,
    physicalDeviceID: String,
    role: LensRole,
    captureMode: CameraCaptureMode,
    deviceZoomFactor: Double,
    displayZoom: String
  ) {
    self.id = id
    self.physicalDeviceID = physicalDeviceID
    self.role = role
    self.captureMode = captureMode
    self.deviceZoomFactor = deviceZoomFactor
    self.displayZoom = displayZoom
  }
}

public enum CameraErrorCode: String, Codable, Sendable {
  case permissionDenied
  case sessionConfigurationFailed
  case cameraUnavailable
  case lensSwitchFailed
  case focusFailed
  case exposureFailed
  case captureFailed
  case sourcePersistenceFailed
  case rendererFailed
  case interrupted
}

public struct CameraOperationFailure: Error, Sendable {
  public let code: CameraErrorCode
  public let message: String

  public init(code: CameraErrorCode, message: String) {
    self.code = code
    self.message = message
  }
}

public enum CameraLifecycleState: Hashable, Sendable {
  case idle
  case configuring
  case running
  case interrupted
  case failed
}

/// A serial-queue-owned lifecycle guard; invalid native state transitions are ignored.
public struct CameraStateMachine {
  public private(set) var state: CameraLifecycleState = .idle

  public init() {}

  @discardableResult
  public mutating func transition(to next: CameraLifecycleState) -> Bool {
    guard Self.allowedTransitions[state, default: []].contains(next) else {
      return state == next
    }
    state = next
    return true
  }

  private static let allowedTransitions: [CameraLifecycleState: Set<CameraLifecycleState>] = [
    .idle: [.configuring, .running, .failed],
    .configuring: [.running, .failed, .idle],
    .running: [.configuring, .interrupted, .failed, .idle],
    .interrupted: [.configuring, .running, .failed, .idle],
    .failed: [.configuring, .running, .idle],
  ]
}

public struct ExposureBiasRange: Equatable, Sendable {
  public let minimum: Float
  public let maximum: Float

  public init(minimum: Float, maximum: Float) {
    self.minimum = min(minimum, maximum)
    self.maximum = max(minimum, maximum)
  }

  public func clamp(_ value: Float) -> Float {
    guard value.isFinite else {
      return min(max(0, minimum), maximum)
    }
    return min(max(value, minimum), maximum)
  }
}

public struct CaptureMetadata: Codable, Equatable, Sendable {
  public let id: String
  public let sourceUri: String
  public let thumbnailUri: String?
  public let width: Int
  public let height: Int
  public let capturedAt: String
  public let lensId: String
  public let physicalDeviceId: String
  public let captureMode: CameraCaptureMode
  public let deviceZoomFactor: Double
  public let sourceSafe: Bool
  public let complete: Bool
  public let recoverableError: String?

  public init(
    id: String,
    sourceUri: String,
    thumbnailUri: String?,
    width: Int,
    height: Int,
    capturedAt: String,
    lensId: String,
    physicalDeviceId: String,
    captureMode: CameraCaptureMode,
    deviceZoomFactor: Double,
    sourceSafe: Bool = true,
    complete: Bool = true,
    recoverableError: String? = nil
  ) {
    self.id = id
    self.sourceUri = sourceUri
    self.thumbnailUri = thumbnailUri
    self.width = width
    self.height = height
    self.capturedAt = capturedAt
    self.lensId = lensId
    self.physicalDeviceId = physicalDeviceId
    self.captureMode = captureMode
    self.deviceZoomFactor = deviceZoomFactor
    self.sourceSafe = sourceSafe
    self.complete = complete
    self.recoverableError = recoverableError
  }
}

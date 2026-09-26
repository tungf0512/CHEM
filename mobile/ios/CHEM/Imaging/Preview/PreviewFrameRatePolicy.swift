import Foundation

public enum PreviewThermalLevel: Sendable {
  case nominal
  case fair
  case serious
  case critical
  case unknown
}

/// Caps display scheduling without forcing AVFoundation to shorten exposure duration.
public struct PreviewFrameRatePolicy: Sendable {
  public let preferredFramesPerSecond: Int
  public let stableFallbackFramesPerSecond: Int

  public init(preferredFramesPerSecond: Int = 60, stableFallbackFramesPerSecond: Int = 30) {
    self.preferredFramesPerSecond = max(1, preferredFramesPerSecond)
    self.stableFallbackFramesPerSecond = max(1, stableFallbackFramesPerSecond)
  }

  public func targetFramesPerSecond(
    thermalLevel: PreviewThermalLevel,
    captureDeviceMaximumFramesPerSecond: Int,
    rendererCapacityFramesPerSecond: Int
  ) -> Int {
    let thermalTarget: Int
    switch thermalLevel {
    case .nominal, .fair:
      thermalTarget = preferredFramesPerSecond
    case .serious, .critical, .unknown:
      thermalTarget = stableFallbackFramesPerSecond
    }

    let captureLimit = captureDeviceMaximumFramesPerSecond > 0
      ? captureDeviceMaximumFramesPerSecond
      : stableFallbackFramesPerSecond
    let rendererLimit = rendererCapacityFramesPerSecond > 0
      ? rendererCapacityFramesPerSecond
      : stableFallbackFramesPerSecond
    return max(1, min(thermalTarget, captureLimit, rendererLimit))
  }
}

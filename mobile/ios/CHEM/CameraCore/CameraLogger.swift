import Foundation
import os

#if canImport(Darwin)
import Darwin
#endif

public enum CameraLogger {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.chem.camera",
    category: "camera"
  )

  public static func lifecycle(_ state: CameraLifecycleState, reason: String = "") {
    logger.info("camera_state=\(String(describing: state), privacy: .public) reason=\(reason, privacy: .public)")
  }

  public static func capture(_ captureID: String, stage: String) {
    logger.info("capture=\(captureID, privacy: .public) stage=\(stage, privacy: .public)")
  }
}

/// Local-only validation state. It is intentionally an in-memory snapshot: no
/// camera frames, account data, GPS, or analytics are persisted or transmitted.
@objc(CHEMValidationDiagnostics)
public final class CHEMValidationDiagnostics: NSObject {
  public static let shared = CHEMValidationDiagnostics()

  private let lock = NSLock()
  private var camera: [String: Any] = [:]
  private var capture: [String: Any] = [:]
  private var preview: [String: Any] = [:]
  private var faultInjection = "none"

  @objc public class func isInternalValidationEnabled() -> Bool {
    #if CHEM_INTERNAL_VALIDATION
    return true
    #else
    return false
    #endif
  }

  public class func updateCamera(
    physicalDeviceID: String,
    role: String,
    captureModeID: String,
    displayZoom: String,
    deviceZoomFactor: Double,
    orientation: String
  ) {
    guard isInternalValidationEnabled() else { return }
    shared.lock.lock()
    shared.camera = [
      "physicalDeviceId": physicalDeviceID,
      "role": role,
      "captureModeId": captureModeID,
      "displayZoom": displayZoom,
      "deviceZoomFactor": deviceZoomFactor,
      "orientation": orientation,
    ]
    shared.lock.unlock()
  }

  public class func updateTelemetry(iso: Double, shutterSeconds: Double, exposureEV: Double) {
    guard isInternalValidationEnabled() else { return }
    shared.lock.lock()
    shared.camera["iso"] = iso
    shared.camera["exposureDurationSeconds"] = shutterSeconds
    shared.camera["exposureCompensationEV"] = exposureEV
    shared.lock.unlock()
  }

  public class func updateLifecycle(state: String) {
    guard isInternalValidationEnabled() else { return }
    shared.lock.lock()
    shared.camera["lifecycleState"] = state
    shared.lock.unlock()
  }

  public class func updateCapture(id: String, sourceSafe: Bool, complete: Bool, state: String) {
    guard isInternalValidationEnabled() else { return }
    shared.lock.lock()
    shared.capture = [
      "latestCaptureId": id,
      "sourceSafe": sourceSafe,
      "complete": complete,
      "state": state,
    ]
    shared.lock.unlock()
  }

  public class func updatePreview(
    configuredFPS: Int,
    inputFPS: Int,
    renderedFPS: Int,
    droppedFrames: Int,
    renderMilliseconds: Double,
    width: Int,
    height: Int,
    matrix: String,
    primaries: String,
    transferFunction: String,
    range: String
  ) {
    guard isInternalValidationEnabled() else { return }
    shared.lock.lock()
    shared.preview = [
      "configuredTargetFPS": configuredFPS,
      "observedInputFPS": inputFPS,
      "observedRenderedFPS": renderedFPS,
      "droppedOrStaleFrames": droppedFrames,
      "renderMilliseconds": renderMilliseconds,
      "width": width,
      "height": height,
      "ycbcrMatrix": matrix,
      "colorPrimaries": primaries,
      "transferFunction": transferFunction,
      "range": range,
      "outputBaseline": "neutral-sdr-srgb-v1",
    ]
    shared.lock.unlock()
  }

  public class func setFaultInjection(_ value: String) {
    guard isInternalValidationEnabled() else { return }
    shared.lock.lock()
    shared.faultInjection = value
    shared.lock.unlock()
  }

  @objc public class func reportJSON() -> String {
    shared.lock.lock()
    let report: [String: Any] = [
      "enabled": isInternalValidationEnabled(),
      "build": [
        "semanticVersion": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
        "buildNumber": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown",
        "gitCommitSHA": Bundle.main.object(forInfoDictionaryKey: "CHEMGitCommitSHA") as? String ?? "unknown",
        "rendererBaselineVersion": Bundle.main.object(forInfoDictionaryKey: "CHEMRendererBaselineVersion") as? String ?? "unknown",
      ],
      "device": [
        "hardwareModel": Self.hardwareModelIdentifier(),
        "osVersion": ProcessInfo.processInfo.operatingSystemVersionString,
        "thermalState": Self.thermalStateName(),
      ],
      "camera": camera,
      "capture": capture,
      "preview": preview,
      "faultInjection": faultInjection,
    ] as [String: Any]
    shared.lock.unlock()

    guard JSONSerialization.isValidJSONObject(report),
          let data = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]),
          let json = String(data: data, encoding: .utf8) else {
      return "{\"enabled\":false,\"error\":\"Validation report could not be serialized.\"}"
    }
    return json
  }

  private class func thermalStateName() -> String {
    switch ProcessInfo.processInfo.thermalState {
    case .nominal: return "nominal"
    case .fair: return "fair"
    case .serious: return "serious"
    case .critical: return "critical"
    @unknown default: return "unknown"
    }
  }

  private class func hardwareModelIdentifier() -> String {
    #if canImport(Darwin)
    var size = 0
    guard sysctlbyname("hw.machine", nil, &size, nil, 0) == 0, size > 0 else {
      return "unknown"
    }
    var machine = [CChar](repeating: 0, count: size)
    guard sysctlbyname("hw.machine", &machine, &size, nil, 0) == 0 else {
      return "unknown"
    }
    return String(cString: machine)
    #else
    return "unknown"
    #endif
  }
}

import Foundation
import os

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

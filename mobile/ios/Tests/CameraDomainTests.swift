import Foundation
import XCTest
@testable import CHEMNativeDomain

final class CameraDomainTests: XCTestCase {
  private var mainLens: CameraLens {
    CameraLens(
      id: "main-device::base",
      physicalDeviceID: "main-device",
      role: .wide,
      captureMode: .physicalCamera,
      deviceZoomFactor: 1,
      displayZoom: "1×"
    )
  }

  func testExposureBiasClampsFiniteAndNonFiniteValues() {
    let range = ExposureBiasRange(minimum: -2.0, maximum: 2.0)
    XCTAssertEqual(range.clamp(4.0), 2.0)
    XCTAssertEqual(range.clamp(-4.0), -2.0)
    XCTAssertEqual(range.clamp(.nan), 0.0)
    XCTAssertEqual(range.clamp(.infinity), 2.0)
    XCTAssertEqual(range.clamp(-.infinity), -2.0)
  }

  func testCameraLifecycleRejectsImpossibleTransitionAndAllowsRecovery() {
    var machine = CameraStateMachine()
    XCTAssertFalse(machine.transition(to: .interrupted))
    XCTAssertTrue(machine.transition(to: .configuring))
    XCTAssertTrue(machine.transition(to: .running))
    XCTAssertTrue(machine.transition(to: .interrupted))
    XCTAssertTrue(machine.transition(to: .running))
    XCTAssertTrue(machine.transition(to: .failed))
    XCTAssertTrue(machine.transition(to: .configuring))
    XCTAssertTrue(machine.transition(to: .running))
  }

  func testPhysicalCameraModesSeparateSensorIdentityFromUserZoomChoices() throws {
    let cameras = [
      PhysicalCameraDescriptor(
        id: "main-fusion",
        role: .wide,
        baseDisplayZoom: 1,
        videoZoomFactorUpscaleThreshold: 2,
        maximumVideoZoomFactor: 8
      ),
      PhysicalCameraDescriptor(
        id: "ultra-wide",
        role: .ultraWide,
        baseDisplayZoom: 0.5,
        videoZoomFactorUpscaleThreshold: 1,
        maximumVideoZoomFactor: 8
      ),
      PhysicalCameraDescriptor(
        id: "telephoto",
        role: .telephoto,
        baseDisplayZoom: 3,
        videoZoomFactorUpscaleThreshold: 1,
        maximumVideoZoomFactor: 6
      ),
      // Duplicate semantics from a second physical device do not create duplicate buttons.
      PhysicalCameraDescriptor(
        id: "second-telephoto",
        role: .telephoto,
        baseDisplayZoom: 3,
        videoZoomFactorUpscaleThreshold: 1,
        maximumVideoZoomFactor: 6
      ),
    ]
    let modes = CameraLensCatalog.modes(from: cameras)

    XCTAssertEqual(modes.map(\.displayZoom), ["0.5×", "1×", "2×", "3×"])
    XCTAssertEqual(modes, CameraLensCatalog.modes(from: Array(cameras.reversed())))
    XCTAssertEqual(Set(modes.map(\.displayZoom)).count, modes.count)
    let mainModes = modes.filter { $0.physicalDeviceID == "main-fusion" }
    XCTAssertEqual(mainModes.map(\.captureMode), [.physicalCamera, .mainSensorCrop])
    XCTAssertEqual(mainModes.map(\.deviceZoomFactor), [1, 2])
    XCTAssertEqual(mainModes.map(\.role), [.wide, .wide])
  }

  func testLensCatalogDoesNotInventCropModeBeyondNativeUpscaleThreshold() {
    let modes = CameraLensCatalog.modes(from: [
      PhysicalCameraDescriptor(
        id: "main",
        role: .wide,
        baseDisplayZoom: 1,
        videoZoomFactorUpscaleThreshold: 1.7,
        maximumVideoZoomFactor: 8
      ),
    ])
    XCTAssertEqual(modes.count, 1)
    XCTAssertEqual(modes[0].captureMode, .physicalCamera)
  }

  func testCaptureModeMetadataRoundTripsAsJSON() throws {
    let cropMode = CameraLens(
      id: "main-device::sensor-crop-2x",
      physicalDeviceID: "main-device",
      role: .wide,
      captureMode: .mainSensorCrop,
      deviceZoomFactor: 2,
      displayZoom: "2×"
    )
    XCTAssertEqual(
      try JSONDecoder().decode(CameraLens.self, from: JSONEncoder().encode(cropMode)),
      cropMode
    )

    let metadata = CaptureMetadata(
      id: UUID().uuidString,
      sourceUri: "file:///CHEM/Captures/capture/source.jpg",
      thumbnailUri: nil,
      width: 4032,
      height: 3024,
      capturedAt: "2026-09-26T10:00:00Z",
      lensId: cropMode.id,
      physicalDeviceId: cropMode.physicalDeviceID,
      captureMode: cropMode.captureMode,
      deviceZoomFactor: cropMode.deviceZoomFactor,
      sourceSafe: true,
      complete: false,
      recoverableError: "Thumbnail could not be generated."
    )
    XCTAssertEqual(try JSONDecoder().decode(CaptureMetadata.self, from: JSONEncoder().encode(metadata)), metadata)
  }

  func testValidationReportIsSmallMetadataOnlyJSON() throws {
    let data = try XCTUnwrap(CHEMValidationDiagnostics.reportJSON().data(using: .utf8))
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    XCTAssertNotNil(object["build"] as? [String: Any])
    XCTAssertNotNil(object["device"] as? [String: Any])
    XCTAssertNil(object["pixels"])
    XCTAssertNil(object["gps"])
    XCTAssertNil(object["account"])
  }

  func testCaptureStoreWritesSourceFirstInUUIDDirectoryAndRestoresCompleteRecord() throws {
    let root = makeTemporaryCaptureRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let store = CaptureStore(rootURL: root)
    let captureID = UUID().uuidString

    let metadata = try store.persist(
      sourceData: Data("source-pixels".utf8),
      captureID: captureID,
      width: 4032,
      height: 3024,
      capturedAt: "2026-09-26T10:00:00Z",
      lens: mainLens,
      prepareThumbnail: { sourceURL in
        XCTAssertEqual(try Data(contentsOf: sourceURL), Data("source-pixels".utf8))
        return Data("thumbnail".utf8)
      }
    )

    let sourceURL = try CapturePathGenerator.sourceURL(rootURL: root, captureID: captureID)
    let thumbnailURL = try CapturePathGenerator.thumbnailURL(rootURL: root, captureID: captureID)
    let metadataURL = try CapturePathGenerator.metadataURL(rootURL: root, captureID: captureID)
    XCTAssertEqual(sourceURL.deletingLastPathComponent().lastPathComponent, captureID)
    XCTAssertEqual(try Data(contentsOf: sourceURL), Data("source-pixels".utf8))
    XCTAssertEqual(try Data(contentsOf: thumbnailURL), Data("thumbnail".utf8))
    XCTAssertTrue(FileManager.default.fileExists(atPath: metadataURL.path))
    XCTAssertTrue(metadata.sourceSafe)
    XCTAssertTrue(metadata.complete)
    XCTAssertNotNil(metadata.thumbnailUri)
    XCTAssertEqual(store.recoverLatestRecord(), metadata)
    XCTAssertEqual(
      try JSONDecoder().decode(CaptureMetadata.self, from: Data(store.latestMetadataJSONValue.utf8)),
      metadata
    )
  }

  func testReusingCaptureIDNeverOverwritesOrDeletesAnExistingSafeSource() throws {
    let root = makeTemporaryCaptureRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let store = CaptureStore(rootURL: root)
    let captureID = UUID().uuidString
    let originalSource = Data("original-safe-source".utf8)
    _ = try store.persist(
      sourceData: originalSource,
      captureID: captureID,
      width: 100,
      height: 100,
      capturedAt: "2026-09-26T10:00:00Z",
      lens: mainLens,
      prepareThumbnail: { _ in Data("thumbnail".utf8) }
    )

    XCTAssertThrowsError(try store.persist(
      sourceData: Data("replacement-must-not-win".utf8),
      captureID: captureID,
      width: 200,
      height: 200,
      capturedAt: "2026-09-26T10:01:00Z",
      lens: mainLens,
      prepareThumbnail: { _ in Data("replacement-thumbnail".utf8) }
    )) { error in
      guard let storeError = error as? CaptureStoreError,
            case .captureAlreadyExists = storeError else {
        return XCTFail("Expected captureAlreadyExists, got \(error)")
      }
    }

    let sourceURL = try CapturePathGenerator.sourceURL(rootURL: root, captureID: captureID)
    XCTAssertEqual(try Data(contentsOf: sourceURL), originalSource)
    XCTAssertEqual(store.recoverLatestRecord()?.id, captureID)
  }

  func testThumbnailFailureKeepsSourceAndReturnsRecoverableCaptureRecord() throws {
    let root = makeTemporaryCaptureRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let store = CaptureStore(rootURL: root)
    let captureID = UUID().uuidString

    let metadata = try store.persist(
      sourceData: Data("source-survives-thumbnail-error".utf8),
      captureID: captureID,
      width: 3000,
      height: 2000,
      capturedAt: "2026-09-26T10:01:00Z",
      lens: mainLens,
      prepareThumbnail: { _ in throw CaptureStoreError.thumbnailPreparationFailed("injected thumbnail failure") }
    )

    let sourceURL = try CapturePathGenerator.sourceURL(rootURL: root, captureID: captureID)
    XCTAssertEqual(try Data(contentsOf: sourceURL), Data("source-survives-thumbnail-error".utf8))
    XCTAssertTrue(metadata.sourceSafe)
    XCTAssertFalse(metadata.complete)
    XCTAssertNil(metadata.thumbnailUri)
    XCTAssertTrue(metadata.recoverableError?.contains("injected thumbnail failure") == true)
    XCTAssertEqual(store.recoverLatestRecord()?.sourceUri, metadata.sourceUri)
    XCTAssertFalse(store.recoverLatestRecord()?.complete ?? true)
  }

  func testMetadataWriteFailureAfterSourceSafeRetainsSourceAndRecoveryRecord() throws {
    let root = makeTemporaryCaptureRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let store = CaptureStore(rootURL: root)
    store.debugFailurePoint = .metadataWrite
    let captureID = UUID().uuidString

    let metadata = try store.persist(
      sourceData: Data("source-survives-metadata-error".utf8),
      captureID: captureID,
      width: 2000,
      height: 1000,
      capturedAt: "2026-09-26T10:02:00Z",
      lens: mainLens,
      prepareThumbnail: { _ in Data("thumbnail".utf8) }
    )

    let sourceURL = try CapturePathGenerator.sourceURL(rootURL: root, captureID: captureID)
    let metadataURL = try CapturePathGenerator.metadataURL(rootURL: root, captureID: captureID)
    XCTAssertEqual(try Data(contentsOf: sourceURL), Data("source-survives-metadata-error".utf8))
    XCTAssertTrue(metadata.sourceSafe)
    XCTAssertFalse(metadata.complete)
    XCTAssertNotNil(metadata.recoverableError)
    XCTAssertFalse(FileManager.default.fileExists(atPath: metadataURL.path))

    let recovered = store.recoverLatestRecord()
    XCTAssertEqual(recovered?.id, captureID)
    XCTAssertTrue(recovered?.sourceSafe == true)
    XCTAssertFalse(recovered?.complete ?? true)
  }

  func testLatestPointerFailureKeepsCompleteRecordAndQueryRepairsIndex() throws {
    let root = makeTemporaryCaptureRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let store = CaptureStore(rootURL: root)
    store.debugFailurePoint = .latestPointerWrite
    let captureID = UUID().uuidString

    let record = try store.persist(
      sourceData: Data("source-survives-index-error".utf8),
      captureID: captureID,
      width: 2048,
      height: 1536,
      capturedAt: "2026-09-26T10:03:00Z",
      lens: mainLens,
      prepareThumbnail: { _ in Data("thumbnail".utf8) }
    )

    let latestURL = root.appendingPathComponent("latest.json")
    let sourceURL = try CapturePathGenerator.sourceURL(rootURL: root, captureID: captureID)
    XCTAssertTrue(record.sourceSafe)
    XCTAssertTrue(record.complete)
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
    XCTAssertFalse(FileManager.default.fileExists(atPath: latestURL.path))
    XCTAssertEqual(store.recoverLatestRecord(), record)
    XCTAssertTrue(FileManager.default.fileExists(atPath: latestURL.path))
  }

  func testRecoveryMarksMissingThumbnailRecoverableWithoutDeletingSource() throws {
    let root = makeTemporaryCaptureRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let store = CaptureStore(rootURL: root)
    let captureID = UUID().uuidString
    let record = try store.persist(
      sourceData: Data("source-with-lost-derived-thumbnail".utf8),
      captureID: captureID,
      width: 900,
      height: 600,
      capturedAt: "2026-09-26T10:04:00Z",
      lens: mainLens,
      prepareThumbnail: { _ in Data("thumbnail".utf8) }
    )
    let sourceURL = try CapturePathGenerator.sourceURL(rootURL: root, captureID: captureID)
    let thumbnailURL = try CapturePathGenerator.thumbnailURL(rootURL: root, captureID: captureID)
    try FileManager.default.removeItem(at: thumbnailURL)

    let recovered = store.recoverLatestRecord()
    XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
    XCTAssertEqual(recovered?.id, record.id)
    XCTAssertTrue(recovered?.sourceSafe == true)
    XCTAssertFalse(recovered?.complete ?? true)
    XCTAssertNil(recovered?.thumbnailUri)
    XCTAssertNotNil(recovered?.recoverableError)
  }

  func testMissingSourceReferencedByMetadataIsNeverReportedAsCapture() throws {
    let root = makeTemporaryCaptureRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let store = CaptureStore(rootURL: root)
    let captureID = UUID().uuidString
    _ = try store.persist(
      sourceData: Data("source-removed-after-crash-test".utf8),
      captureID: captureID,
      width: 100,
      height: 100,
      capturedAt: "2026-09-26T10:05:00Z",
      lens: mainLens,
      prepareThumbnail: { _ in Data("thumbnail".utf8) }
    )
    let sourceURL = try CapturePathGenerator.sourceURL(rootURL: root, captureID: captureID)
    try FileManager.default.removeItem(at: sourceURL)

    XCTAssertNil(store.recoverLatestRecord())
    XCTAssertEqual(store.latestMetadataJSONValue, "")
  }

  func testEmptySourceAndPathTraversalAreRejectedBeforeWriting() throws {
    let root = makeTemporaryCaptureRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let store = CaptureStore(rootURL: root)

    XCTAssertThrowsError(try store.persist(
      sourceData: Data(),
      captureID: UUID().uuidString,
      width: 10,
      height: 10,
      capturedAt: "2026-09-26T10:06:00Z",
      lens: mainLens,
      prepareThumbnail: { _ in Data() }
    )) { error in
      guard let storeError = error as? CaptureStoreError,
            case .emptySource = storeError else {
        return XCTFail("Expected emptySource, got \(error)")
      }
    }
    XCTAssertFalse(FileManager.default.fileExists(atPath: root.path))
    XCTAssertThrowsError(try CapturePathGenerator.sourceURL(rootURL: root, captureID: "../../outside"))
  }

  func testPreviewAndFocusTransformsAreExactInversesAcrossOrientationsAndCrops() {
    let viewPoints = [
      NormalizedCameraPoint(x: 0.5, y: 0.5),
      NormalizedCameraPoint(x: 0.05, y: 0.05),
      NormalizedCameraPoint(x: 0.95, y: 0.05),
      NormalizedCameraPoint(x: 0.05, y: 0.95),
      NormalizedCameraPoint(x: 0.95, y: 0.95),
    ]

    for orientation in CameraOrientation.allCases {
      let isPortrait = orientation == .portrait || orientation == .portraitUpsideDown
      let geometry = CameraPreviewGeometry(
        width: isPortrait ? 390 : 844,
        height: isPortrait ? 844 : 390,
        orientation: orientation
      )
      for point in viewPoints {
        let sensor = CameraCoordinateMapper.sensorPoint(
          fromDisplayPoint: point,
          geometry: geometry,
          sensorWidth: 4032,
          sensorHeight: 3024
        )
        let restored = CameraCoordinateMapper.displayPoint(
          fromSensorPoint: sensor,
          geometry: geometry,
          sensorWidth: 4032,
          sensorHeight: 3024
        )
        XCTAssertEqual(restored.x, point.x, accuracy: 0.000_000_01, "orientation=\(orientation) x=\(point.x)")
        XCTAssertEqual(restored.y, point.y, accuracy: 0.000_000_01, "orientation=\(orientation) y=\(point.y)")
      }
    }

    // Oriented portrait source into a wide viewport exercises vertical aspect-fill cropping.
    let landscapeGeometry = CameraPreviewGeometry(width: 1200, height: 500, orientation: .landscapeRight)
    let wideViewPoint = NormalizedCameraPoint(x: 0.9, y: 0.1)
    let tallSensorPoint = CameraCoordinateMapper.sensorPoint(
      fromDisplayPoint: wideViewPoint,
      geometry: landscapeGeometry,
      sensorWidth: 3024,
      sensorHeight: 4032
    )
    let restoredWidePoint = CameraCoordinateMapper.displayPoint(
      fromSensorPoint: tallSensorPoint,
      geometry: landscapeGeometry,
      sensorWidth: 3024,
      sensorHeight: 4032
    )
    XCTAssertEqual(restoredWidePoint.x, wideViewPoint.x, accuracy: 0.000_000_01)
    XCTAssertEqual(restoredWidePoint.y, wideViewPoint.y, accuracy: 0.000_000_01)
  }

  func testPreviewRatePolicyAccountsForThermalCaptureAndRendererLimits() {
    let policy = PreviewFrameRatePolicy()
    XCTAssertEqual(policy.targetFramesPerSecond(
      thermalLevel: .nominal,
      captureDeviceMaximumFramesPerSecond: 120,
      rendererCapacityFramesPerSecond: 60
    ), 60)
    XCTAssertEqual(policy.targetFramesPerSecond(
      thermalLevel: .nominal,
      captureDeviceMaximumFramesPerSecond: 30,
      rendererCapacityFramesPerSecond: 60
    ), 30)
    XCTAssertEqual(policy.targetFramesPerSecond(
      thermalLevel: .serious,
      captureDeviceMaximumFramesPerSecond: 60,
      rendererCapacityFramesPerSecond: 60
    ), 30)
    XCTAssertEqual(policy.targetFramesPerSecond(
      thermalLevel: .nominal,
      captureDeviceMaximumFramesPerSecond: 60,
      rendererCapacityFramesPerSecond: 24
    ), 24)
  }

  private func makeTemporaryCaptureRoot() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("CHEM-tests-\(UUID().uuidString)", isDirectory: true)
  }
}

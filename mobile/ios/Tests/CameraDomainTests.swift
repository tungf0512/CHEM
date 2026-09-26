import Foundation
import XCTest
@testable import CHEMNativeDomain

final class CameraDomainTests: XCTestCase {
  func testExposureBiasIsClampedToDeviceRange() {
    let range = ExposureBiasRange(minimum: -2.0, maximum: 2.0)
    XCTAssertEqual(range.clamp(4.0), 2.0)
    XCTAssertEqual(range.clamp(-4.0), -2.0)
    XCTAssertEqual(range.clamp(.nan), 0.0)
  }

  func testCameraLifecycleRejectsImpossibleTransition() {
    var machine = CameraStateMachine()
    XCTAssertFalse(machine.transition(to: .interrupted))
    XCTAssertTrue(machine.transition(to: .configuring))
    XCTAssertTrue(machine.transition(to: .running))
    XCTAssertTrue(machine.transition(to: .configuring))
    XCTAssertTrue(machine.transition(to: .running))
    XCTAssertEqual(machine.state, .running)
    XCTAssertTrue(machine.transition(to: .interrupted))
    XCTAssertTrue(machine.transition(to: .running))
  }

  func testLensRolesAndCaptureMetadataRoundTrip() throws {
    let lens = CameraLens(id: "rear-wide", role: .wide, displayZoom: "1×")
    XCTAssertEqual(try JSONDecoder().decode(CameraLens.self, from: JSONEncoder().encode(lens)), lens)

    let metadata = CaptureMetadata(
      id: "capture-abc",
      sourceUri: "file:///CHEM/Captures/capture-abc.jpg",
      thumbnailUri: "file:///CHEM/Captures/capture-abc-thumb.jpg",
      width: 4032,
      height: 3024,
      capturedAt: "2026-09-26T10:00:00Z",
      lensId: lens.id
    )
    XCTAssertEqual(try JSONDecoder().decode(CaptureMetadata.self, from: JSONEncoder().encode(metadata)), metadata)
  }

  func testCaptureStoreAtomicallyPersistsAndRestoresSourceAndThumbnail() throws {
    let rootURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("CHEM-tests-\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }
    let store = CaptureStore(rootURL: rootURL)

    let metadata = try store.persist(
      sourceData: Data("photo-source".utf8),
      captureID: "capture-abc",
      width: 4032,
      height: 3024,
      capturedAt: "2026-09-26T10:00:00Z",
      lensID: "rear-wide",
      prepareThumbnail: { sourceURL in
        XCTAssertEqual(try Data(contentsOf: sourceURL), Data("photo-source".utf8))
        return Data("small-thumbnail".utf8)
      }
    )

    XCTAssertEqual(try Data(contentsOf: URL(string: metadata.sourceUri)!), Data("photo-source".utf8))
    XCTAssertEqual(try Data(contentsOf: URL(string: metadata.thumbnailUri!)!), Data("small-thumbnail".utf8))
    XCTAssertEqual(try JSONDecoder().decode(CaptureMetadata.self, from: Data(store.latestMetadataJSONValue.utf8)), metadata)
  }

  func testCapturePathsUseDedicatedSourceAndThumbnailNames() {
    let rootURL = URL(fileURLWithPath: "/captures", isDirectory: true)
    XCTAssertEqual(CapturePathGenerator.sourceURL(rootURL: rootURL, captureID: "id-1").lastPathComponent, "id-1.jpg")
    XCTAssertEqual(CapturePathGenerator.thumbnailURL(rootURL: rootURL, captureID: "id-1").lastPathComponent, "id-1-thumb.jpg")
    XCTAssertEqual(CapturePathGenerator.metadataURL(rootURL: rootURL, captureID: "id-1").lastPathComponent, "id-1.json")
  }
}

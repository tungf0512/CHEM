import Foundation
import ImageIO

public enum CaptureStoreError: Error, LocalizedError {
  case applicationSupportUnavailable
  case emptySource
  case invalidCaptureID
  case captureAlreadyExists
  case sourceValidationFailed
  case emptyThumbnail
  case thumbnailPreparationFailed(String)
  case writeFailed(String)

  public var errorDescription: String? {
    switch self {
    case .applicationSupportUnavailable:
      return "The application support directory is unavailable."
    case .emptySource:
      return "The captured source image is empty."
    case .invalidCaptureID:
      return "The capture identifier is invalid."
    case .captureAlreadyExists:
      return "The capture identifier already belongs to a saved source."
    case .sourceValidationFailed:
      return "The captured source could not be validated after writing."
    case .emptyThumbnail:
      return "The captured preview thumbnail is empty."
    case .thumbnailPreparationFailed(let reason):
      return reason
    case .writeFailed(let reason):
      return "The captured source could not be written: \(reason)"
    }
  }
}

#if DEBUG
public enum CaptureStoreFailurePoint: Equatable {
  case thumbnailGeneration
  case metadataWrite
  case latestPointerWrite
}
#endif

public enum CapturePathGenerator {
  public static func captureDirectory(rootURL: URL, captureID: String) throws -> URL {
    guard let uuid = UUID(uuidString: captureID),
          uuid.uuidString.caseInsensitiveCompare(captureID) == .orderedSame else {
      throw CaptureStoreError.invalidCaptureID
    }
    let root = rootURL.standardizedFileURL
    let directory = root.appendingPathComponent(uuid.uuidString, isDirectory: true).standardizedFileURL
    guard directory.deletingLastPathComponent().path == root.path else {
      throw CaptureStoreError.invalidCaptureID
    }
    return directory
  }

  public static func sourceURL(rootURL: URL, captureID: String) throws -> URL {
    try captureDirectory(rootURL: rootURL, captureID: captureID)
      .appendingPathComponent("source.jpg", isDirectory: false)
  }

  public static func thumbnailURL(rootURL: URL, captureID: String) throws -> URL {
    try captureDirectory(rootURL: rootURL, captureID: captureID)
      .appendingPathComponent("thumbnail.jpg", isDirectory: false)
  }

  public static func metadataURL(rootURL: URL, captureID: String) throws -> URL {
    try captureDirectory(rootURL: rootURL, captureID: captureID)
      .appendingPathComponent("metadata.json", isDirectory: false)
  }
}

public protocol CaptureStoring {
  func persist(
    sourceData: Data,
    captureID: String,
    width: Int,
    height: Int,
    capturedAt: String,
    lens: CameraLens,
    prepareThumbnail: (URL) throws -> Data
  ) throws -> CaptureMetadata
}

/// Source-first persistence. After the source is validated, derivative/index errors are
/// represented as recoverable metadata and never thrown in a way that can erase the source.
@objc(CHEMCaptureStore)
public final class CaptureStore: NSObject, CaptureStoring {
  private static let sharedStore = CaptureStore(
    rootURL: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
      .first?.appendingPathComponent("CHEM/Captures", isDirectory: true)
  )

  private let rootURL: URL?
  private let queue = DispatchQueue(label: "chem.capture-store", qos: .utility)
  private let fileManager: FileManager
  #if DEBUG
  public var debugFailurePoint: CaptureStoreFailurePoint?
  #endif

  public init(rootURL: URL?, fileManager: FileManager = .default) {
    self.rootURL = rootURL?.standardizedFileURL
    self.fileManager = fileManager
    super.init()
  }

  @objc public class func latestMetadataJSON() -> String {
    sharedStore.latestMetadataJSONValue
  }

  /// Queries by validating/recovering on-disk records; `latest.json` is only an index hint.
  public var latestMetadataJSONValue: String {
    queue.sync {
      guard let record = recoverLatestRecordLocked(),
            let data = try? Self.encode(record),
            let json = String(data: data, encoding: .utf8) else { return "" }
      return json
    }
  }

  @discardableResult
  public func recoverLatestRecord() -> CaptureMetadata? {
    queue.sync { recoverLatestRecordLocked() }
  }

  public func persist(
    sourceData: Data,
    captureID: String,
    width: Int,
    height: Int,
    capturedAt: String,
    lens: CameraLens,
    prepareThumbnail: (URL) throws -> Data
  ) throws -> CaptureMetadata {
    try queue.sync {
      guard !sourceData.isEmpty else { throw CaptureStoreError.emptySource }
      guard let rootURL else { throw CaptureStoreError.applicationSupportUnavailable }
      let directory = try CapturePathGenerator.captureDirectory(rootURL: rootURL, captureID: captureID)
      let sourceURL = try CapturePathGenerator.sourceURL(rootURL: rootURL, captureID: captureID)
      let thumbnailURL = try CapturePathGenerator.thumbnailURL(rootURL: rootURL, captureID: captureID)
      let metadataURL = try CapturePathGenerator.metadataURL(rootURL: rootURL, captureID: captureID)
      let latestURL = rootURL.appendingPathComponent("latest.json", isDirectory: false)

      var captureDirectoryCreated = false
      do {
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        do {
          // Creating the per-capture directory without intermediate creation is the
          // exclusive transaction claim. Only its owner may write/remove its source.
          try fileManager.createDirectory(at: directory, withIntermediateDirectories: false)
          captureDirectoryCreated = true
        } catch {
          if fileManager.fileExists(atPath: directory.path) {
            throw CaptureStoreError.captureAlreadyExists
          }
          throw error
        }
        CameraLogger.capture(captureID, stage: "source_write_started")
        try sourceData.write(to: sourceURL, options: .atomic)
        let persistedSource = try Data(contentsOf: sourceURL, options: [.mappedIfSafe])
        guard !persistedSource.isEmpty, persistedSource.count == sourceData.count else {
          throw CaptureStoreError.sourceValidationFailed
        }
      } catch {
        // Cleanup is limited to failures before the source-safe point.
        // An ID collision never acquires the directory claim, so it cannot erase a
        // pre-existing source. Once the claim is held, pre-safe cleanup owns the folder.
        if captureDirectoryCreated { try? fileManager.removeItem(at: directory) }
        if let storeError = error as? CaptureStoreError { throw storeError }
        throw CaptureStoreError.writeFailed(error.localizedDescription)
      }

      CameraLogger.capture(captureID, stage: "source_safe")
      let safeRecord = CaptureMetadata(
        id: captureID,
        sourceUri: sourceURL.absoluteString,
        thumbnailUri: nil,
        width: max(0, width),
        height: max(0, height),
        capturedAt: capturedAt,
        lensId: lens.id,
        physicalDeviceId: lens.physicalDeviceID,
        captureMode: lens.captureMode,
        deviceZoomFactor: lens.deviceZoomFactor,
        sourceSafe: true,
        complete: false,
        recoverableError: "Capture source is safe; derived metadata is pending."
      )

      var thumbnailUri: String?
      var derivedError: String?
      do {
        #if DEBUG
        if debugFailurePoint == .thumbnailGeneration {
          throw CaptureStoreError.thumbnailPreparationFailed("Debug injection: thumbnail generation failed.")
        }
        #endif
        let thumbnailData = try prepareThumbnail(sourceURL)
        guard !thumbnailData.isEmpty else { throw CaptureStoreError.emptyThumbnail }
        try thumbnailData.write(to: thumbnailURL, options: .atomic)
        let persistedThumbnail = try Data(contentsOf: thumbnailURL, options: [.mappedIfSafe])
        guard !persistedThumbnail.isEmpty else { throw CaptureStoreError.emptyThumbnail }
        thumbnailUri = thumbnailURL.absoluteString
      } catch {
        derivedError = error.localizedDescription
        try? fileManager.removeItem(at: thumbnailURL)
      }

      let incompleteRecord = CaptureMetadata(
        id: safeRecord.id,
        sourceUri: safeRecord.sourceUri,
        thumbnailUri: thumbnailUri,
        width: safeRecord.width,
        height: safeRecord.height,
        capturedAt: safeRecord.capturedAt,
        lensId: safeRecord.lensId,
        physicalDeviceId: safeRecord.physicalDeviceId,
        captureMode: safeRecord.captureMode,
        deviceZoomFactor: safeRecord.deviceZoomFactor,
        sourceSafe: true,
        complete: false,
        recoverableError: derivedError ?? "Capture metadata is being finalized."
      )

      var metadataPersisted = false
      do {
        #if DEBUG
        if debugFailurePoint == .metadataWrite {
          throw CaptureStoreError.writeFailed("Debug injection: metadata write failed.")
        }
        #endif
        try Self.encode(incompleteRecord).write(to: metadataURL, options: .atomic)
        metadataPersisted = true
      } catch {
        derivedError = derivedError ?? error.localizedDescription
      }

      var record = incompleteRecord
      if thumbnailUri != nil, metadataPersisted {
        let completeRecord = CaptureMetadata(
          id: incompleteRecord.id,
          sourceUri: incompleteRecord.sourceUri,
          thumbnailUri: incompleteRecord.thumbnailUri,
          width: incompleteRecord.width,
          height: incompleteRecord.height,
          capturedAt: incompleteRecord.capturedAt,
          lensId: incompleteRecord.lensId,
          physicalDeviceId: incompleteRecord.physicalDeviceId,
          captureMode: incompleteRecord.captureMode,
          deviceZoomFactor: incompleteRecord.deviceZoomFactor,
          sourceSafe: true,
          complete: true,
          recoverableError: nil
        )
        do {
          try Self.encode(completeRecord).write(to: metadataURL, options: .atomic)
          record = completeRecord
        } catch {
          derivedError = error.localizedDescription
          record = Self.withRecoverableError(incompleteRecord, error: derivedError)
          // The first incomplete sidecar remains available; source and thumbnail remain safe.
        }
      } else if let derivedError {
        record = Self.withRecoverableError(incompleteRecord, error: derivedError)
        if metadataPersisted {
          try? Self.encode(record).write(to: metadataURL, options: .atomic)
        }
      }

      do {
        #if DEBUG
        if debugFailurePoint == .latestPointerWrite {
          throw CaptureStoreError.writeFailed("Debug injection: latest pointer write failed.")
        }
        #endif
        try Self.encode(record).write(to: latestURL, options: .atomic)
      } catch {
        // The pointer is an optimization. Recovery enumerates source-safe capture folders.
        CameraLogger.capture(captureID, stage: "latest_pointer_recoverable_failure")
      }
      CameraLogger.capture(captureID, stage: record.complete ? "capture_complete" : "capture_recoverable")
      return record
    }
  }

  private func recoverLatestRecordLocked() -> CaptureMetadata? {
    guard let rootURL,
          let directories = try? fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
          ) else { return nil }

    let records = directories.compactMap(recoverRecord(in:))
    guard let latest = records.max(by: { recordDate($0) < recordDate($1) }) else { return nil }

    let pointer = rootURL.appendingPathComponent("latest.json", isDirectory: false)
    if let encoded = try? Self.encode(latest) {
      do {
        try encoded.write(to: pointer, options: .atomic)
      } catch {
        // Keep the source-safe capture discoverable even when the index cannot be repaired.
      }
    }
    return latest
  }

  private func recoverRecord(in directory: URL) -> CaptureMetadata? {
    guard let rootURL,
          (try? directory.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
          let captureID = UUID(uuidString: directory.lastPathComponent)?.uuidString,
          captureID.caseInsensitiveCompare(directory.lastPathComponent) == .orderedSame,
          let expectedDirectory = try? CapturePathGenerator.captureDirectory(rootURL: rootURL, captureID: captureID),
          expectedDirectory.standardizedFileURL == directory.standardizedFileURL,
          let sourceURL = try? CapturePathGenerator.sourceURL(rootURL: rootURL, captureID: captureID),
          let sourceData = try? Data(contentsOf: sourceURL, options: [.mappedIfSafe]),
          !sourceData.isEmpty,
          let attributes = try? fileManager.attributesOfItem(atPath: sourceURL.path),
          let sourceSize = (attributes[.size] as? NSNumber)?.intValue,
          sourceSize > 0 else { return nil }

    let metadataURL = try? CapturePathGenerator.metadataURL(rootURL: rootURL, captureID: captureID)
    let thumbnailURL = try? CapturePathGenerator.thumbnailURL(rootURL: rootURL, captureID: captureID)
    let validMetadata = metadataURL.flatMap { url -> CaptureMetadata? in
      guard let data = try? Data(contentsOf: url),
            let metadata = try? JSONDecoder().decode(CaptureMetadata.self, from: data),
            metadata.id.caseInsensitiveCompare(captureID) == .orderedSame,
            metadata.sourceSafe,
            metadata.sourceUri == sourceURL.absoluteString else { return nil }
      return metadata
    }

    let hasThumbnailFile = thumbnailURL.flatMap { try? Data(contentsOf: $0, options: [.mappedIfSafe]) }
      .map { !$0.isEmpty } ?? false
    let thumbnailUri = hasThumbnailFile ? thumbnailURL?.absoluteString : nil
    if let validMetadata {
      let thumbnailMatchesRecord = validMetadata.thumbnailUri == thumbnailURL?.absoluteString
      let complete = validMetadata.complete && hasThumbnailFile && thumbnailMatchesRecord
      let recoverableError = complete
        ? validMetadata.recoverableError
        : (hasThumbnailFile ? "Capture record needs metadata recovery." : "Thumbnail is missing; source is safe and recoverable.")
      return CaptureMetadata(
        id: validMetadata.id,
        sourceUri: sourceURL.absoluteString,
        thumbnailUri: thumbnailUri,
        width: validMetadata.width,
        height: validMetadata.height,
        capturedAt: validMetadata.capturedAt,
        lensId: validMetadata.lensId,
        physicalDeviceId: validMetadata.physicalDeviceId,
        captureMode: validMetadata.captureMode,
        deviceZoomFactor: validMetadata.deviceZoomFactor,
        sourceSafe: true,
        complete: complete,
        recoverableError: recoverableError
      )
    }

    let imageDimensions = CaptureSourceInspector.dimensions(at: sourceURL)
    let modifiedAt = (attributes[.modificationDate] as? Date) ?? Date(timeIntervalSince1970: 0)
    let reconstructed = CaptureMetadata(
      id: captureID,
      sourceUri: sourceURL.absoluteString,
      thumbnailUri: thumbnailUri,
      width: imageDimensions?.width ?? 0,
      height: imageDimensions?.height ?? 0,
      capturedAt: ISO8601DateFormatter().string(from: modifiedAt),
      lensId: "",
      physicalDeviceId: "",
      captureMode: .physicalCamera,
      deviceZoomFactor: 1,
      sourceSafe: true,
      complete: false,
      recoverableError: "Capture metadata was missing or invalid and has been reconstructed from the safe source."
    )
    if let metadataURL, let encoded = try? Self.encode(reconstructed) {
      try? encoded.write(to: metadataURL, options: .atomic)
    }
    return reconstructed
  }

  private func recordDate(_ record: CaptureMetadata) -> String {
    record.capturedAt.isEmpty ? record.id : record.capturedAt
  }

  private static func encode(_ metadata: CaptureMetadata) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return try encoder.encode(metadata)
  }

  private static func withRecoverableError(
    _ metadata: CaptureMetadata,
    error: String
  ) -> CaptureMetadata {
    CaptureMetadata(
      id: metadata.id,
      sourceUri: metadata.sourceUri,
      thumbnailUri: metadata.thumbnailUri,
      width: metadata.width,
      height: metadata.height,
      capturedAt: metadata.capturedAt,
      lensId: metadata.lensId,
      physicalDeviceId: metadata.physicalDeviceId,
      captureMode: metadata.captureMode,
      deviceZoomFactor: metadata.deviceZoomFactor,
      sourceSafe: metadata.sourceSafe,
      complete: false,
      recoverableError: error
    )
  }
}

public enum CaptureSourceInspector {
  public static func dimensions(at url: URL) -> (width: Int, height: Int)? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
          let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
          width > 0, height > 0 else { return nil }
    return (width, height)
  }
}

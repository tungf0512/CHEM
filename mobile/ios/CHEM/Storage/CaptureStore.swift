import Foundation

public enum CaptureStoreError: Error {
  case applicationSupportUnavailable
  case emptySource
  case emptyThumbnail
  case thumbnailPreparationFailed(String)
  case writeFailed(String)
}

extension CaptureStoreError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .applicationSupportUnavailable:
      return "The application support directory is unavailable."
    case .emptySource:
      return "The captured source image is empty."
    case .emptyThumbnail:
      return "The captured preview thumbnail is empty."
    case .thumbnailPreparationFailed(let reason):
      return reason
    case .writeFailed(let reason):
      return "The captured photo could not be written: \(reason)"
    }
  }
}

public enum CapturePathGenerator {
  public static func sourceURL(rootURL: URL, captureID: String) -> URL {
    rootURL.appendingPathComponent("\(captureID).jpg", isDirectory: false)
  }

  public static func thumbnailURL(rootURL: URL, captureID: String) -> URL {
    rootURL.appendingPathComponent("\(captureID)-thumb.jpg", isDirectory: false)
  }

  public static func metadataURL(rootURL: URL, captureID: String) -> URL {
    rootURL.appendingPathComponent("\(captureID).json", isDirectory: false)
  }
}

public protocol CaptureStoring {
  func persist(
    sourceData: Data,
    captureID: String,
    width: Int,
    height: Int,
    capturedAt: String,
    lensID: String,
    prepareThumbnail: (URL) throws -> Data
  ) throws -> CaptureMetadata
}

/// Persists a full-resolution source first, then its thumbnail and latest-capture pointer.
/// A success result is returned only after all required atomic writes have completed.
@objc(CHEMCaptureStore)
public final class CaptureStore: NSObject, CaptureStoring {
  private static let sharedStore = CaptureStore(
    rootURL: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
      .first?.appendingPathComponent("CHEM/Captures", isDirectory: true)
  )

  private let rootURL: URL?
  private let queue = DispatchQueue(label: "chem.capture-store", qos: .utility)
  private let fileManager: FileManager

  public init(rootURL: URL?, fileManager: FileManager = .default) {
    self.rootURL = rootURL
    self.fileManager = fileManager
    super.init()
  }

  @objc public class func latestMetadataJSON() -> String {
    sharedStore.latestMetadataJSONValue
  }

  public var latestMetadataJSONValue: String {
    queue.sync {
      guard let rootURL,
            let data = try? Data(contentsOf: rootURL.appendingPathComponent("latest.json")),
            let json = String(data: data, encoding: .utf8) else {
        return ""
      }
      return json
    }
  }

  public func persist(
    sourceData: Data,
    captureID: String,
    width: Int,
    height: Int,
    capturedAt: String,
    lensID: String,
    prepareThumbnail: (URL) throws -> Data
  ) throws -> CaptureMetadata {
    try queue.sync {
      guard !sourceData.isEmpty else {
        throw CaptureStoreError.emptySource
      }
      guard let rootURL else {
        throw CaptureStoreError.applicationSupportUnavailable
      }

      let sourceURL = CapturePathGenerator.sourceURL(rootURL: rootURL, captureID: captureID)
      let thumbnailURL = CapturePathGenerator.thumbnailURL(rootURL: rootURL, captureID: captureID)
      let metadataURL = CapturePathGenerator.metadataURL(rootURL: rootURL, captureID: captureID)
      let latestURL = rootURL.appendingPathComponent("latest.json", isDirectory: false)
      do {
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        CameraLogger.capture(captureID, stage: "source_write_started")
        try sourceData.write(to: sourceURL, options: .atomic)
        let thumbnailData = try prepareThumbnail(sourceURL)
        guard !thumbnailData.isEmpty else {
          throw CaptureStoreError.emptyThumbnail
        }
        try thumbnailData.write(to: thumbnailURL, options: .atomic)

        let metadata = CaptureMetadata(
          id: captureID,
          sourceUri: sourceURL.absoluteString,
          thumbnailUri: thumbnailURL.absoluteString,
          width: width,
          height: height,
          capturedAt: capturedAt,
          lensId: lensID
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encodedMetadata = try encoder.encode(metadata)
        try encodedMetadata.write(to: metadataURL, options: .atomic)
        try encodedMetadata.write(to: latestURL, options: .atomic)
        CameraLogger.capture(captureID, stage: "source_persisted")
        return metadata
      } catch {
        try? fileManager.removeItem(at: sourceURL)
        try? fileManager.removeItem(at: thumbnailURL)
        try? fileManager.removeItem(at: metadataURL)
        if let storeFailure = error as? CaptureStoreError {
          throw storeFailure
        }
        throw CaptureStoreError.writeFailed(error.localizedDescription)
      }
    }
  }
}

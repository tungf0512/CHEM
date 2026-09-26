import AVFoundation
import Foundation
import ImageIO
import UniformTypeIdentifiers

public final class PhotoCaptureCoordinator {
  private let store: CaptureStoring
  private let lock = NSLock()
  private var requests: [Int64: PhotoCaptureRequest] = [:]

  public init(store: CaptureStoring) {
    self.store = store
  }

  public func capture(
    using output: AVCapturePhotoOutput,
    lens: CameraLens,
    completion: @escaping (Result<CaptureMetadata, CameraOperationFailure>) -> Void
  ) {
    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
    let requestID = settings.uniqueID
    let captureID = UUID().uuidString
    CameraLogger.capture(captureID, stage: "requested")
    let request = PhotoCaptureRequest(
      store: store,
      captureID: captureID,
      lens: lens,
      completion: completion,
      onFinished: { [weak self] in self?.removeRequest(requestID) }
    )
    lock.lock()
    requests[requestID] = request
    lock.unlock()
    output.capturePhoto(with: settings, delegate: request)
  }

  private func removeRequest(_ requestID: Int64) {
    lock.lock()
    requests.removeValue(forKey: requestID)
    lock.unlock()
  }
}

private final class PhotoCaptureRequest: NSObject, AVCapturePhotoCaptureDelegate {
  private let store: CaptureStoring
  private let captureID: String
  private let lens: CameraLens
  private let completion: (Result<CaptureMetadata, CameraOperationFailure>) -> Void
  private let onFinished: () -> Void
  private let stateLock = NSLock()
  private var didFinish = false

  init(
    store: CaptureStoring,
    captureID: String,
    lens: CameraLens,
    completion: @escaping (Result<CaptureMetadata, CameraOperationFailure>) -> Void,
    onFinished: @escaping () -> Void
  ) {
    self.store = store
    self.captureID = captureID
    self.lens = lens
    self.completion = completion
    self.onFinished = onFinished
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishProcessingPhoto photo: AVCapturePhoto,
    error: Error?
  ) {
    if let error {
      complete(.failure(CameraOperationFailure(code: .captureFailed, message: error.localizedDescription)))
      return
    }
    guard let sourceData = photo.fileDataRepresentation() else {
      complete(.failure(CameraOperationFailure(
        code: .captureFailed,
        message: "The camera did not return photo data."
      )))
      return
    }
    CameraLogger.capture(captureID, stage: "sensor_received")

    guard let imageSource = CGImageSourceCreateWithData(sourceData as CFData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
          let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
          let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
          width > 0,
          height > 0 else {
      complete(.failure(CameraOperationFailure(
        code: .captureFailed,
        message: "The camera photo metadata could not be read."
      )))
      return
    }

    do {
      let metadata = try store.persist(
        sourceData: sourceData,
        captureID: captureID,
        width: width,
        height: height,
        capturedAt: ISO8601DateFormatter().string(from: Date()),
        lens: lens,
        prepareThumbnail: { sourceURL in
          guard let durableSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
                let thumbnailData = Self.makeThumbnail(from: durableSource) else {
            throw CaptureStoreError.thumbnailPreparationFailed(
              "The persisted photo could not be prepared for preview."
            )
          }
          return thumbnailData
        }
      )
      complete(.success(metadata))
    } catch let failure as CaptureStoreError {
      complete(.failure(CameraOperationFailure(
        code: .sourcePersistenceFailed,
        message: failure.localizedDescription
      )))
    } catch {
      complete(.failure(CameraOperationFailure(
        code: .sourcePersistenceFailed,
        message: error.localizedDescription
      )))
    }
  }

  func photoOutput(
    _ output: AVCapturePhotoOutput,
    didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
    error: Error?
  ) {
    if let error {
      complete(.failure(CameraOperationFailure(code: .captureFailed, message: error.localizedDescription)))
    }
    onFinished()
  }

  private func complete(_ result: Result<CaptureMetadata, CameraOperationFailure>) {
    stateLock.lock()
    guard !didFinish else {
      stateLock.unlock()
      return
    }
    didFinish = true
    stateLock.unlock()
    completion(result)
  }

  private static func makeThumbnail(from source: CGImageSource) -> Data? {
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: 640,
    ]
    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
      return nil
    }
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
      data,
      UTType.jpeg.identifier as CFString,
      1,
      nil
    ) else {
      return nil
    }
    CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.84] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { return nil }
    return data as Data
  }
}

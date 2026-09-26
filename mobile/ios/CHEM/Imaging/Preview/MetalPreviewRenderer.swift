import CoreVideo
import CoreFoundation
import Foundation
import Metal
import MetalKit
import QuartzCore

private struct PreviewVertex {
  var position: SIMD2<Float>
  var textureCoordinate: SIMD2<Float>
}

private struct PreviewUniforms {
  var viewSize: SIMD2<Float>
  var sourceSize: SIMD2<Float>
  var orientation: UInt32
  var ycbcrMatrix: UInt32
  var ycbcrRange: UInt32
  var padding: UInt32 = 0
}

/// Latest-frame-only native Metal renderer. Pixel buffers never cross into React Native.
public final class MetalPreviewRenderer: NSObject, MTKViewDelegate {
  private let device: MTLDevice?
  private let commandQueue: MTLCommandQueue?
  private let textureCache: CVMetalTextureCache?
  private let pipelineState: MTLRenderPipelineState?
  private let vertices: MTLBuffer?
  private let frameRatePolicy = PreviewFrameRatePolicy()
  private weak var view: MTKView?
  private var thermalObserver: NSObjectProtocol?
  private var captureDeviceMaximumFPS = 30
  private let rendererCapacityFPS = 60
  private let frameLock = NSLock()
  private var latestPixelBuffer: CVPixelBuffer?
  private var orientationValue: UInt32 = 1
  private var didReportFailure = false
  private var latestGeneration: UInt64 = 0
  private var lastSubmittedGeneration: UInt64 = 0
  private var isRenderInFlight = false
  private var metricBucketStartedAt = CACurrentMediaTime()
  private var metricInputFrames = 0
  private var metricRenderedFrames = 0
  private var metricDroppedFrames = 0
  private var metricTotalGPUTime = 0.0
  private var metricCameraState = "idle"
  private var metricActiveLens = ""

  private var storedFailureMessage: String?
  public var failureMessage: String? {
    frameLock.lock()
    defer { frameLock.unlock() }
    return storedFailureMessage
  }
  public var onFailure: ((String) -> Void)?
  public var onMetrics: (([String: Any]) -> Void)?

  public override init() {
    let metalDevice = MTLCreateSystemDefaultDevice()
    device = metalDevice
    commandQueue = metalDevice?.makeCommandQueue()

    var cache: CVMetalTextureCache?
    if let metalDevice {
      CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &cache)
    }
    textureCache = cache

    if let metalDevice,
       let library = metalDevice.makeDefaultLibrary(),
       let vertexFunction = library.makeFunction(name: "chemPreviewVertex"),
       let fragmentFunction = library.makeFunction(name: "chemPreviewFragment") {
      let descriptor = MTLRenderPipelineDescriptor()
      descriptor.vertexFunction = vertexFunction
      descriptor.fragmentFunction = fragmentFunction
      descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      pipelineState = try? metalDevice.makeRenderPipelineState(descriptor: descriptor)
    } else {
      pipelineState = nil
    }

    let vertexData = [
      PreviewVertex(position: SIMD2(-1, 1), textureCoordinate: SIMD2(0, 0)),
      PreviewVertex(position: SIMD2(1, 1), textureCoordinate: SIMD2(1, 0)),
      PreviewVertex(position: SIMD2(-1, -1), textureCoordinate: SIMD2(0, 1)),
      PreviewVertex(position: SIMD2(1, -1), textureCoordinate: SIMD2(1, 1)),
    ]
    if let metalDevice {
      vertices = vertexData.withUnsafeBytes { bytes in
        guard let baseAddress = bytes.baseAddress else { return nil }
        return metalDevice.makeBuffer(bytes: baseAddress, length: bytes.count, options: .storageModeShared)
      }
    } else {
      vertices = nil
    }

    super.init()
    thermalObserver = NotificationCenter.default.addObserver(
      forName: ProcessInfo.thermalStateDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in self?.applyFrameRatePolicy() }
    if metalDevice == nil {
      storedFailureMessage = "This device does not expose a Metal rendering device."
    } else if commandQueue == nil || textureCache == nil || pipelineState == nil || vertices == nil {
      storedFailureMessage = "The neutral Metal preview pipeline could not be initialized."
    }
  }

  deinit {
    if let thermalObserver { NotificationCenter.default.removeObserver(thermalObserver) }
  }

  public func attach(to view: MTKView?) {
    if let previous = self.view, previous !== view {
      previous.delegate = nil
      previous.isPaused = true
    }
    self.view = view
    guard let view else { return }
    view.device = device
    view.colorPixelFormat = .bgra8Unorm
    view.framebufferOnly = true
    view.autoResizeDrawable = true
    if let metalLayer = view.layer as? CAMetalLayer {
      metalLayer.colorspace = CGColorSpace(name: CGColorSpace.sRGB)
    }
    view.enableSetNeedsDisplay = false
    view.isPaused = !isActive || failureMessage != nil
    view.clearColor = MTLClearColor(red: 0.035, green: 0.04, blue: 0.05, alpha: 1)
    view.delegate = self
    applyFrameRatePolicy()
    if let failureMessage { reportFailureOnce(failureMessage) }
  }

  private var isActive = false

  public func setActive(_ active: Bool) {
    isActive = active
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.view?.isPaused = !active || self.failureMessage != nil
      self.applyFrameRatePolicy()
    }
  }

  public func updateCaptureDeviceFrameRateLimit(_ maximumFPS: Int) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.captureDeviceMaximumFPS = maximumFPS
      self.applyFrameRatePolicy()
    }
  }

  private func applyFrameRatePolicy() {
    let thermalLevel: PreviewThermalLevel
    switch ProcessInfo.processInfo.thermalState {
    case .nominal: thermalLevel = .nominal
    case .fair: thermalLevel = .fair
    case .serious: thermalLevel = .serious
    case .critical: thermalLevel = .critical
    case .unknown: thermalLevel = .unknown
    @unknown default: thermalLevel = .unknown
    }
    view?.preferredFramesPerSecond = frameRatePolicy.targetFramesPerSecond(
      thermalLevel: thermalLevel,
      captureDeviceMaximumFramesPerSecond: captureDeviceMaximumFPS,
      rendererCapacityFramesPerSecond: rendererCapacityFPS
    )
  }

  public func setOrientation(_ orientation: Int) {
    frameLock.lock()
    orientationValue = UInt32(clamping: orientation)
    frameLock.unlock()
  }

  public func enqueue(_ pixelBuffer: CVPixelBuffer) {
    frameLock.lock()
    #if DEBUG
    if latestGeneration > lastSubmittedGeneration {
      metricDroppedFrames += 1
    }
    metricInputFrames += 1
    #endif
    latestGeneration += 1
    latestPixelBuffer = pixelBuffer
    frameLock.unlock()
  }

  public func updateCameraContext(state: String? = nil, activeLens: String? = nil) {
    frameLock.lock()
    if let state { metricCameraState = state }
    if let activeLens { metricActiveLens = activeLens }
    frameLock.unlock()
  }

  public func draw(in view: MTKView) {
    frameLock.lock()
    guard !isRenderInFlight,
          latestGeneration > lastSubmittedGeneration,
          let pixelBuffer = latestPixelBuffer else {
      frameLock.unlock()
      return
    }
    isRenderInFlight = true
    let orientation = orientationValue
    let generation = latestGeneration
    frameLock.unlock()
    guard let colorParameters = colorParameters(for: pixelBuffer) else {
      reportFailureOnce("The camera preview received unsupported wide-gamut or HDR color metadata; the neutral SDR renderer did not apply an approximate transform.")
      releaseRenderSlot()
      return
    }
    guard let descriptor = view.currentRenderPassDescriptor,
          let drawable = view.currentDrawable,
          let commandBuffer = commandQueue?.makeCommandBuffer(),
          let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
      releaseRenderSlot()
      return
    }

    guard let pipelineState,
          let yTexture = makeTexture(from: pixelBuffer, plane: 0, pixelFormat: .r8Unorm),
          let chromaTexture = makeTexture(from: pixelBuffer, plane: 1, pixelFormat: .rg8Unorm),
          let vertices else {
      encoder.endEncoding()
      releaseRenderSlot()
      return
    }

    encoder.setRenderPipelineState(pipelineState)
    let bounds = view.drawableSize
    var uniforms = PreviewUniforms(
      viewSize: SIMD2(Float(bounds.width), Float(bounds.height)),
      sourceSize: SIMD2(Float(CVPixelBufferGetWidth(pixelBuffer)), Float(CVPixelBufferGetHeight(pixelBuffer))),
      orientation: orientation,
      ycbcrMatrix: colorParameters.matrix,
      ycbcrRange: colorParameters.isFullRange ? 1 : 0
    )
    withUnsafePointer(to: &uniforms) { pointer in
      encoder.setVertexBytes(pointer, length: MemoryLayout<PreviewUniforms>.stride, index: 1)
      encoder.setFragmentBytes(pointer, length: MemoryLayout<PreviewUniforms>.stride, index: 0)
    }
    encoder.setVertexBuffer(vertices, offset: 0, index: 0)
    encoder.setFragmentTexture(yTexture.texture, index: 0)
    encoder.setFragmentTexture(chromaTexture.texture, index: 1)
    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    encoder.endEncoding()
    frameLock.lock()
    lastSubmittedGeneration = max(lastSubmittedGeneration, generation)
    frameLock.unlock()
    commandBuffer.addCompletedHandler { [weak self] buffer in
      withExtendedLifetime(yTexture.reference) {}
      withExtendedLifetime(chromaTexture.reference) {}
      let gpuMilliseconds = max(0, (buffer.gpuEndTime - buffer.gpuStartTime) * 1_000)
      self?.finishRender(gpuMilliseconds: gpuMilliseconds)
    }
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

  public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

  private func makeTexture(
    from pixelBuffer: CVPixelBuffer,
    plane: Int,
    pixelFormat: MTLPixelFormat
  ) -> (texture: MTLTexture, reference: CVMetalTexture)? {
    guard let textureCache else { return nil }
    let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, plane)
    let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane)
    var texture: CVMetalTexture?
    let result = CVMetalTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault,
      textureCache,
      pixelBuffer,
      nil,
      pixelFormat,
      width,
      height,
      plane,
      &texture
    )
    guard result == kCVReturnSuccess, let texture else {
      reportFailureOnce("The camera pixel buffer could not be mapped into Metal textures.")
      return nil
    }
    guard let metalTexture = CVMetalTextureGetTexture(texture) else {
      reportFailureOnce("The camera Metal texture could not be created.")
      return nil
    }
    return (metalTexture, texture)
  }

  private func colorParameters(for pixelBuffer: CVPixelBuffer) -> (matrix: UInt32, isFullRange: Bool)? {
    let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
    let isFullRange: Bool
    if pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange {
      isFullRange = false
    } else if pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
      isFullRange = true
    } else {
      return nil
    }

    let matrixValue = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, nil)?.takeUnretainedValue()
    let matrix: UInt32
    if let matrixValue, CFEqual(matrixValue, kCVImageBufferYCbCrMatrix_ITU_R_601_4) {
      matrix = 1
    } else if let matrixValue,
              CFEqual(matrixValue, kCVImageBufferYCbCrMatrix_ITU_R_709_2) {
      matrix = 0
    } else if matrixValue == nil {
      // The capture device is explicitly fixed to SDR sRGB/Rec.709-compatible output.
      matrix = 0
    } else {
      return nil
    }

    let transferValue = CVBufferGetAttachment(pixelBuffer, kCVImageBufferTransferFunctionKey, nil)?.takeUnretainedValue()
    if let transferValue,
       !CFEqual(transferValue, kCVImageBufferTransferFunction_ITU_R_709_2),
       !CFEqual(transferValue, kCVImageBufferTransferFunction_sRGB) {
      return nil
    }
    let primariesValue = CVBufferGetAttachment(pixelBuffer, kCVImageBufferColorPrimariesKey, nil)?.takeUnretainedValue()
    if let primariesValue,
       !CFEqual(primariesValue, kCVImageBufferColorPrimaries_ITU_R_709_2),
       !CFEqual(primariesValue, kCVImageBufferColorPrimaries_SMPTE_C) {
      return nil
    }
    return (matrix, isFullRange)
  }

  private func reportFailureOnce(_ message: String) {
    frameLock.lock()
    guard !didReportFailure else {
      frameLock.unlock()
      return
    }
    didReportFailure = true
    storedFailureMessage = message
    frameLock.unlock()
    DispatchQueue.main.async { [weak self] in
      self?.view?.isPaused = true
      self?.onFailure?(message)
    }
  }

  private func releaseRenderSlot() {
    frameLock.lock()
    isRenderInFlight = false
    frameLock.unlock()
  }

  private func finishRender(gpuMilliseconds: Double) {
    frameLock.lock()
    isRenderInFlight = false
    var metricsToPublish: [String: Any]?
    #if DEBUG
    metricRenderedFrames += 1
    metricTotalGPUTime += gpuMilliseconds
    let now = CACurrentMediaTime()
    let elapsed = now - metricBucketStartedAt
    guard elapsed >= 1 else {
      frameLock.unlock()
      return
    }
    metricsToPublish = [
      "previewFPS": Int((Double(metricInputFrames) / elapsed).rounded()),
      "renderFPS": Int((Double(metricRenderedFrames) / elapsed).rounded()),
      "renderMilliseconds": metricRenderedFrames == 0 ? 0 : metricTotalGPUTime / Double(metricRenderedFrames),
      "droppedFrames": metricDroppedFrames,
      "activeLens": metricActiveLens,
      "cameraState": metricCameraState,
    ]
    metricBucketStartedAt = now
    metricInputFrames = 0
    metricRenderedFrames = 0
    metricDroppedFrames = 0
    metricTotalGPUTime = 0
    frameLock.unlock()
    #else
    frameLock.unlock()
    #endif
    if let metricsToPublish {
      onMetrics?(metricsToPublish)
    }
  }
}

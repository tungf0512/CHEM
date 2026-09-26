import MetalKit
import UIKit

@objc public final class CHEMCameraPreviewView: UIView {
  @objc public let cameraEngine: CHEMCameraEngine
  private let metalView: MTKView
  private var requestedActive = false

  public override init(frame: CGRect) {
    cameraEngine = CHEMCameraEngine()
    metalView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    super.init(frame: frame)
    backgroundColor = .black
    metalView.isUserInteractionEnabled = false
    addSubview(metalView)
    cameraEngine.attachPreview(metalView)
  }

  public required init?(coder: NSCoder) {
    cameraEngine = CHEMCameraEngine()
    metalView = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    super.init(coder: coder)
    backgroundColor = .black
    metalView.isUserInteractionEnabled = false
    addSubview(metalView)
    cameraEngine.attachPreview(metalView)
  }

  @objc public func setPreviewActive(_ active: Bool) {
    requestedActive = active
    cameraEngine.setActive(active && window != nil)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    metalView.frame = bounds
    let orientation = window?.windowScene?.interfaceOrientation ?? .portrait
    cameraEngine.updatePreviewGeometry(width: bounds.width, height: bounds.height, orientation: orientation.rawValue)
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    cameraEngine.setActive(requestedActive && window != nil)
    cameraEngine.attachPreview(metalView)
  }

  deinit {
    cameraEngine.setActive(false)
    cameraEngine.attachPreview(nil)
  }
}

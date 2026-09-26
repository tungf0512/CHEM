# CHEM system architecture — camera foundation

This milestone implements the first narrow camera slice. React Native owns the product experience and control plane; Swift/AVFoundation/Metal own the camera and pixel data plane. The supplied HTML and screenshots are design references only and are not loaded by the application.

```text
React Native CameraScreen
  permission, controls, telemetry, focus affordance, last local thumbnail
            │ typed Codegen commands/events (metadata only)
            ▼
TurboModule: permission + latest-capture metadata query
Fabric CHEMCameraPreview: native MTKView host + typed event emitters
            │
            ▼
Per-mounted-view CHEMCameraEngine
  CameraSessionController ── serial session queue ── AVCaptureSession
       │ AVCaptureVideoDataOutput                     │ AVCapturePhotoOutput
       ▼                                               ▼
MetalPreviewRenderer                            PhotoCaptureCoordinator
  newest-frame slot / YCbCr Metal                    │
       │                                              ▼
       ▼                                         CaptureStore
   MTKView / Fabric                           Application Support files
```

## Ownership and threading

- `CameraSessionController` is the sole owner of session topology and camera-device mutations. It serializes configuration, start/stop, lens selection, focus, and exposure on `chem.camera.session`. `chem.camera.video` receives `AVCaptureVideoDataOutput` sample callbacks. The renderer uses MetalKit's draw callback and a lock-protected latest-frame slot; frames are replaced rather than accumulated.
- A mounted Fabric preview retains its `CHEMCameraEngine` while props update. `active` starts or stops the existing session; it does not recreate the engine. Recycle/unmount deactivates and invalidates its owner. The app has one camera screen in this milestone; there is no process-global camera singleton.
- Native application/session notifications cover active/background transitions, AVFoundation interruptions, runtime errors, and media-services reset. React Native AppState is used for presentation, not as the only native cleanup mechanism.
- CameraCore imports AVFoundation/Foundation and does not import React Native. The view wrapper and minimal ObjC++ adapters are the only React Native-specific native layer.

## Preview data plane

`AVCaptureVideoDataOutput` supplies bi-planar YCbCr pixel buffers. Late frames are discarded by AVFoundation; the renderer retains only the newest buffer. A persistent `MTLDevice`, command queue, pipeline, vertex buffer, and `CVMetalTextureCache` back conversion and aspect-fill rendering directly into a native `MTKView`. Orientation and view geometry are sent to native code; no UIImage, Base64, pixel buffer, texture, histogram, or frame-rate stream crosses into JavaScript. The shader is neutral/pass-through, not a film look. This source implementation has not been built or exercised on iOS hardware in the current Linux environment.

## Camera and capture flow

The TurboModule reports/request permission only if status is not determined and exposes a local last-capture metadata query. Once authorized, Fabric activates its engine. Native discovers actual rear devices and emits serializable lens descriptors; React Native shows those choices and only changes its selected lens on a native active-lens acknowledgment. Tap coordinates are normalized by the UI and remapped natively through preview aspect-fill and interface orientation. EV is clamped in UI state and again against device limits natively.

Still capture uses `AVCapturePhotoOutput` and JPEG source data. `CaptureStore` first atomically writes the source under Application Support; only then does its thumbnail-preparation callback decode from that durable file. It atomically writes the thumbnail, per-capture metadata, and latest pointer afterward. Any preparation/write failure returns a typed failure and removes partial transaction files; completion metadata is emitted only after all required writes succeed. The capture event contains file URIs and dimensions, never image bytes. The most recent thumbnail is rendered by React Native from its local file URI and can be opened in a read-only modal.

## Deliberate boundaries

The implementation does not include an artistic film pipeline, Film Shelf, Lab, RAW/ProRAW, manual Pro controls, video, networking, account features, or cloud storage. No network is needed for the camera foundation. Android retains its generated RN shell and presents an iOS-only camera state; Android camera support is not claimed.

## Verification boundary

TypeScript, Jest, lint, and Codegen generation are host-checkable. Swift compilation, CocoaPods integration, `xcodebuild`, simulator rendering, AVFoundation behavior, orientation, and physical camera testing require macOS/Xcode and, for hardware behavior, a physical iPhone. See [Implementation status](IMPLEMENTATION_STATUS.md) and [physical-device checklist](PHYSICAL_DEVICE_VALIDATION.md) for the actual result.

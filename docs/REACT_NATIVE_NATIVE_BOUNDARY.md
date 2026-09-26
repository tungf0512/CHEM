# React Native / native iOS boundary

React Native owns the experience. Native iOS owns the camera and pixels. The UI remains a control plane around a native imaging data plane; camera frames and full-resolution image bytes never enter JavaScript.

| Responsibility | React Native | Native iOS |
|---|---:|---:|
| Camera UI | ✅ | |
| Lens buttons | ✅ | |
| Focus indicator UI | ✅ | |
| Camera session | | ✅ |
| Device discovery | | ✅ |
| Preview frames | | ✅ |
| Metal rendering | | ✅ |
| Still capture | | ✅ |
| Source persistence | | ✅ |
| Live film engine (future) | | ✅ |
| Lab UI (future) | ✅ | |
| Full-res render (future) | | ✅ |

The future rows describe ownership only and are not implemented in this milestone.

## Native surface

- Fabric component: `CHEMCameraPreview` (Codegen component name), implemented by `CHEMCameraPreviewComponentView` and its contained native `CHEMCameraPreviewView`/`MTKView`.
- TurboModule: `CHEMCameraModule`, used only for permission status/request and querying persisted last-capture metadata when no preview view needs to be mounted.
- CameraCore is Swift and React-Native-independent. The ObjC++ files bridge Codegen-generated interfaces to Swift and are intentionally limited to that adapter work.

## Commands

| Command | Direction | Payload and meaning |
|---|---|---|
| `start` | JS → Fabric | Activate the mounted preview/session. |
| `stop` | JS → Fabric | Stop active capture while retaining the mounted engine. |
| `selectLens(deviceId)` | JS → Fabric | Request an available native device; UI selection waits for acknowledgment. |
| `focusAndExpose(normalizedX, normalizedY)` | JS → Fabric | Ask native to map view coordinates through aspect-fill/orientation and apply focus/exposure points. |
| `setExposureCompensation(ev)` | JS → Fabric | Set capture exposure bias in EV; native clamps to device range. |
| `capture` | JS → Fabric | Trigger native still capture; haptic is best effort and does not gate capture. |
| `getCameraPermissionStatus()` | JS → TurboModule | Return one of `notDetermined`, `authorized`, `denied`, `restricted`, or defensive `unknown`. |
| `requestCameraPermission()` | JS → TurboModule | Prompt only while status is not determined and return resulting status. |
| `getLastCapture()` | JS → TurboModule | Return JSON metadata for the latest locally committed capture, or an empty string. Pixels remain native/local. |

`active?: boolean` is the only camera configuration prop. It starts/stops the stable mounted engine rather than rebuilding the camera session. No image or per-frame prop exists.

## Typed native events

| Event | Direction | Contract |
|---|---|---|
| `onCameraStateChanged` | Native → JS | `state`, `reason`, `code`; lifecycle states are idle/configuring/running/interrupted/failed. |
| `onAvailableLensesChanged` | Native → JS | Actual rear camera descriptors `{id, role, displayZoom}[]`. |
| `onActiveLensChanged` | Native → JS | Native-confirmed `{id}` after activation. |
| `onLensSelectionFailed` | Native → JS | `{id, code, message}`; selection remains unconfirmed. |
| `onExposureChanged` | Native → JS | `{minimumEV, maximumEV, appliedEV}` from the active device. |
| `onTelemetryChanged` | Native → JS | Real `{iso, shutterSeconds, lensDisplay, captureExposureCompensationEV}`, throttled to about 2 Hz. |
| `onPerformanceMetricsChanged` | Native → JS | Debug-only aggregate FPS, GPU render time, dropped-frame count, active lens, and lifecycle; low frequency, never per frame. |
| `onCaptureCompleted` | Native → JS | `{id, sourceUri, thumbnailUri, width, height, capturedAt, lensId}` after durable writes. No image bytes. |
| `onCaptureFailed` | Native → JS | Stable `{code, message}`; no raw pixels or user-facing NSError text. |
| `onCameraError` | Native → JS | Stable `{code, message}` for non-capture camera operations. |

Generated Codegen headers are build artifacts. Source contracts live in `mobile/src/specs/`; do not hand-edit generated output.

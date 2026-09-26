# Module contracts

## React Native feature state

`mobile/src/features/camera/camera.types.ts` centralizes the discriminated camera lifecycle, stable camera error codes, permission states, native lens descriptors, capture metadata, telemetry, exposure capabilities, performance aggregates, and reducer actions. Native strings are validated/mapped before entering product state. The reducer preserves the prior last capture on failure and only confirms a lens after native acknowledgment. Exposure values are clamped to the reported device bounds before sending.

## Fabric component

Codegen source: `mobile/src/specs/CHEMCameraNativeComponent.ts` (`codegenNativeComponent('CHEMCameraPreview')`). Its optional `active` prop and typed direct events are the complete view contract. Generated command methods are `start`, `stop`, `selectLens`, `focusAndExpose`, `setExposureCompensation`, and `capture`. The view hosts the native preview renderer; frames are not properties or events.

## TurboModule

Codegen source: `mobile/src/specs/NativeCHEMCameraModule.ts` (`NativeCHEMCameraModule` maps to `CHEMCameraModule`). It exposes permission read/request and `getLastCapture(): Promise<string>`. The last-capture response is decoded/validated as metadata in JS; it is not an image payload. Permission request resolves the existing status without re-prompting after a prior decision.

## Native domain

- `CameraLens`: stable device ID, typed lens role, human-readable optical zoom.
- `CameraLifecycleState`: idle/configuring/running/interrupted/failed with a transition guard.
- `CameraOperationFailure`: stable error category plus safe descriptive message.
- `ExposureBiasRange`: hardware min/max and clamping.
- `CaptureStoring`: native storage abstraction independent of React Native event types.
- `CaptureMetadata`: UUID, local source/thumbnail URIs, dimensions, timestamp, and lens ID.

## Capture persistence contract

`CaptureStore.persist` atomically writes non-empty source data first, then invokes a thumbnail-preparation callback with the durable source URL. It returns metadata only after non-empty thumbnail data, capture JSON, and `latest.json` have also been atomically written. A write/preparation failure cleans up partial per-capture files and surfaces a typed capture or persistence failure. The source is under Application Support, not Caches. The current JPEG container is deliberately simple and does not claim RAW/ProRAW or a complete future CHEM frame repository.

## Error categories

`permissionDenied`, `sessionConfigurationFailed`, `cameraUnavailable`, `lensSwitchFailed`, `focusFailed`, `exposureFailed`, `captureFailed`, `sourcePersistenceFailed`, `rendererFailed`, and `interrupted`. UI maps these to controlled copy. Messages may be included in typed native events for diagnostics, but raw framework error strings are not shown directly in the Camera screen.

Native lifecycle/capture stages use `OSLog` with capture UUIDs and no image/location data. `cameraLogger.ts` adds a small `__DEV__`-only React Native logger for permission, lifecycle, and capture control events; it does not log file URIs or image contents.

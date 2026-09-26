# ADR-003: Camera ownership stays in native iOS CameraCore

- Status: accepted
- Context: Live preview, device switching, focus/exposure, and reliable still capture need native camera lifecycle and hardware access.
- Decision: A Swift `CameraSessionController` is the sole serialized owner of the `AVCaptureSession` topology and device mutations. It configures `AVCaptureVideoDataOutput` and `AVCapturePhotoOutput`, discovers actual rear cameras, and observes app/session lifecycle natively.
- Consequences: CameraCore is independent of React Native; the mounted Fabric view keeps its engine while props update. Linux can inspect source but cannot prove Swift compilation, session operation, or hardware behavior.

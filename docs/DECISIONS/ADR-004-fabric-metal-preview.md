# ADR-004: Fabric hosts a native neutral Metal preview

- Status: accepted
- Context: The first milestone needs a native live view while preserving a strict no-camera-frames-in-JavaScript boundary.
- Decision: A Fabric component hosts `MTKView`; `AVCaptureVideoDataOutput` feeds a native latest-frame-only renderer using reusable Metal resources and YCbCr conversion. The React Native component exchanges control commands and low-frequency aggregates only.
- Consequences: No WebView, Expo Camera, VisionCamera, JS filter, or per-frame bridge path exists. Preview is intentionally neutral; orientation, image conversion, pacing, and renderer stability remain to be visually verified on supported iPhones.

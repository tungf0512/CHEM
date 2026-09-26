# ADR-005: Persist the native source before capture success

- Status: accepted
- Context: Capture reliability requires a durable original before the UI is told that a photo exists.
- Decision: `AVCapturePhotoOutput` produces JPEG source data. Native storage atomically writes the source first under Application Support, then prepares a thumbnail from that durable source and atomically writes thumbnail, per-capture metadata, and the latest-capture pointer. Only after the transaction succeeds does the native layer emit metadata and local URIs.
- Consequences: JavaScript never receives full-resolution bytes and can restore the latest thumbnail by querying metadata. The current store is a small camera-foundation abstraction, not the final CHEM Frame repository; native tests and restart behavior remain unverified here.

# ADR-006: Live camera frames never enter JavaScript

- Status: accepted
- Context: React Native is the product control plane, but camera-rate image processing would create avoidable copies, latency, and capture instability.
- Decision: Keep sample buffers, pixel buffers, Metal textures, frame scheduling, and all image rendering inside native iOS. Bridge only lifecycle, lens descriptors, exposure/telemetry summaries, capture metadata, failures, and user-issued commands.
- Consequences: Future film preview and full-resolution render belong in the native imaging pipeline. No frame Base64, per-frame event, histogram array, or JS filter API may be added.

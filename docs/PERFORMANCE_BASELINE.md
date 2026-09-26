# Neutral preview performance baseline

No physical measurements have been made yet. Fill one record per device/build; do not infer observed performance from the configured display cadence.

```text
Device: iPhone Air (first target; exact model identifier: __________)
iOS version: __________
Build commit: __________
Date: __________

Preview resolution: __________
Configured FPS (nominal / fair): preferred 60, capped by capture-device and renderer limits
Configured FPS (serious / critical / unknown thermal): stable 30 fallback, capped by device/renderer
Observed input FPS: __________
Observed render FPS: __________
p50 render ms: __________
p95 render ms: __________
Dropped frames: __________
Memory: __________
Thermal state: __________
Scene / duration / orientation / capture mode: __________
Notes: __________
```

The renderer exposes dev-only low-frequency input/render FPS, average GPU render time, dropped-frame count, active capture mode, and lifecycle state. These aggregate metrics never contain frame data and are not emitted per frame. The configured cadence does not set AVFoundation exposure duration; observed rate and physical performance remain device checks.

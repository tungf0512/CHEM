# Physical-device validation checklist

No physical camera item is marked complete. The first target is **iPhone Air**, whose 1× and 2× modes must be validated as two capture modes of the same physical Fusion Main sensor. Add other device records for physical Ultra Wide / Main / Telephoto combinations.

## Device record

```text
Device: iPhone Air (first target)
Exact model identifier: __________
iOS: __________
Build commit: __________
Date: __________
Tester: __________
Evidence folder / video / logs: __________
```

- [ ] App launches safely; simulator/unavailable state does not crash. Notes/evidence: __________
- [ ] Camera starts and requests permission only when appropriate. Notes/evidence: __________
- [ ] Denied/restricted permission and Settings return work. Notes/evidence: __________
- [ ] Neutral preview orientation is correct in portrait. Evidence: __________
- [ ] Neutral preview orientation is correct in landscape left. Evidence: __________
- [ ] Neutral preview orientation is correct in landscape right. Evidence: __________
- [ ] Preview aspect-fill crop and tap focus/exposure mapping agree at center and four near-corners in each orientation. Evidence: __________
- [ ] Preview color is neutral vs Apple/reference view; record matrix, primaries, transfer, output-display settings and any visible mismatch. Evidence: __________
- [ ] Preview FPS: record configured, observed input/render FPS, dropped frames, scene duration, and thermal state. Evidence: __________
- [ ] iPhone Air lens list has one 1× and one 2× Main-sensor mode (no duplicate virtual/physical buttons); metadata shows the same physical device ID and distinct mode/zoom values. Evidence: __________
- [ ] Switch 1× ↔ 2× repeatedly; capture crop and metadata remain deterministic. Evidence: __________
- [ ] Lens list on additional supported devices contains no duplicate semantic zoom choices. Device / evidence: __________
- [ ] Tap focus corresponds to tapped scene region. Evidence: __________
- [ ] Tap exposure corresponds to tapped scene region. Evidence: __________
- [ ] EV compensation respects the active camera range. Evidence: __________
- [ ] 20 repeated captures produce 20 source-safe records. Evidence/log: __________
- [ ] Source files survive force-close/relaunch. Evidence: __________
- [ ] Last-frame thumbnail updates after a complete capture. Evidence: __________
- [ ] Simulated thumbnail failure returns a source-safe record with no thumbnail and does not delete source. Evidence/log: __________
- [ ] Simulated metadata write failure retains a source-safe record and can be recovered on query/relaunch. Evidence/log: __________
- [ ] Simulated latest-pointer failure retains capture and recovery scan restores the latest record. Evidence/log: __________
- [ ] Background / foreground resume works without duplicate start/stop churn. Evidence: __________
- [ ] AVFoundation interruption and interruption-ended recovery work. Evidence: __________
- [ ] Media-services reset recovery works where it can be safely induced. Evidence/log: __________

## Additional device record template

```text
Device: __________
Exact model identifier: __________
iOS: __________
Build commit: __________
Date: __________
Available physical devices / modes: __________
Observed preview FPS / thermal state: __________
Lens identity and crop metadata evidence: __________
Color comparison evidence: __________
Failures / notes: __________
```

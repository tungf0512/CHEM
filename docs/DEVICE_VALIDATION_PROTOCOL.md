# CHEM iPhone Air validation protocol

Target the physical **iPhone Air** first. The expected topology is one physical Fusion Main camera with a 1× physical mode and, when reported by capabilities, a 2× main-sensor crop mode. The model must remain generic for devices that also expose physical Ultra Wide, Main, or Telephoto cameras.

## Evidence header

```text
Device: iPhone Air
Exact model identifier: __________
iOS: __________
CHEM version/build: __________
Git commit: __________
Date/tester: __________
Evidence folder or video: __________
```

For each test, record the action, observed result, report/metadata evidence, and mark exactly `PASS` or `FAIL`. A failed test is not silently waived.

## A. Installation and build identity

| ID | Action | Expected result | Evidence / PASS-FAIL |
| --- | --- | --- | --- |
| A-01 | Install the internal TestFlight build and open diagnostics (long-press CHEM header). | Semantic version, build number, commit SHA, and `neutral-sdr-v1` are visible. | __________ |
| A-02 | Confirm the diagnostics report contains only metadata. | No photo pixels, GPS, account, or advertising identifiers are present. | __________ |

## B. Permission and lifecycle

| ID | Action | Expected result | Evidence / PASS-FAIL |
| --- | --- | --- | --- |
| B-01 | Fresh install, grant camera access, background/foreground the app. | Permission request is explicit; session resumes once without duplicate starts. | __________ |
| B-02 | Deny permission, relaunch, then use Settings and return. | The UI explains the state and recovers after authorization. | __________ |
| B-03 | Induce a camera interruption if safe. | State changes to interrupted and returns to running after interruption ends. | __________ |

## C. Camera identity and modes

| ID | Action | Expected result | Evidence / PASS-FAIL |
| --- | --- | --- | --- |
| AIR-01 | Inspect the lens selector on iPhone Air. | Exactly one Main 1× and one Main 2× mode appear where 2× is supported. | __________ |
| AIR-02 | Compare diagnostics while selecting 1× and 2×. | Both modes report the same physical Main identifier. | __________ |
| AIR-03 | Capture metadata at 1× and 2×. | Mode ID, display zoom, and device-local zoom differ deterministically. | __________ |
| AIR-04 | Switch 1× ↔ 2× repeatedly for one minute. | No duplicate buttons/sessions, preview freeze, or stale active-mode acknowledgement. | __________ |

## D. Orientation, aspect fill, and focus coordinates

| ID | Action | Expected result | Evidence / PASS-FAIL |
| --- | --- | --- | --- |
| AIR-05 | Tap the same marked subject in portrait, landscape-left, and landscape-right; repeat at center and four near-corners. | Focus/exposure follows the tapped scene point after aspect-fill crop and orientation mapping. | __________ |
| D-02 | Rotate while preview is active and capture. | Still orientation and preview orientation agree; no 90°/180° mismatch. | __________ |

## E. Exposure and EV

| ID | Action | Expected result | Evidence / PASS-FAIL |
| --- | --- | --- | --- |
| E-01 | Move EV control to both limits and back to zero. | Values are clamped to the active device range and telemetry reflects applied EV. | __________ |
| E-02 | Tap bright and dark regions. | Exposure telemetry changes for the selected scene region without a lifecycle failure. | __________ |

## F. Neutral color

| ID | Action | Expected result | Evidence / PASS-FAIL |
| --- | --- | --- | --- |
| AIR-10 | Compare the neutral preview beside Apple Camera/reference under daylight, skin tone, and low light. | No artistic film look is applied; record any visible mismatch and report matrix, primaries, transfer, range, and output baseline. | __________ |

## G. Preview performance and thermal

| ID | Action | Expected result | Evidence / PASS-FAIL |
| --- | --- | --- | --- |
| AIR-09 | Keep a continuous scene for at least 60 seconds; export the report at nominal and warm thermal states if possible. | Configured FPS, input/render FPS, dropped/stale frames, render time, dimensions, and thermal state are recorded. | __________ |

## H. Capture reliability

| ID | Action | Expected result | Evidence / PASS-FAIL |
| --- | --- | --- | --- |
| AIR-06 | Capture 20 photos in a repeatable scene. | 20 unique source-safe records exist; every source is non-empty. | __________ |
| H-02 | Force-close and relaunch after the sequence. | Source-safe records remain discoverable and the latest record is restored. | __________ |

## I. Recovery and fault injection

| ID | Action | Expected result | Evidence / PASS-FAIL |
| --- | --- | --- | --- |
| AIR-08a | Set `THUMBNAIL FAILURE`, capture, then query metadata. | Source remains safe; thumbnail may be absent; record is recoverable. | __________ |
| AIR-08b | Set `METADATA FAILURE`, capture, then relaunch/query. | Source remains safe and metadata is reconstructed or marked recoverable. | __________ |
| AIR-08c | Set `LATEST POINTER FAILURE`, capture, then query/relaunch. | Recovery scan finds the capture even when the pointer write fails. | __________ |
| I-04 | Clear the fault and capture normally. | A complete record with thumbnail is produced. | __________ |

## J. Evidence export

| ID | Action | Expected result | Evidence / PASS-FAIL |
| --- | --- | --- | --- |
| J-01 | Tap `COPY VALIDATION REPORT` and paste into the evidence record. | Small JSON metadata report is copied; no image data is included. | __________ |
| J-02 | Attach capture metadata and a short preview/performance recording. | Evidence is sufficient to reproduce any failure without sharing private account/location data. | __________ |

Unexecuted tests remain `NOT RUN`; this document does not claim physical-device verification by itself.

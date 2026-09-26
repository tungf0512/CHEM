# CHEM iOS foundation verification

Status before this run:
- JS build verification: Previously reported passing in `IMPLEMENTATION_STATUS.md`; rerun in this task.
- Codegen verification: Previously reported passing; rerun in this task.
- Native Swift verification: Not run; treated as unverified source.
- CocoaPods verification: Not run; `pod` is unavailable on this Linux host.
- iOS simulator build: Not run; `xcodebuild` and an iOS Simulator are unavailable.
- physical iPhone verification: Not run; no iPhone is attached.

## Risks confirmed in the pre-change audit

- `PhotoCaptureCoordinator` coalesces `CaptureStoreError.localizedDescription` with `??`, although `Error.localizedDescription` is non-optional. This is a likely Swift compile error.
- `CaptureStore.persist` removes the source image when thumbnail, metadata, or latest-pointer work fails after its atomic source write. There is no source-safe state or recovery scan, and the flat file layout makes partial records ambiguous.
- Capture IDs are interpolated into paths without UUID validation. A malformed ID can escape the intended capture namespace.
- The JS domain already accepts a nullable thumbnail, but the Codegen event marks `thumbnailUri` as required and native sends an empty-string sentinel.
- Lens discovery exposes both physical and virtual AVFoundation devices as separate buttons. It conflates a physical sensor with a user-facing capture mode; the iPhone Air's 1× and 2× Fusion Main modes demonstrate why these identities must differ.
- Preview/focus orientation and aspect-fill formulas have no pure native tests. The shader's duplicated geometry is not connected to tests.
- Camera teardown uses `sessionQueue.sync` without checking queue ownership, and lifecycle observers are not removed on invalidation or guarded against queued callbacks restarting an invalidated engine.
- Preview pacing is fixed to 30 FPS. Pixel buffers request video-range 8-bit bi-planar YCbCr, but unknown matrices silently fall through to BT.709 coefficients; transfer function, primaries, HDR input, and drawable color space are not explicit.
- The Xcode target advertises iPad as well as iPhone and retains a React Native template bundle identifier. The shared scheme names a `CHEMTests` target that is not present in the project; native tests actually live in a Swift package.
- No macOS workflow exists. `package-lock.json` is present, but `Gemfile.lock` and `Podfile.lock` are absent despite a checked-in Gemfile/Podfile.

## Implementation and evidence from this run

### Implemented

- Corrected the Swift `localizedDescription` misuse, added explicit Xcode target membership for the pure geometry/lens/FPS files, removed the scheme's dangling `CHEMTests` reference (tests run through the Swift package), changed the provisional bundle ID to `com.chem.camera`, and made the target iPhone-only. No signing Team ID was added.
- Matched the ObjC++ event adapter to generated Codegen types. Codegen represents event strings as required `std::string`; missing thumbnail/error values now cross as empty strings and normalize to `null` at the JS domain boundary. The generated iOS component and TurboModule providers were inspected after generation.
- Made capture source persistence write-once per UUID directory: native claims a fresh capture directory, atomically writes and reopens the source, and crosses the source-safe point only after validation. A colliding capture ID cannot overwrite/delete the prior source. Thumbnail, metadata, and latest-pointer errors are recoverable; directory scanning validates source presence, reconstructs sidecars, and repairs the index best-effort. Added deterministic failure injection in Debug and corresponding Swift package tests.
- Split physical camera identity from user-facing capture modes. Physical rear Ultra Wide/Main/Telephoto devices are discovered deterministically; virtual devices are omitted. A Main-sensor 2× crop mode is emitted only when the active format reports sufficient native upscale threshold and maximum zoom. Equal display zooms collapse deterministically to one semantic button. Metadata carries mode ID, physical device ID, mode kind, and device-local zoom. The iPhone Air is explicitly the first hardware-validation target without an iPhone-model branch; see the lens-discovery addendum in [BOOTSTRAP_AUDIT.md](BOOTSTRAP_AUDIT.md) and [ADR-007](DECISIONS/ADR-007-physical-camera-capture-modes.md).
- Extracted orientation/aspect-fill/focus transforms into pure tested geometry; hardened teardown/observer handling and lens-switch rollback; added thermal/capture/renderer-aware display pacing; and configured a neutral SDR/sRGB preview contract with explicit range/matrix support and rejection of unsupported wide-gamut/HDR metadata.
- Added the required macOS workflow at `.github/workflows/ios-foundation-ci.yml`. It runs npm checks and Codegen, Bundler/CocoaPods, workspace/scheme listing, a generic iOS Simulator Debug build with signing disabled, and Swift Package tests. Native logs and the resolved CocoaPods lock are uploaded as artifacts. The workflow has the requested `mobile/**` and `.github/workflows/**` filters.
- Dependency policy is documented in [DEPENDENCY_POLICY.md](DEPENDENCY_POLICY.md). `package-lock.json` and the newly resolved `Gemfile.lock` are present; `Pods/` and generated Codegen outputs remain ignored. `Podfile.lock` is the intended checked-in resolution lock, but could not be generated here and remains a macOS bootstrap follow-up.

### Locally verified

Commands run from `mobile/` unless noted:

| Command/check | Result |
|---|---|
| `node --version` / `npm --version` | Pass: `v20.19.6` / `11.14.1`. |
| `npm ci` | Pass: installed 864 packages; npm reported 7 moderate dependency advisories. |
| `npm run typecheck` | Pass: `tsc --noEmit`, exit 0. |
| `npm test -- --runInBand` | Pass: 2 suites, 7 tests, exit 0. |
| `npm run lint` | Pass: ESLint, exit 0. |
| `npm run codegen:ios` | Pass: generated iOS Codegen artifacts, providers, and podspecs. Expected pre-Pods warnings noted missing generated autolinking output; artifact generation completed successfully. |
| `npx react-native config` | Pass: React Native 0.86 config and safe-area-context iOS podspec/autolinking resolved. |
| `npx react-native bundle --entry-file index.js --platform ios --dev false --bundle-output /tmp/chem-main.jsbundle --assets-dest /tmp/chem-assets` | Pass: Metro wrote the iOS bundle. CLI printed a sandbox `setup_env.sh` EPERM warning and continued. |
| `ruby --version`; `ruby -c ios/Podfile`; `ruby -c Gemfile` | Pass: Ruby `3.0.2p107`; both Ruby files report `Syntax OK`. |
| Bundler lock generation via the installed Bundler 2.2.22 library | Pass: resolved and wrote `Gemfile.lock`. The `bundle` executable itself is absent from PATH. |
| `bundle install --jobs 4 --retry 3` (invoked through Bundler 2.2.22) | Blocked: Bundler fetched dependencies, but local Ruby development headers are missing; `bigdecimal` could not build its native extension (`ruby.h` unavailable). |
| Workflow YAML parse / Prettier check; shared scheme XML and `Info.plist` XML parse | Pass. `actionlint` is not installed. |
| Swift tests | 15 pure-domain tests authored, not run locally (`swift` unavailable). |

### CI-verified / unverified

- GitHub Actions: not triggered or observed. This checkout has no configured Git remote and `gh` is not installed; the new workflow awaits a GitHub runner. No CI result is claimed.
- `pod install`: blocked (`pod` unavailable); `bundle install` is additionally blocked by missing Ruby development headers. No `Podfile.lock` exists yet.
- `xcodebuild -list -workspace CHEM.xcworkspace`: blocked (`xcodebuild` unavailable).
- Generic iOS Simulator Debug build: blocked (`xcodebuild` unavailable). Swift, Objective-C++, and Metal are therefore not build-verified despite the source/Codegen integration fixes.
- Swift package tests: blocked (`swift` unavailable); the 15 tests are authored for macOS CI but not claimed as passing.
- Simulator launch/rendering: unverified. Physical device: unverified; no device attached. In particular, iPhone Air lens capability reporting, 1×/2× same-sensor crop behavior, focus, color, FPS, repeated capture, recovery, and lifecycle behavior remain pending the checklist in [PHYSICAL_DEVICE_VALIDATION.md](PHYSICAL_DEVICE_VALIDATION.md).

### Stop-condition result

The foundation has source-level hardening and a macOS CI gate, but no actual macOS iOS Simulator build result exists yet, and the CocoaPods lock is pending. Do not proceed to the Film Engine or report `READY_FOR_FILM_ENGINE`; current result is **`NOT_READY_FOR_FILM_ENGINE`** pending a green macOS Simulator build and native tests, followed by physical iPhone Air validation before asserting camera behavior.

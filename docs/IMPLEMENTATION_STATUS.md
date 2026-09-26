# Implementation status and evidence

Status labels distinguish source implementation from validation: a native feature can be `implemented` in source while still not being `build-verified` on this host. Do not infer camera hardware behavior from the RN UI or from a successful JavaScript check.

## Current milestone

| Area | Status | Evidence / boundary |
|---|---|---|
| Bare React Native + TypeScript app | implemented, build-verified (JS scope) | RN 0.86.3 in `mobile/`; strict TypeScript, Metro bundle, Jest, and lint pass. iOS binary is not build-verified. |
| CHEM Camera viewfinder UI | implemented, build-verified (JS scope) | React Native components, design tokens, safe-area layout, permission/error states, real-state control presentation, local last-capture modal. No HTML runtime. |
| New Architecture / Codegen contracts | implemented, build-verified (Codegen only) | Fabric component and TurboModule specs generate expected iOS artifacts; CocoaPods/Xcode integration is still blocked. |
| TurboModule permission and latest metadata query | implemented, not build-verified | Objective-C++ adapter calls AVFoundation permission API and native storage query. Requires CocoaPods/Xcode integration. |
| Swift CameraCore, lens/focus/EV/lifecycle | implemented, not build-verified | Source owners and serial queue boundaries exist; AVFoundation behavior requires iOS build/device checks. |
| `AVCaptureVideoDataOutput` → neutral Metal preview | implemented, not build-verified | Native latest-frame renderer and Fabric host exist, with one GPU command in flight and a latest-frame slot. Color/orientation/pacing still require visual iPhone verification. |
| Still capture and durable local storage | implemented, not build-verified | `AVCapturePhotoOutput`, native JPEG source, thumbnail, metadata, and latest pointer; success follows writes. Persistence tests are authored but not run on this host. |
| Last-capture restore and React Native thumbnail | implemented, build-verified (JS only) | Native latest metadata query is wired to launch state; local file URI presentation exists. Native result not runtime-verified. |
| React Native camera diagnostics | implemented, build-verified (JS scope) | `cameraLogger.ts` is dev-only and excludes pixel data/file paths. |
| Neutral-preview and inactive-film copy | placeholder | Explicitly states the film engine is inactive; no film effect or fake runtime telemetry. |
| Android host project | scaffolded, deferred | Generated React Native shell only; no Android camera implementation is claimed. |
| Swift package unit tests | implemented, blocked | `swift test` cannot run because Swift/Xcode tooling is absent. |
| iOS simulator launch/build | blocked; simulator-verified: no | Linux host has no Xcode, CocoaPods, or simulator. |
| Physical-device validation | blocked; device-verified: no | No iPhone attached; checklist remains entirely unchecked. |

## Deferred (out of this task)

Production Film Engine, DAY 200, SKIN 400, NIGHT 800T, grain/bloom/halation/LUT, Lab/redevelopment, Shelf, Photos import/export, RAW/ProRAW, calibration, full Pro Mode/manual ISO/shutter, flash, video, rolls, sharing, batch development, StoreKit, backend, authentication, cloud sync, and generative AI. Android camera behavior is deferred; Android only has the generated app shell and iOS-only presentation.

## Validation log

“Build-verified” below applies only to the named host-level scope. Missing iOS toolchain checks are attempted and recorded as blocked, not source failures.

| Command/check | Result |
|---|---|
| `node --version` / `npm --version` | Pass: `v20.19.6` / `11.14.1`. |
| `ruby --version` | Pass: `ruby 3.0.2p107`. |
| `yarn --version`, `pnpm --version`, `bundle --version`, `pod --version`, `xcodebuild -version`, `swift --version`, `clang --version` | Blocked/unavailable: each executable is absent. |
| `npm run typecheck` | Pass: `tsc --noEmit`, exit 0. |
| `npm test -- --runInBand` | Pass: 2 suites, 6 tests, exit 0. |
| `npm run lint` | Pass: ESLint, exit 0. |
| `npx react-native bundle --entry-file index.js --platform ios --dev false --bundle-output /tmp/chem-main.jsbundle --assets-dest /tmp/chem-assets` | Pass: Metro wrote the iOS JS bundle to `/tmp/chem-main.jsbundle`, exit 0. CLI printed a sandbox `setup_env.sh` EPERM warning, then continued and completed. |
| `npx react-native config` | Pass: exit 0; RN 0.86 config resolved and `react-native-safe-area-context` autolinking discovered. |
| `npm run codegen:ios` | Pass: exit 0; Fabric props/events/commands, TurboModule specs, component/module providers, and podspecs generated under ignored `build/generated/ios`. |
| `pod install` | Blocked: `/bin/bash: pod: command not found`. |
| `xcodebuild -list -project ios/CHEM.xcodeproj` | Blocked: `/bin/bash: xcodebuild: command not found`. |
| `xcodebuild -project ios/CHEM.xcodeproj -scheme CHEM -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/chem-derived CODE_SIGNING_ALLOWED=NO build` | Blocked: `/bin/bash: xcodebuild: command not found`. |
| `swift test --package-path ios` | Blocked: `/bin/bash: swift: command not found`. |
| Simulator/device behavior | Not verified: no simulator or iPhone; see [physical checklist](PHYSICAL_DEVICE_VALIDATION.md). |

## Required physical checklist

The items in [PHYSICAL_DEVICE_VALIDATION.md](PHYSICAL_DEVICE_VALIDATION.md) remain unchecked unless run on a physical iPhone. Simulator evidence is not device evidence.

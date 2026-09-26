# CHEM bootstrap audit

Audit performed before implementation from repository contents and the start prompt.

## Existing repository

The root contains the CHEM PRD, the 3,932-line original implementation plan, the implementation prompt, the optical/emulsion design tokens, four HTML screen references with screenshots, a separate optical mark reference, four photographic sample images, and a React Native/iOS roadmap under `docs/implementation-plans/`. The roadmap says it was written on 2026-09-26 and records that implementation had not started. There is no application source, package manifest, Xcode project, native Swift/Metal code, or test suite. The HTML files are design references with remote assets, fabricated telemetry, and demo-only interactions; they are not runtime application code.

The `.git` entry is an empty directory rather than Git metadata: `git status --short --branch` fails with “not a git repository”. No tracked/untracked diff is available to establish asset history. All supplied PRD, plan, HTML, screenshot, and image assets will remain in place.

## Environment observed

| Tool | Observed |
|---|---|
| Host Node.js | `v20.19.6` |
| npm | `11.14.1` |
| Yarn | unavailable |
| pnpm | unavailable |
| Ruby | `3.0.2p107` |
| Bundler | unavailable |
| CocoaPods | unavailable |
| Xcode / `xcodebuild` | unavailable |
| Swift | unavailable |
| clang | unavailable |
| Host | Linux; no iOS simulator or physical iPhone exposed |

The generated React Native 0.86.3 project pins React `19.2.3`, CLI `20.1.0`, and declares Node.js `>=22.11.0`. The published RN 0.86.3 packages declare Node `^20.19.4 || ^22.13.0 || ^24.3.0 || >=25.0.0`, so the observed host Node `20.19.6` is supported. The generated app-level engine range is broader/stricter than its actual dependencies; `mobile/package.json` will be aligned to the published package engines and `.nvmrc` will use `20.19.6`. A temporary Node `22.13.0` was also used for a clean dependency refresh. React Native 0.87 is the newer active stable line, but has a newly-default strict TypeScript API migration. I selected 0.86.3, also active stable, to use the more mature New Architecture/Codegen line for the first native integration. npm `11.14.1` and the official Community CLI template are used. This is a deliberate, supported version choice, not a claim that 0.86 is the newest release. Sources: [React Native 0.87 release notes](https://reactnative.dev/blog/2026/08/11/react-native-0.87), [React Native release status](https://reactnative.dev/releases/overview), [React Native 0.86 version API example](https://reactnative.dev/docs/0.86/reactnativeversion).

## Implementation assumptions and intended layout

The start prompt takes precedence over the older SwiftUI wording in the original engineering plan and over the roadmap's earlier `apps/mobile` suggestion. The app will live at `mobile/` as requested by the start prompt; design and planning assets stay at the root. The app will launch into the Camera screen. The interface will be translated with React Native primitives and semantic tokens; system fonts replace Inter/JetBrains Mono until licensed local files are supplied. No HTML, WebView, Expo Camera, VisionCamera, camera SDK, or JavaScript frame processing will be introduced.

Planned project areas:

```text
mobile/
├── src/app/
├── src/design-system/
├── src/features/camera/
├── src/domain/
├── src/native/
├── specs/
├── ios/CHEM/CameraCore/
├── ios/CHEM/Imaging/Preview/
├── ios/CHEM/Storage/
├── ios/CHEM/ReactNative/
└── __tests__/
docs/
├── BOOTSTRAP_AUDIT.md
├── SYSTEM_ARCHITECTURE.md
├── REACT_NATIVE_NATIVE_BOUNDARY.md
├── MODULE_CONTRACTS.md
├── IMPLEMENTATION_STATUS.md
└── DECISIONS/
```

React Native owns camera-screen composition, permission/error presentation, controls, selected UI state, and the last-capture thumbnail. The TurboModule exposes typed permission and non-view storage queries. A Codegen Fabric component hosts the native preview view and exposes typed camera state/events/commands. Swift CameraCore is independent of React Native and has the sole serialized owner of `AVCaptureSession`; AVFoundation owns device discovery, focus/exposure, EV, and still capture. Preview frames pass through `AVCaptureVideoDataOutput` into a native Metal renderer and never enter JavaScript. Swift storage writes the source below Application Support and creates the thumbnail before any capture-success receipt/event is emitted.

Only the Camera Viewfinder is in this task. Film identity is a documented placeholder; no film look, RAW, Pro controls, live filter, telemetry values without native measurements, Shelf, or Lab behavior will be claimed as implemented. The screenshots do not establish rights/provenance for the separate scene images, so they will not be bundled as production assets or used to fake a camera preview.

## Environment boundary

The official CLI can create a bare iOS/Android host project on this Linux machine, and JavaScript tooling can be checked here once dependencies are installed. Native Swift/Metal compilation, CocoaPods integration, simulator launch, AVFoundation validation, and device tests require a macOS/Xcode toolchain and a physical iPhone where appropriate. Those results will be recorded as blocked by the current host, not as passed. No signing Team ID will be added.

## Resulting implementation layout

The application is now bootstrapped under `mobile/`. The `App.tsx` entry launches the Camera viewfinder; reusable UI and camera state live under `src/design-system/` and `src/features/camera/`. React Native Codegen specs live in `src/specs/` (rather than `src/native/`) because Codegen requires the conventional `Native...` and `...NativeComponent` names and a single configured `jsSrcsDir`. No separate `src/app/`, `src/domain/`, or `src/native/` layer was needed for this single-screen milestone; camera domain state is localized in `camera.types.ts` and native contracts in the generated-spec source files.

The sole non-template runtime dependency is `react-native-safe-area-context` (`^5.5.2`, lockfile-resolved `5.10.0`) for notch/home-indicator insets. There is no navigation or state-management dependency. Test infrastructure follows the React Native template (Jest `29.7.0`, React Test Renderer `19.2.3`, TypeScript `5.9.3`, ESLint `8.57.1`). System sans and monospaced fonts remain intentional temporary substitutions; font binaries were not downloaded.

The iOS implementation is grouped under `mobile/ios/CHEM/CameraCore`, `Imaging/Preview`, `Storage`, and `ReactNative`. Handwritten source includes the TurboModule adapter and Fabric component-view glue; React Native Codegen output is generated under ignored build output and is not hand-edited or committed. `mobile/ios/Package.swift` provides a Foundation-only native-domain test target for logic that does not require AVFoundation hardware.

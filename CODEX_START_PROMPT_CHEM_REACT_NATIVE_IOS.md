# CODEX MASTER PROMPT — CHEM React Native iOS Bootstrap + Native Camera Foundation

You are the lead engineer starting implementation of **CHEM**, an iPhone-first film camera application.

The product UI must be implemented in **React Native + TypeScript**, based on the existing HTML/CSS designs in this repository.

The camera and realtime imaging path must remain **native iOS**, implemented with **Swift + AVFoundation + Metal**, and exposed to React Native through the React Native New Architecture.

This is a hybrid architecture by design:

```text
React Native / TypeScript
    UI, product state, navigation, design system
                 │
                 │ typed Codegen boundary
                 ▼
Fabric Native Component + Turbo Native Module
                 │
                 ▼
Swift iOS Camera / Imaging Core
    AVFoundation + Metal + durable capture storage
```

The JavaScript thread must NEVER receive or process live camera frames.

Your goal in this first task is to bootstrap the real application and implement the first reliable camera foundation.

Do NOT attempt to implement the complete CHEM application in one run.

---

# 1. Audit the repository before touching code

Read the following files completely before implementation:

1. `CHEM_iOS_Core_Features_Implementation_Plan_v1.0 (1).md`
2. `chem_prd_v1.0.md`
3. `chem_optical_emulsion_system/DESIGN.md`
4. `chem_camera_viewfinder/code.html`
5. `chem_camera_viewfinder/screen.png`
6. `chem_pro_mode_viewfinder/code.html`
7. `chem_pro_mode_viewfinder/screen.png`
8. `chem_film_shelf/code.html`
9. `chem_film_shelf/screen.png`
10. `chem_darkroom_lab/code.html`
11. `chem_darkroom_lab/screen.png`

Inspect the complete repository tree as well.

Before coding, write a short repository audit describing:

- what currently exists;
- what is design/spec only;
- whether a React Native project already exists;
- whether Node/npm/yarn/pnpm, Ruby/Bundler, CocoaPods and Xcode are available;
- which implementation assumptions you are making.

Do not delete, overwrite, or restructure the design/specification assets during this first task.

If documents conflict, use this precedence:

1. This prompt for implementation technology and current task scope.
2. `CHEM_iOS_Core_Features_Implementation_Plan...md` for architecture and implementation order.
3. `chem_prd_v1.0.md` for product requirements.
4. `DESIGN.md` for design language.
5. `screen.png` for visual target.
6. `code.html` for layout/interaction details.

---

# 2. Critical correction to the previous architecture

The UI is NOT SwiftUI.

The product application layer is:

> **React Native + TypeScript**

The HTML/CSS screens in the repository must be **manually translated into React Native components and styles**.

Do NOT:

- use `WKWebView`;
- use `react-native-webview`;
- load the existing HTML directly;
- use React Native Web as the production iPhone UI;
- keep Tailwind classes and render them through a browser;
- build a web app and place it inside the iOS application;
- send camera frames over the React Native bridge;
- perform image filtering frame-by-frame in JavaScript;
- perform camera capture through a JS-only implementation.

The HTML files are the source design specification only.

---

# 3. React Native architecture requirement

Use a **bare React Native application**, not Expo Managed Workflow.

Use the React Native **New Architecture**.

The implementation should be based on:

- React Native;
- TypeScript;
- Fabric Native Components;
- Turbo Native Modules;
- React Native Codegen;
- native iOS Swift implementation;
- the minimum Objective-C / Objective-C++ glue required by React Native Codegen/interoperability.

Do not deliberately downgrade to the Legacy Bridge architecture just because it appears easier.

If the repository contains no React Native application, bootstrap one using the official React Native Community CLI and the stable React Native version available/appropriate in the environment.

Record the exact versions selected in documentation.

Do not blindly pin a version copied from this prompt.

Do not use Expo Camera for the core camera implementation.

Do not use VisionCamera in this first milestone.

Do not use a third-party image-filter/camera SDK.

The purpose of this milestone is to own the camera and rendering architecture directly.

---

# 4. Repository layout

Because the existing repository contains product/design artifacts at the root, avoid destructive bootstrapping.

Preferred structure:

```text
repo-root/
├── existing PRD/design assets...
├── docs/
│
└── mobile/
    ├── package.json
    ├── tsconfig.json
    ├── metro.config.js
    ├── babel.config.js
    ├── src/
    │   ├── app/
    │   ├── design-system/
    │   ├── features/
    │   ├── domain/
    │   ├── native/
    │   └── platform/
    │
    ├── ios/
    │   └── CHEM/
    │       ├── CameraCore/
    │       ├── Imaging/
    │       ├── Storage/
    │       └── ReactNative/
    │
    └── __tests__/
```

If repository constraints make another layout materially better, explain it first in `docs/BOOTSTRAP_AUDIT.md`.

Do not relocate the supplied HTML/screenshots in this run.

---

# 5. Product context

CHEM is a **camera-first film photography app**.

It is not:

- a generic Lightroom replacement;
- an Instagram-like social app;
- a toy retro-camera collection;
- an HTML wrapper;
- an AI image generator.

The long-term product should eventually provide:

```text
camera
 → deterministic film renderer
 → durable digital negative
 → Lab re-development
 → Gallery processing
```

But THIS Codex task is intentionally narrower.

Core principles that must already influence the architecture:

- camera first;
- reliability before effects;
- native imaging path;
- preserve source before expensive processing;
- future preview and final renderer should share semantics;
- no mandatory network;
- no account required for core camera;
- product complexity belongs below the UI;
- never claim an unimplemented feature through fake UI state.

---

# 6. Scope of THIS Codex task

Implement:

## Milestone 0
React Native application foundation.

## Milestone 1
Reliable native iOS camera foundation.

## Minimal Milestone 2 infrastructure
A Metal-backed **neutral/pass-through live preview** exposed as a React Native Fabric Native Component.

At the end of this task, the application should support this real flow:

```text
Launch React Native CHEM app
        ↓
React Native camera UI
        ↓
Camera permission
        ↓
Native AVFoundation camera session
        ↓
AVCaptureVideoDataOutput
        ↓
Native Metal renderer
        ↓
Fabric native camera preview component
        ↓
Real lens discovery/switching
        ↓
Tap focus/expose
        ↓
EV compensation
        ↓
Shutter
        ↓
AVCapturePhotoOutput
        ↓
Durable local still image
        ↓
Capture event sent to React Native
        ↓
Last-frame thumbnail shown in React Native UI
```

The live preview is visually neutral in this task.

Do not implement production film color.

---

# 7. Explicit NON-SCOPE

Do NOT implement yet:

- production CHEM Film Engine;
- DAY 200;
- SKIN 400;
- NIGHT 800T;
- grain;
- bloom;
- halation;
- 3D LUT film pipeline;
- scene-aware processing;
- Lab;
- re-development;
- Photos import;
- Photos export;
- RAW;
- ProRAW;
- device calibration;
- full Pro Mode;
- Rolls;
- recipe sharing;
- batch development;
- StoreKit paywall;
- backend;
- authentication;
- cloud sync;
- video;
- generative AI.

You may define narrowly scoped future-facing interfaces when necessary, but do not fill them with fake implementations.

STOP once the native camera foundation defined in this document is working as far as the environment permits.

---

# 8. HTML → React Native translation

The supplied HTML is the visual implementation reference.

Translate it into React Native manually.

For every visible Camera-screen element:

1. inspect the HTML structure;
2. inspect computed/intended CSS values;
3. inspect the screenshot;
4. recreate using React Native primitives;
5. use native app state, not static demo values.

Use:

- `View`;
- `Text`;
- `Pressable`;
- `Image`;
- `StyleSheet`;
- native animations where useful;
- safe-area handling.

Do not mechanically convert DOM tags 1:1.

Preserve the design intent rather than browser implementation details.

---

# 9. Design system

Create a React Native design system based on:

`chem_optical_emulsion_system/DESIGN.md`

At minimum include:

```text
src/design-system/
├── colors.ts
├── spacing.ts
├── radius.ts
├── typography.ts
├── motion.ts
└── components/
```

Use semantic tokens.

Example:

```ts
export const colors = {
  background: ...,
  surface: ...,
  foreground: ...,
  muted: ...,
  amber: ...,
  critical: ...,
  success: ...,
} as const;
```

Do not scatter arbitrary hex values and magic paddings through screen code.

---

# 10. Fonts

The design references fonts such as Inter and JetBrains Mono.

Do not download font binaries automatically.

Do not introduce random font files.

For the first engineering milestone:

- use iOS system font for sans-serif roles;
- use system monospaced font for technical/readout roles;
- document this as a temporary substitution.

Do not block camera engineering on exact brand fonts.

---

# 11. Icons

Do not depend on remote Google Material Symbol fonts at runtime.

Preferred order:

1. locally bundled design SVG/assets if already available;
2. iOS-native semantic symbols through a small native wrapper if needed;
3. a justified lightweight local icon solution.

Do not add a large UI dependency only for three icons.

Do not use emoji as product icons.

---

# 12. React Native app state boundaries

React Native owns:

- screen composition;
- Camera screen product state;
- selected UI state;
- controls;
- last-capture thumbnail presentation;
- error presentation;
- eventual navigation.

Native iOS owns:

- `AVCaptureSession`;
- camera devices;
- preview video frames;
- Metal textures;
- Metal draw loop;
- still capture;
- focus/exposure hardware calls;
- EV hardware calls;
- durable source file writing;
- camera interruption recovery.

Never mirror live frames into JS.

---

# 13. Native camera architecture

Create a reusable native camera engine independent of React Native.

Suggested native structure:

```text
ios/CHEM/
├── CameraCore/
│   ├── CHEMCameraEngine.swift
│   ├── CameraSessionController.swift
│   ├── CameraDeviceCatalog.swift
│   ├── PhotoCaptureCoordinator.swift
│   ├── CameraFocusController.swift
│   ├── CameraExposureController.swift
│   └── CameraTypes.swift
│
├── Imaging/
│   └── Preview/
│       ├── CHEMMetalPreviewView.swift
│       ├── MetalPreviewRenderer.swift
│       └── Shaders.metal
│
├── Storage/
│   └── CaptureStore.swift
│
└── ReactNative/
    ├── camera native component integration
    ├── camera permission TurboModule
    └── minimal ObjC/ObjC++ glue if required
```

Names may change, but responsibilities must remain separated.

The React Native wrapper must be thin.

Do not put camera implementation logic directly in the Fabric component class.

---

# 14. Native camera engine invariants

The native camera layer must enforce:

### INV-CAM-01
Only one owner mutates `AVCaptureSession` topology.

### INV-CAM-02
Session configuration is serialized.

### INV-CAM-03
Still photos are captured with `AVCapturePhotoOutput`.

### INV-CAM-04
Preview uses `AVCaptureVideoDataOutput`.

### INV-CAM-05
JavaScript never receives raw preview frames.

### INV-CAM-06
Source image is written natively before capture success is emitted to JS.

### INV-CAM-07
A React Native re-render must not recreate the physical camera session unnecessarily.

### INV-CAM-08
Unmounting or backgrounding the screen must not leave camera resources in a broken state.

---

# 15. Fabric Native Component

Implement the camera preview as a **Fabric Native Component**.

The TypeScript Codegen spec should follow current React Native naming conventions for native components.

Create a component conceptually similar to:

```text
CHEMCameraNativeComponent
```

It must render a native iOS view containing the Metal preview.

The component should expose typed props/events/commands.

Do not pass camera frames through props/events.

---

# 16. Suggested Fabric component API

Exact Codegen types may need adjustment for React Native compatibility.

Conceptually support props such as:

```ts
type CameraPreviewProps = {
  active: boolean;
};
```

Events should include structured payloads for:

```text
onCameraStateChanged
onAvailableLensesChanged
onActiveLensChanged
onCaptureCompleted
onCaptureFailed
onExposureChanged
onTelemetryChanged
```

Commands should conceptually include:

```text
start
stop
selectLens
focusAndExpose
setExposureCompensation
capture
setFlashMode (optional)
```

If current Fabric command ergonomics make a slightly different interface cleaner, use it and document the decision.

Do not use an untyped DeviceEventEmitter-based API for the core camera contract when Codegen events can model it.

---

# 17. Turbo Native Module

Use a Turbo Native Module only for non-view native camera functionality that should exist independent of a mounted camera preview.

At minimum, camera permission is a good candidate.

Conceptual TypeScript contract:

```ts
export interface Spec extends TurboModule {
  getCameraPermissionStatus(): Promise<string>;
  requestCameraPermission(): Promise<string>;
}
```

Do not duplicate session state between the TurboModule and Fabric component.

One camera engine must remain the source of truth for an active session.

If permission handling is cleaner inside the component for this milestone, keep the TurboModule minimal, but preserve a typed architecture suitable for future nonvisual APIs.

---

# 18. Swift and React Native interoperability

Prefer Swift for iOS implementation.

React Native New Architecture interop may require a small Objective-C or Objective-C++ adapter generated/implemented around Codegen interfaces.

That is acceptable.

Rules:

- keep ObjC++ glue minimal;
- do not move camera logic into ObjC++ merely because the wrapper needs it;
- Swift types own camera behavior;
- Codegen contract remains typed;
- document which files are generated versus handwritten;
- do not manually edit generated Codegen output.

---

# 19. Camera permission behavior

Add correct iOS privacy usage description.

React Native Camera screen states:

```text
unknown/loading
requesting
authorized
denied
restricted
cameraFailed
running
interrupted
```

Behavior:

### Authorized
Mount/activate camera.

### Not determined
Show CHEM permission CTA and request permission through typed native API.

### Denied/restricted
Show a CHEM-designed state with:
- explanation;
- Open Settings action where available.

Do not show a permanent black viewfinder.

Do not repeatedly prompt permission.

---

# 20. AVFoundation session implementation

Use:

- `AVCaptureSession`;
- camera device input;
- `AVCaptureVideoDataOutput`;
- `AVCapturePhotoOutput`.

The session controller must own topology.

Serialize:

- `beginConfiguration`;
- input changes;
- output changes;
- lens switching.

Do not mutate the session from random callback queues.

Use Swift concurrency/actor or a clearly controlled serial execution mechanism.

Document actor/queue ownership.

---

# 21. Live preview pipeline

Required pipeline:

```text
AVCaptureVideoDataOutput
   ↓
CMSampleBuffer
   ↓
CVPixelBuffer
   ↓
CVMetalTextureCache
   ↓
MTLTexture
   ↓
MetalPreviewRenderer
   ↓
MTKView
   ↓
Fabric Native Component
   ↓
React Native layout
```

Do NOT:

```text
CVPixelBuffer
 → UIImage
 → Base64
 → JavaScript
 → React Native Image
```

No frame should cross the JS/native boundary.

---

# 22. Metal renderer for this milestone

Implement a simple neutral renderer.

Required characteristics:

- persistent `MTLDevice`;
- persistent `MTLCommandQueue`;
- cached pipeline state;
- reused texture cache;
- no pipeline compilation per frame;
- correct image orientation;
- correct aspect fill;
- correct mirroring behavior if relevant;
- latest-frame behavior under backpressure.

A visually correct YCbCr/RGB conversion is part of the task if camera pixel format requires it.

Do not add artistic film processing yet.

---

# 23. Preview backpressure

A camera cannot queue every preview frame if rendering falls behind.

Implement:

> newest useful frame wins.

If renderer is busy:
- discard stale preview work;
- do not create an unbounded queue;
- do not let latency accumulate over seconds.

Camera control and shutter interaction must remain responsive.

---

# 24. Camera lifecycle

Native camera layer must observe and handle:

- app active/inactive;
- app foreground/background;
- capture session interruptions;
- AVFoundation runtime errors;
- media services reset where appropriate.

JS `AppState` may inform UI state, but native camera correctness must not rely exclusively on JS lifecycle timing.

Emit typed state events back to React Native.

---

# 25. Lens discovery

Discover actual rear camera devices.

Do not assume every iPhone supports:

- `.5x`;
- `1x`;
- `2x`;
- `5x`.

Create a native domain representation:

```swift
struct CameraLens {
    let id: String
    let role: LensRole
    let displayZoom: String
    let deviceUniqueID: String
}
```

Send only serializable domain data to React Native.

Do not expose raw `AVCaptureDevice` objects.

---

# 26. Lens selector in React Native

Translate the lens control from the supplied HTML into a React Native component.

The available buttons come from the native `onAvailableLensesChanged` event.

React Native should never fabricate unavailable lenses.

Interaction:

```text
Press lens
  ↓
send selectLens command
  ↓
native session changes
  ↓
native emits active lens
  ↓
React Native updates selected state
```

Do not optimistically claim selection succeeded before native confirmation unless transient UI clearly represents pending state.

---

# 27. Focus and exposure

Implement tap-to-focus/expose.

Recommended interaction path:

```text
React Native touch coordinates
   ↓
normalize relative to camera preview bounds
   ↓
Fabric native command with normalized x/y
   ↓
native preview aspect transform
   ↓
AVFoundation point
   ↓
focus/expose
```

Be careful:

The visible preview uses aspect-fill, so naïve `x / width, y / height` may be incorrect.

The native layer knows:
- source aspect ratio;
- crop;
- orientation.

Perform the final camera coordinate conversion natively.

React Native owns the focus indicator animation.

Native sends success/state only if useful.

---

# 28. EV compensation

Implement capture exposure compensation.

React Native provides the control.

Native clamps to actual hardware range.

Use clear naming:

```text
captureExposureCompensationEV
```

Do not call it development exposure.

Do not implement fake EV by applying brightness in the preview shader.

EV must control the camera exposure target where AVFoundation supports it.

---

# 29. Runtime telemetry shown in UI

The HTML camera mockup contains values like ISO and shutter speed.

For this implementation:

Only display values if they are derived from real native camera state.

Native may emit low-frequency telemetry events such as:

```json
{
  "iso": 80,
  "shutterSeconds": 0.00625,
  "lensDisplay": "1×",
  "exposureCompensationEV": 0
}
```

Do not emit telemetry every camera frame.

Throttle to a reasonable frequency.

Do not hardcode demo `ISO 400` / `1/160s` and present it as real.

---

# 30. Film UI state in this milestone

The design contains film identity such as `STREET 400`.

Production film rendering is NOT implemented yet.

For the Camera UI:
- the film badge may exist as a clearly temporary/static design state;
- use one explicit placeholder film identity;
- add a code comment / implementation-status documentation that artistic film rendering is not active;
- do not call the native neutral preview a film simulation.

Do not build Film Shelf functionality in this task.

---

# 31. Pro UI state in this milestone

The design may include a `PRO` affordance.

Full Pro Mode is out of scope.

Either:
- show it disabled/inactive;
- or hide it in the functional first build.

Do not expose manual ISO/shutter controls without native implementation.

---

# 32. RAW UI state

RAW and ProRAW are out of scope.

Do not display `RAW+CHEM` as though enabled.

If preserving the visual design requires the element:
- visibly mark it unavailable/dev-only;
- or omit it.

Truthfulness is more important than screenshot imitation.

---

# 33. Shutter

The React Native shutter control must:

1. respond immediately to press;
2. trigger haptic if native haptic service exists;
3. issue a typed Fabric command;
4. not wait for animation;
5. show capture-in-progress state only as needed.

Native does:

```text
AVCapturePhotoOutput capture
   ↓
receive processed still
   ↓
persist durable source
   ↓
generate/prepare thumbnail
   ↓
emit captureCompleted
```

Capture success must NOT be emitted before durable source write completes.

---

# 34. Durable capture storage

Implement natively on iOS.

This is not yet the full final CHEM Frame repository, but it must be forward-compatible.

Store under application-controlled durable storage such as:

```text
Application Support/
  CHEM/
    Captures/
      <UUID>/
        source.heic
        thumbnail.jpg
        metadata.json
```

Exact format may vary.

Rules:

- UUID-based IDs;
- never use `Caches` as the only location for source;
- write atomically where practical;
- if source write fails, emit capture failure rather than success;
- source file must survive app restart.

---

# 35. Capture event contract

Native capture completion event should return serializable metadata, not image bytes.

Conceptually:

```ts
type CaptureCompletedEvent = {
  id: string;
  sourceUri: string;
  thumbnailUri: string | null;
  width: number;
  height: number;
  capturedAt: string;
  lensId: string;
};
```

Do not Base64-encode still images into events.

---

# 36. Last-frame thumbnail

React Native Camera screen must show the most recent successful captured thumbnail.

Do not keep the full captured image in JS memory.

Use a local file URI.

Tap can open a simple React Native capture preview screen or lightweight modal.

Do not implement Darkroom Lab yet.

---

# 37. React Native Camera feature structure

Recommended:

```text
src/features/camera/
├── CameraScreen.tsx
├── CameraViewModel.ts / useCameraController.ts
├── camera.types.ts
├── camera.reducer.ts
├── components/
│   ├── ShutterButton.tsx
│   ├── LensSelector.tsx
│   ├── CameraTopBar.tsx
│   ├── CameraTelemetry.tsx
│   ├── FocusIndicator.tsx
│   ├── ExposureControl.tsx
│   └── LastCaptureButton.tsx
└── __tests__/
```

Do not put all JSX and state into one giant screen file.

---

# 38. Native specs directory

Create a clear typed native boundary, for example:

```text
src/native/
├── NativeCHEMCamera.ts
├── CHEMCameraNativeComponent.ts
├── cameraNative.types.ts
└── index.ts
```

Follow React Native Codegen naming requirements.

Remember:

- TurboModule specs use the expected `Native...` naming convention.
- Fabric Native Component specs use the expected `...NativeComponent` convention.

Configure `codegenConfig` correctly.

Do not commit hand-edited generated output unless the React Native template/toolchain convention requires generated files in a specific location.

---

# 39. React state management

Do not add Redux, MobX, Zustand, Recoil, or another state-management library in this milestone.

The Camera feature is currently small enough for:

- hooks;
- reducer;
- context where necessary.

Add a global state library only when product requirements justify it.

---

# 40. Navigation

Do not add a heavy navigation architecture solely for one Camera screen.

If the existing UI implementation requires a second temporary preview screen, use the simplest appropriate solution.

If React Navigation is already present due repository/bootstrap choices, use it cleanly.

Otherwise do not add it yet unless necessary.

The app should launch straight into Camera.

---

# 41. JavaScript performance rules

Strict rules:

- no preview frames in JS;
- no per-frame setState;
- no per-frame telemetry events;
- no Base64 image transport;
- no image filters in JS;
- no JSON messages at camera FPS;
- no JS loop that controls Metal rendering cadence.

React Native exists around the camera, not inside its pixel pipeline.

---

# 42. Native performance instrumentation

Create debug-only native metrics:

- preview FPS;
- dropped preview frames;
- render frame time where practical;
- active lens;
- camera lifecycle state.

Expose only low-frequency aggregate metrics to React Native if needed for a debug HUD.

Do not emit 60 events/sec.

Add a dev-only performance overlay toggle.

---

# 43. Haptics

Shutter should feel tactile.

Preferred:
- native iOS haptic exposed via the camera native component or small native utility;
- or a minimal appropriate React Native-native haptic implementation.

Do not add a large dependency solely for one haptic.

Do not let haptic failure block capture.

---

# 44. Flash

Flash is optional in this first pass.

If implementing:
- off;
- auto;
- on;
- translate to `AVCapturePhotoSettings`.

If it risks core stability:
- leave button inactive or omit it;
- document deferred implementation.

Do not fake flash with screen animation.

---

# 45. Error model

Native errors should be typed/categorized.

Suggested categories:

```text
permissionDenied
sessionConfigurationFailed
cameraUnavailable
lensSwitchFailed
focusFailed
exposureFailed
captureFailed
sourcePersistenceFailed
rendererFailed
```

Bridge them as stable error codes plus safe message.

React Native maps them into user-facing copy.

Do not expose raw NSError strings directly to users.

---

# 46. Logging

Use native `OSLog` for native camera/imaging/storage.

Use a small JS logging wrapper for React Native feature logs.

Each capture has a UUID.

Native lifecycle example:

```text
capture=<uuid> requested
capture=<uuid> sensor_received
capture=<uuid> source_write_started
capture=<uuid> source_persisted
capture=<uuid> event_emitted
```

Do not log:
- pixels;
- location;
- sensitive file contents.

---

# 47. React Native test requirements

Add meaningful TypeScript tests for:

- camera reducer/state transitions;
- permission state rendering logic;
- available-lens mapping into UI;
- selected-lens confirmation behavior;
- capture success updates last thumbnail;
- capture failure does not replace valid last capture;
- EV UI clamping before native call if applicable.

Do not create placeholder tests.

Use the testing setup appropriate to the React Native version chosen.

---

# 48. Native unit tests

Add iOS tests for non-hardware logic where feasible:

- capture path generation;
- durable file write/read;
- EV clamping;
- lens domain mapping;
- capture metadata encoding;
- state machine transitions if separated from AVFoundation.

Physical camera behavior still requires real hardware.

Do not pretend simulator tests validate AVFoundation camera correctness.

---

# 49. Simulator behavior

On simulator:

- application must launch;
- React Native UI must render;
- no crash from missing camera;
- show a CHEM-designed unavailable/simulator state.

Do not attempt to fake a real camera and report it as working.

A local static preview asset may be used ONLY in development preview mode and must be clearly separated from production native camera state.

---

# 50. Physical-device validation checklist

Create this checklist in docs and mark only what was actually tested:

```text
[ ] First camera permission
[ ] Denied permission state
[ ] Camera starts
[ ] Background / foreground resume
[ ] Lens discovery
[ ] Lens switching
[ ] Tap focus
[ ] Tap exposure
[ ] EV compensation
[ ] 20 repeated captures
[ ] Durable source survives restart
[ ] Last thumbnail updates
[ ] Portrait
[ ] Landscape left
[ ] Landscape right
[ ] Native preview remains stable
[ ] Interruption recovery
```

Do not mark hardware tests as passed unless they were run on a device.

---

# 51. Documentation required

Create:

```text
docs/
├── BOOTSTRAP_AUDIT.md
├── SYSTEM_ARCHITECTURE.md
├── REACT_NATIVE_NATIVE_BOUNDARY.md
├── MODULE_CONTRACTS.md
├── IMPLEMENTATION_STATUS.md
└── DECISIONS/
    ├── ADR-001-react-native-ui.md
    ├── ADR-002-react-native-new-architecture.md
    ├── ADR-003-native-avfoundation-camera.md
    ├── ADR-004-fabric-metal-preview.md
    ├── ADR-005-native-capture-storage.md
    └── ADR-006-no-live-frames-in-js.md
```

---

# 52. `REACT_NATIVE_NATIVE_BOUNDARY.md`

This document is especially important.

Include a table:

| Responsibility | React Native | Native iOS |
|---|---:|---:|
| Camera UI | ✅ | |
| Lens buttons | ✅ | |
| Focus indicator UI | ✅ | |
| Camera session | | ✅ |
| Device discovery | | ✅ |
| Preview frames | | ✅ |
| Metal rendering | | ✅ |
| Still capture | | ✅ |
| Source persistence | | ✅ |
| Live film engine (future) | | ✅ |
| Lab UI (future) | ✅ | |
| Full-res render (future) | | ✅ |

Also document every event/command crossing the native boundary.

---

# 53. Build validation

Run and report the exact commands used.

Expected categories:

```text
node --version
npm/yarn/pnpm --version
bundle --version
pod --version
xcodebuild -version
```

React Native:

```text
install dependencies
run Codegen as appropriate
install iOS pods
TypeScript check
tests
```

iOS:

```text
xcodebuild -list
xcodebuild ... simulator build
```

Use the actual scheme/workspace generated.

Do not put a personal Apple signing Team ID into the repository.

If build fails because the environment lacks:
- Xcode;
- CocoaPods;
- simulator;
- signing;

separate environmental blockers from source errors.

Fix source errors that are in scope.

---

# 54. Package policy

Minimize dependencies.

Before adding a package, answer:
- why React Native/core platform APIs are insufficient;
- whether it affects New Architecture compatibility;
- whether it adds native setup;
- whether it is maintained.

Do not add:
- Expo;
- Expo Camera;
- VisionCamera;
- image-filter SDK;
- Redux solely for Camera;
- analytics SDK;
- networking framework;
- UI kit.

A small dependency needed for safe-area or test infrastructure is acceptable if it is part of standard React Native practice and compatible with the chosen version.

Record all non-template dependencies in the audit.

---

# 55. TypeScript quality

Use strict TypeScript.

Requirements:

- avoid `any` for native contracts;
- define discriminated unions for camera states;
- validate nullable native payloads;
- keep native event types centralized;
- avoid stringly typed lens/state logic where unions/enums are practical.

Example:

```ts
type CameraLifecycle =
  | {type: 'idle'}
  | {type: 'configuring'}
  | {type: 'running'}
  | {type: 'interrupted'; reason: string}
  | {type: 'failed'; code: CameraErrorCode};
```

---

# 56. Swift quality

Requirements:

- no `try!`;
- no force unwraps in camera runtime path;
- no arbitrary `DispatchQueue.main.async` everywhere;
- explicit queue/actor ownership;
- no global mutable camera singleton;
- no massive all-purpose manager;
- no UI code in CameraCore;
- no React Native imports deep inside CameraCore.

The native wrapper can import React.

The core camera engine should not know React Native exists.

---

# 57. Native camera session reuse

A React Native render cycle must not restart the camera.

The Fabric native view should create/attach to a stable native camera engine for its mounted lifetime.

Prop changes should update configuration, not reconstruct the whole session.

When `active=false`:
- pause/stop appropriately.

When `active=true`:
- resume safely.

Unmount:
- release resources deliberately.

Document the lifecycle.

---

# 58. Application lifecycle

React Native `AppState` can update product state.

Native iOS must still observe relevant application/session notifications.

If JS is paused during backgrounding, camera correctness must remain safe.

When returning:
- session recovers;
- native emits state;
- React Native updates UI.

---

# 59. UI fidelity target for this run

Implement only the **Camera Viewfinder** screen deeply.

Use:
- `chem_camera_viewfinder/code.html`;
- `chem_camera_viewfinder/screen.png`;
- global `DESIGN.md`.

Do not spend this run implementing Film Shelf, Darkroom Lab, or full Pro screen.

You may extract common design primitives that future screens will reuse.

The screen should visibly look like CHEM:
- dark optical-instrument aesthetic;
- amber accents;
- monospaced telemetry/readouts;
- prominent shutter;
- restrained controls.

It should not look like a default React Native starter app.

---

# 60. Safe-area and layout behavior

The Camera screen must handle:

- iPhone notch/Dynamic Island;
- home indicator;
- portrait;
- landscape if native camera supports it in this milestone.

Do not hardcode one screenshot pixel size.

Use responsive layout driven by window/safe-area dimensions.

The viewfinder aspect/crop should match the design intent.

---

# 61. Orientation contract

Native preview and capture must agree on orientation.

React Native layout may rotate/reflow.

Native owns:
- source orientation;
- preview transform;
- capture metadata.

Test:
- portrait;
- landscape left;
- landscape right.

Do not fix orientation by rotating JS image pixels after capture.

---

# 62. Capture storage abstraction

Native `CaptureStore` should expose a small protocol independent of React Native.

Conceptually:

```swift
protocol CaptureStoring: Sendable {
    func persist(
        data: Data,
        metadata: CaptureMetadata,
        id: UUID
    ) async throws -> StoredCapture
}
```

Future work will replace/extend this with full CHEM frame persistence.

Do not encode React Native event types into the storage layer.

---

# 63. Last-capture restoration after app restart

If cheap to implement cleanly, restore the most recent local capture thumbnail at launch.

This is desirable but P1 for this task.

Do not block core camera completion on it.

If implemented:
- query native storage through a typed module API;
- do not scan directories from JavaScript.

---

# 64. Performance rule: JS is control plane

Treat React Native as the **control plane**.

Native imaging is the **data plane**.

Allowed bridge traffic:

```text
JS → native
select lens
focus at point
set EV
capture
start/stop

native → JS
state changed
lenses list
capture completed
capture failed
low-frequency telemetry
```

Forbidden bridge traffic:

```text
video frames
raw pixel buffers
Metal textures
per-frame histogram arrays
full-resolution image bytes
60 Hz telemetry
```

---

# 65. Development debug tools

Add a dev-only native performance HUD or React Native debug panel using low-frequency native aggregate metrics.

Useful values:

```text
Camera: running
Lens: 1×
Preview FPS: 59
Render ms: 8.4
Dropped frames: 3
```

Do not make this part of production UX.

---

# 66. Implementation order inside this task

Follow this order:

## Step 1
Repository audit.

## Step 2
Bootstrap bare React Native TypeScript app.

## Step 3
Create design tokens + Camera screen static native RN layout.

## Step 4
Set up Codegen/New Architecture boundary.

## Step 5
Implement native camera permission module.

## Step 6
Implement native CameraCore session.

## Step 7
Implement `AVCaptureVideoDataOutput`.

## Step 8
Implement native Metal/MTKView preview.

## Step 9
Expose preview as Fabric Native Component.

## Step 10
Wire Camera UI to real native state.

## Step 11
Real lens discovery/switch.

## Step 12
Tap focus/expose.

## Step 13
EV compensation.

## Step 14
Still photo capture.

## Step 15
Durable native source storage.

## Step 16
Last capture thumbnail in React Native.

## Step 17
Tests/docs/build validation.

Do not start with the full HTML screen and leave camera native work until the end.

The camera path is the primary risk.

---

# 67. First vertical demo

The final demo for this Codex task should be:

```text
Open app
 ↓
CHEM React Native Camera screen
 ↓
Grant camera permission
 ↓
Native Metal camera preview appears
 ↓
Native-provided lenses appear in RN
 ↓
Tap another lens
 ↓
Native camera switches
 ↓
Tap viewfinder
 ↓
Native camera focuses/exposes
 ↓
Adjust EV
 ↓
Press RN shutter
 ↓
Native still capture occurs
 ↓
Native source is persisted
 ↓
RN receives captureCompleted
 ↓
Last-frame thumbnail updates
```

This is the only vertical slice that must be complete in this run.

---

# 68. Truthfulness requirements

Never mark a feature done because the UI exists.

Examples:

- Camera screen ≠ camera implementation.
- Film badge ≠ Film Engine.
- RAW label ≠ RAW capture.
- Pro button ≠ Pro Mode.
- preview image ≠ native live camera.
- a file stored in temporary cache ≠ durable capture.
- simulator build ≠ physical-device validation.

Your status documentation must distinguish:

```text
implemented
scaffolded
placeholder
simulator-verified
build-verified
device-verified
deferred
blocked
```

---

# 69. Stop condition

STOP once all of these are implemented or explicitly documented as environment-blocked:

- React Native TypeScript app bootstrapped.
- Camera screen translated from HTML into React Native.
- No WebView runtime.
- React Native New Architecture configured.
- Codegen contract exists.
- Fabric Native Camera Preview exists.
- Native AVFoundation CameraCore exists.
- Native Metal pass-through renderer exists.
- Preview frames never enter JS.
- Camera permission works.
- Real rear camera lenses are discovered.
- Lens switching works.
- Tap focus/expose works.
- EV compensation works.
- `AVCapturePhotoOutput` still capture works.
- Captured source is written to durable native storage.
- Capture success returns metadata/URI only.
- Last-frame thumbnail updates in React Native.
- Important errors are typed.
- Tests exist.
- Architecture documentation exists.
- Build/test evidence is recorded.
- Production Film Engine has NOT been started.

Do not continue into Film Engine, Lab, RAW, or calibration.

---

# 70. Required final handoff

At completion, return:

## A. Repository audit
What existed before your changes.

## B. React Native bootstrap
Exact React Native/Node/package-manager versions.

## C. Implemented UI
Which parts of the supplied HTML were translated.

## D. Native architecture
Fabric component, TurboModule, Swift CameraCore, Metal path.

## E. JS/native contract
Commands, props, events.

## F. Capture architecture
Explain source persistence before success event.

## G. Build/test evidence
Exact commands and outputs/status.

## H. Physical device verification
Exactly what was actually tested.

## I. Known limitations
Explicit list.

## J. Files created/changed
Grouped by React Native / iOS / docs / tests.

## K. Next Codex task
Recommend, but DO NOT implement:

> Shared CHEM RenderDescriptor + versioned FilmProfile + first DAY 200 Metal film pipeline + preview/final renderer consistency.

---

# 71. Definition of Done

The task is complete only if:

```text
[ ] Repository/spec audit completed
[ ] Existing HTML/design assets preserved
[ ] Bare React Native TypeScript app exists
[ ] New Architecture remains enabled
[ ] Camera UI is React Native, not SwiftUI
[ ] HTML is not loaded at runtime
[ ] No WebView used for product UI
[ ] CameraCore is native Swift
[ ] CameraCore does not depend on React Native
[ ] Fabric Native Component hosts native Metal preview
[ ] TurboModule/typed native API used where appropriate
[ ] Codegen configured
[ ] No camera frame crosses into JS
[ ] AVFoundation session has one clear owner
[ ] Video preview uses AVCaptureVideoDataOutput
[ ] Still photo uses AVCapturePhotoOutput
[ ] Real lens discovery implemented
[ ] Lens switching implemented
[ ] Tap focus/expose implemented
[ ] EV compensation implemented
[ ] Native durable capture storage implemented
[ ] Capture success emitted only after durable source exists
[ ] React Native shows last thumbnail
[ ] Camera permission states implemented
[ ] Simulator unavailable state is safe
[ ] Typed TS state exists
[ ] Typed native errors exist
[ ] OSLog/native diagnostics exist
[ ] Non-hardware tests exist
[ ] Physical-device checklist documented
[ ] Build/test status truthfully documented
[ ] No Film Engine scope creep
```

---

# 72. Final engineering rule

Keep this distinction throughout the implementation:

> **React Native owns the experience. Native iOS owns the camera and pixels.**

The HTML is there to tell you how CHEM should look.

React Native is there to implement that product interface.

AVFoundation and Metal are there to make CHEM a real camera.

Never move pixel-intensive work into JavaScript merely because the UI is React Native.

And never sacrifice capture reliability in order to imitate a design mockup.

Start by auditing the repository and writing the intended React Native/native module structure before modifying source files. Then proceed autonomously through the implementation order above. Do not ask for minor choices already resolved by the PRD, implementation plan, design files, or this prompt.

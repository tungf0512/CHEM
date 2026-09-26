# CHEM iOS — Core Features Implementation Plan

> **Document type:** Engineering Implementation Plan  
> **Product:** CHEM — Film Camera for iPhone  
> **Status:** Implementation-ready draft  
> **Version:** 1.0  
> **Platform:** iPhone / iOS  
> **Primary UI:** SwiftUI  
> **Camera:** AVFoundation  
> **Realtime rendering:** Metal  
> **Image/RAW support:** Core Image + ImageIO + AVFoundation  
> **Persistence:** SwiftData for metadata + file system for image assets  
> **Photos integration:** PhotoKit / PhotosPicker  
> **Concurrency:** Swift Concurrency  
> **Purchases:** StoreKit 2  
> **Source product spec:** CHEM PRD v1.0  
> **Core rule:** Reliability first, imaging second, product polish third.

---

# 0. Purpose of This Document

This document turns the CHEM PRD into an executable engineering plan.

The PRD answers:

> What should CHEM be?

This implementation plan answers:

> In what order should we build CHEM, which modules own which responsibilities, which interfaces must be frozen before implementation, what technical risks should be validated first, and what evidence is required before each milestone is considered complete?

The plan is intentionally organized around **technical risk and dependency order**, not around screen order.

For CHEM, the highest-risk areas are:

1. Camera lifecycle and capture reliability.
2. Realtime Metal rendering.
3. Preview/final rendering consistency.
4. Safe source persistence.
5. Full-resolution rendering performance.
6. RAW/ProRAW compatibility.
7. Cross-device/lens output consistency.
8. Integrating the existing HTML design into a native iOS implementation without polluting the imaging architecture.

The application must not begin as a large feature implementation where Camera, Lab, Film Shelf, StoreKit, onboarding, and advanced controls are all built simultaneously.

The correct implementation strategy is:

```text
Architecture skeleton
        ↓
Reliable camera
        ↓
Realtime renderer
        ↓
Safe capture transaction
        ↓
Shared final renderer
        ↓
Film engine V1
        ↓
CHEM frame persistence
        ↓
Lab / re-development
        ↓
Photos import/export
        ↓
RAW / ProRAW
        ↓
Device calibration
        ↓
Pro controls
        ↓
Productization + monetization
```

Until the previous layer is stable, the next layer should not become a hard dependency.

---

# 1. Implementation Objectives

The first engineering program has six objectives.

## OBJ-01 — Produce a dependable native camera

CHEM must be able to:

- start reliably;
- resume after interruption;
- switch lenses;
- focus;
- apply exposure compensation;
- capture a recoverable source frame;
- never silently lose a photo.

The app is not successful if its film rendering is excellent but the camera is unreliable.

## OBJ-02 — Build one reusable rendering engine

There must not be separate artistic implementations for:

- camera preview;
- captured photo;
- Lab preview;
- imported Photos image;
- export.

All of them must eventually call the same conceptual CHEM render graph.

Execution quality may differ, but semantics must not.

## OBJ-03 — Preserve the source before expensive rendering

The app must treat full-resolution film rendering as a downstream job.

The capture path is:

```text
Shutter
  ↓
Capture source
  ↓
Persist recoverable source
  ↓
Commit frame record
  ↓
Show fast preview
  ↓
Render final image
  ↓
Export/save
```

A crash after source persistence must not lose the frame.

## OBJ-04 — Establish a versioned image-processing architecture

From day one, the following must be versioned:

- `FilmProfile`;
- `FilmRecipe`;
- `DeviceProfile`;
- `RendererVersion`;
- persisted frame schema.

This avoids an architectural rewrite after public users already have photos.

## OBJ-05 — Make the UI native and independent from imaging

The supplied HTML/CSS UI is treated as:

- visual specification;
- interaction reference;
- source of design tokens;
- source of component states.

It is **not** the runtime UI technology.

The production iOS application should be native SwiftUI with isolated UIKit/Metal hosting only where needed.

## OBJ-06 — Build measurable quality gates

Every major feature needs:

- implementation scope;
- integration tests;
- device tests;
- failure-mode tests;
- exit criteria.

"No obvious bug on my phone" is not an acceptable Definition of Done.

---

# 2. Scope of This Implementation Plan

This document covers the implementation of the main V1 core:

- app architecture;
- native UI foundation;
- camera session;
- realtime film preview;
- image capture;
- source persistence;
- CHEM rendering engine;
- initial film stocks;
- Lab;
- re-development;
- gallery import;
- export;
- RAW/ProRAW;
- device normalization;
- Pro Mode;
- StoreKit Pro unlock;
- privacy-safe telemetry;
- performance instrumentation;
- QA and release hardening.

This document does not deeply specify:

- final brand artwork;
- App Store marketing images;
- public social campaigns;
- future video rendering;
- cloud sync;
- recipe social ecosystem;
- advanced Film Maker;
- generative AI.

---

# 3. Initial Technical Decisions

These decisions should be approved before serious feature implementation.

## DEC-01 — Native SwiftUI app

Use SwiftUI as the main application UI.

UIKit can be used only where it materially simplifies:

- camera preview hosting;
- platform-specific controls;
- advanced image interaction;
- system integration not cleanly exposed to SwiftUI.

Do not embed the HTML experience using `WKWebView`.

## DEC-02 — AVFoundation owns camera capture

The camera module should be built directly with AVFoundation.

Avoid third-party camera frameworks for the core capture layer.

Reasons:

- tighter session control;
- RAW/ProRAW access;
- lens/device selection;
- exposure/focus control;
- interruption handling;
- predictable performance;
- lower dependency risk.

## DEC-03 — Metal owns realtime artistic rendering

Core film rendering should be implemented as Metal compute/render stages.

Core Image can be used where useful, especially for:

- RAW decode/development;
- orientation;
- image conversion;
- interoperability.

But the artistic renderer should not become an uncontrolled chain of high-level `CIFilter`s if preview/final consistency and performance are key product promises.

## DEC-04 — SwiftData stores metadata, file system stores pixels

SwiftData should hold:

- frame metadata;
- recipe metadata;
- roll relationships;
- film/version references;
- render status;
- file references.

The file system should hold:

- source image;
- RAW/DNG;
- preview image;
- rendered image;
- thumbnails;
- diagnostic artifacts in debug builds.

Do not store large image blobs in SwiftData.

## DEC-05 — Core workflow works without backend

V1 core features must not depend on:

- sign-in;
- remote API;
- cloud renderer;
- remote film service.

## DEC-06 — Film profiles are data-driven

Shaders implement reusable stages.

Artistic values live in versioned film resources/configuration.

Avoid building one bespoke shader file per film.

## DEC-07 — Renderer is stateless per render request

A render output should be determined by an explicit render context.

Do not hide mutable global artistic state in the renderer.

---

# 4. Recommended Deployment Strategy

Final minimum iOS version should be frozen after target-device research.

Recommended implementation assumption:

> Build architecture using modern Swift concurrency, SwiftUI, StoreKit 2, PhotosPicker, SwiftData, and current AVFoundation/Metal APIs, then set the minimum supported OS based on device coverage and QA cost.

A practical initial product decision is to support relatively recent iOS versions rather than expanding support aggressively.

CHEM depends heavily on:

- GPU performance;
- current camera hardware;
- modern photo formats;
- ProRAW availability on certain devices.

Old-device support should not compromise the primary camera experience.

---

# 5. Repository Structure

Recommended repository layout:

```text
CHEM/
├── App/
│   ├── CHEMApp.swift
│   ├── AppEnvironment.swift
│   ├── AppRouter.swift
│   └── DependencyContainer.swift
├── DesignSystem/
│   ├── Tokens/
│   ├── Typography/
│   ├── Components/
│   ├── Icons/
│   └── Motion/
├── Features/
│   ├── Camera/
│   ├── Lab/
│   ├── Films/
│   ├── Gallery/
│   ├── Rolls/
│   ├── Settings/
│   ├── Onboarding/
│   └── Paywall/
├── CameraCore/
│   ├── Session/
│   ├── Devices/
│   ├── Capture/
│   ├── Focus/
│   ├── Exposure/
│   ├── WhiteBalance/
│   └── Interruption/
├── Imaging/
│   ├── Renderer/
│   ├── Film/
│   ├── Metal/
│   │   ├── Shaders/
│   │   ├── Kernels/
│   │   └── Resources/
│   ├── RAW/
│   ├── Color/
│   ├── SceneAnalysis/
│   ├── Calibration/
│   └── Output/
├── Domain/
│   ├── Frames/
│   ├── Films/
│   ├── Recipes/
│   ├── Rolls/
│   ├── Capture/
│   └── Export/
├── Persistence/
│   ├── Models/
│   ├── Repositories/
│   ├── Files/
│   ├── Migrations/
│   └── Recovery/
├── Platform/
│   ├── Photos/
│   ├── Permissions/
│   ├── Haptics/
│   ├── Store/
│   ├── Telemetry/
│   ├── DeviceInfo/
│   └── Thermal/
├── Resources/
│   ├── Films/
│   ├── Calibration/
│   └── Assets/
├── InternalTools/
│   ├── ImagingDebug/
│   ├── RendererBenchmark/
│   └── CalibrationCapture/
└── Tests/
    ├── Unit/
    ├── Integration/
    ├── Camera/
    ├── Persistence/
    ├── Rendering/
    ├── ImagingRegression/
    ├── Migration/
    └── UI/
```

If the project is kept in a single Xcode target initially, preserve these logical boundaries anyway.

If the team grows, convert stable boundaries into Swift packages.

---

# 6. Dependency Direction

Use the following dependency direction:

```text
Features
   ↓
Domain
   ↓
Protocols / abstractions
   ↓
Infrastructure implementations
```

Specific rule:

- SwiftUI views may depend on feature state.
- Feature state may depend on domain services.
- Domain models must not import SwiftUI.
- Domain models must not import AVFoundation unless absolutely necessary.
- `CameraCore` owns AVFoundation.
- `Imaging` owns Metal/Core Image.
- `Persistence` owns SwiftData/files.
- `Platform` owns PhotoKit/StoreKit/system integrations.

Avoid:

```text
CameraView
  ↓
directly calls AVCaptureSession
  ↓
directly writes file
  ↓
directly runs Metal renderer
```

Use:

```text
CameraView
  ↓
CameraFeatureModel
  ↓
CameraUseCase / CaptureCoordinator
  ↓
CameraCore + FrameRepository + RenderScheduler
```

---

# 7. Concurrency Model

Use Swift Concurrency intentionally.

Suggested ownership:

```text
@MainActor
CameraFeatureModel
LabFeatureModel
FilmShelfModel
SettingsModel

actor CameraSessionController
actor CaptureCoordinator
actor FrameRepository
actor RenderScheduler
actor ExportCoordinator
actor EntitlementStore
```

Rules:

1. Never block `MainActor` waiting for final render.
2. Never perform full file IO on `MainActor`.
3. Serialize AVFoundation session configuration through one owner.
4. Serialize persistence transactions for the same frame.
5. Allow multiple render jobs only within GPU/memory limits.
6. Preview rendering always has higher scheduling priority than background exports.

---

# 8. Existing HTML UI → Native iOS Conversion Plan

The HTML design should be translated systematically before feature coding.

## 8.1 Deliverable: UI inventory

Create `UI_INVENTORY.md`.

For every screen from HTML, capture:

- screen name;
- states;
- controls;
- gestures;
- overlays;
- empty states;
- loading states;
- error states;
- transitions;
- responsive assumptions.

Example:

```text
CameraScreen
├── idle
├── focusing
├── capturePressed
├── captureProcessing
├── proModeExpanded
├── filmSelectorExpanded
├── cameraPermissionDenied
└── cameraInterrupted
```

## 8.2 Deliverable: design tokens

Create native tokens for:

- colors;
- spacing;
- radii;
- typography;
- icon sizes;
- opacity;
- animation duration;
- haptic mappings.

Do not scatter values such as `Color(hex:)`, `padding(13)`, and custom fonts directly across feature files.

## 8.3 Component mapping

HTML components should become reusable native controls.

Examples:

```text
HTML Film Chip        → FilmChipView
HTML Shutter Button   → ShutterButton
HTML Lens Selector    → LensSelector
HTML Bottom Sheet     → ChemSheet
HTML Slider           → ChemAdjustmentSlider
```

## 8.4 Design fidelity passes

### Pass A — Functional layout

- correct hierarchy;
- correct controls;
- approximate styling.

### Pass B — Interaction fidelity

- gestures;
- motion;
- haptics;
- sheets.

### Pass C — Visual polish

- exact typography;
- spacing;
- animation;
- color tuning.

This prevents UI polish from hiding camera architecture problems.

---

# 9. Milestone Overview

| Milestone | Primary Goal | Core Exit Evidence |
|---|---|---|
| M0 | Project foundation | app boots, DI works, design-system shell exists |
| M1 | Reliable native camera | stable preview + capture on target devices |
| M2 | Metal live renderer | realtime 30/60 fps film preview |
| M3 | Transactional capture | source survives render failure/crash scenarios |
| M4 | Shared final renderer | preview/final use same film model |
| M5 | Film Engine V1 | 3 production-quality distinct film profiles |
| M6 | CHEM persistence | frame/recipe/version lifecycle stable |
| M7 | Lab/re-development | captured frame can change film non-destructively |
| M8 | Photos workflow | import + develop + export |
| M9 | RAW/ProRAW | capability-gated advanced negative pipeline |
| M10 | Device normalization | first calibrated device/lens profiles |
| M11 | Pro controls | ISO/shutter/WB/focus |
| M12 | Productization | paywall, settings, telemetry, accessibility |
| M13 | Hardening | device matrix, performance, migration, release gates |

---

# 10. M0 — Project Foundation

## Goal

Create an application skeleton where future modules can evolve independently.

## Tasks

### M0-T01 — Create Xcode project

Configure bundle ID, schemes, Debug, Release, and an internal/beta configuration if useful.

### M0-T02 — Concurrency/build settings

Enable strict concurrency diagnostics appropriate for the chosen Swift toolchain and useful warnings. Avoid suppressing warnings globally.

### M0-T03 — App environment

Define application dependencies centrally:

```swift
struct AppEnvironment {
    let cameraService: CameraServicing
    let renderer: ChemRendering
    let frameRepository: FrameRepository
    let photoLibrary: PhotoLibraryServicing
    let exportService: ExportServicing
    let entitlementStore: EntitlementStoring
    let telemetry: TelemetryServicing
}
```

### M0-T04 — Protocol-first boundaries

Use real implementations in production and fakes in tests/previews.

### M0-T05 — Logging

Use `OSLog`.

Suggested categories:

- app;
- camera;
- capture;
- renderer;
- persistence;
- photos;
- export;
- purchase;
- recovery;
- performance.

### M0-T06 — Internal feature flags

Examples:

- enableRawCapture;
- enableHalation;
- enableSceneAnalyzer;
- enableDeviceProfile;
- enableProMode.

### M0-T07 — CI

CI should at minimum:

- build Debug;
- build Release;
- run unit tests;
- run migration tests;
- validate bundled film resources.

## Exit criteria

- Project builds from clean clone.
- Dependency container exists.
- Feature-shell navigation works.
- No camera logic exists inside SwiftUI views.
- Logging/test targets are available.

---

# 11. M1 — Reliable Camera Foundation

This is the first real core feature.

Do not apply film effects yet.

## 11.1 CameraCore API

```swift
protocol CameraServicing: Sendable {
    func start() async throws
    func stop() async
    func availableLenses() async -> [CameraLens]
    func selectLens(_ lens: CameraLens) async throws
    func setExposureCompensation(_ ev: Float) async throws
    func focusAndExpose(at point: CGPoint) async throws
    func capture(_ request: CaptureRequest) async throws -> CapturedSource
}
```

Avoid leaking raw AVFoundation types into feature layers.

## 11.2 `CameraSessionController`

Responsibilities:

- own `AVCaptureSession`;
- own selected device;
- configure input/output;
- start/stop;
- interruption handling;
- runtime errors;
- lens reconfiguration;
- orientation.

It must be the only module allowed to mutate session topology.

## 11.3 Serialization

All session configuration must be serialized through one actor/queue.

Never call `beginConfiguration`, add/remove inputs, or change outputs from arbitrary UI callbacks.

## 11.4 Preview source

Use `AVCaptureVideoDataOutput` so live camera frames can feed Metal.

The core preview pipeline should not be a normal `AVCaptureVideoPreviewLayer` with decorative filters over it.

## 11.5 Still output

Use `AVCapturePhotoOutput` for final still capture.

Do not use the live video frame as the final still photo.

## 11.6 Lens discovery

Build `CameraDeviceCatalog`.

Domain representation:

```swift
struct CameraLens: Identifiable, Sendable {
    let id: String
    let role: LensRole
    let displayZoom: String
    let deviceUniqueID: String
    let supportsRaw: Bool
    let supportsManualFocus: Bool
}
```

Do not hardcode `.5×`, `1×`, `2×`, `5×`.

## 11.7 Permissions

Create `CameraPermissionService`.

States:

```text
notDetermined
authorized
denied
restricted
```

Gallery-only mode remains available when camera is denied.

## 11.8 Tap focus/exposure

Build coordinate conversion carefully:

```text
SwiftUI touch point
  ↓
viewfinder aspect-fill transform
  ↓
normalized point
  ↓
AVFoundation point
```

Test all orientations.

## 11.9 Interruption handling

Handle:

- app background;
- system camera interruption;
- media services reset;
- camera unavailable;
- runtime errors.

Camera lifecycle states:

```text
idle
requestingPermission
configuring
running
interrupted(reason)
recovering
failed(error)
```

## 11.10 Plain processed capture first

Before RAW:

- capture HEIF/JPEG;
- validate orientation;
- validate dimensions;
- validate metadata;
- validate repeated capture.

## M1 acceptance tests

### AT-CAM-01

Cold start reaches camera without manual refresh.

### AT-CAM-02

Background → foreground restores preview.

### AT-CAM-03

Switch available lenses repeatedly without session crash.

### AT-CAM-04

Tap focus/exposure works portrait and landscape.

### AT-CAM-05

Capture 100 normal frames with zero silently lost captures.

### AT-CAM-06

Deny camera and use Gallery path.

### AT-CAM-07

System interruption recovers where platform allows.

## M1 exit criteria

Do not continue to serious film rendering until the camera baseline is proven on at least:

- one recent Pro iPhone;
- one recent non-Pro iPhone;
- one intended baseline device.

---

# 12. M2 — Metal Live Rendering

## Goal

Render one film-like transform in realtime without degrading camera reliability.

## 12.1 Long-lived Metal objects

Create once and reuse:

- `MTLDevice`;
- `MTLCommandQueue`;
- pipeline states;
- `CVMetalTextureCache`;
- reusable buffers/textures.

Never compile or recreate expensive pipeline state every frame.

## 12.2 Video buffer → Metal texture

Pipeline:

```text
CMSampleBuffer
  ↓
CVPixelBuffer
  ↓
CVMetalTextureCache
  ↓
MTLTexture
  ↓
CHEM Preview Renderer
  ↓
MTKView drawable
```

Avoid CPU pixel copies.

## 12.3 Preview surface

Use `MTKView` or equivalent Metal-backed native view hosted in SwiftUI.

Do not generate a `UIImage` per video frame.

## 12.4 Aspect and orientation

Keep geometry separate from color processing.

Inputs:

- texture dimensions;
- view dimensions;
- crop/aspect;
- device orientation;
- mirroring.

## 12.5 First shader

Start simple:

```text
input
 ↓
exposure
 ↓
tone
 ↓
3D color transform
 ↓
output
```

No grain/bloom/halation initially.

## 12.6 Performance instrumentation

Measure:

- camera input FPS;
- rendered FPS;
- GPU time;
- CPU encoding time;
- dropped frames;
- queue depth;
- memory;
- thermal state.

Build a debug HUD.

## 12.7 Backpressure

If renderer is behind, drop stale preview frames.

Do not queue every sample buffer.

The preview wants the latest frame, not historical accuracy.

## 12.8 Preview quality tiers

```swift
enum PreviewQuality {
    case high
    case balanced
    case thermalReduced
}
```

Quality may alter resolution or expensive kernel approximation, not film identity.

## M2 gates

- preferred 60 fps on primary recent devices;
- stable 30 fps baseline;
- no unbounded latency;
- UI interaction remains responsive;
- lens switching does not leak GPU resources.

---

# 13. M3 — Transactional Capture and Source Safety

This milestone is non-negotiable.

## 13.1 Capture state machine

```text
idle
 ↓
requestCreated
 ↓
sensorCapturing
 ↓
sourceReceived
 ↓
persistingSource
 ↓
sourceSafe
 ↓
previewGenerating
 ↓
finalRendering
 ↓
exporting
 ↓
complete
```

Anything after `sourceSafe` is recoverable.

## 13.2 Pending frame

At shutter request create a persistent frame identity.

```swift
struct FrameDraft {
    let id: UUID
    let createdAt: Date
    let filmReference: FilmReference
    let captureIntent: CaptureIntent
}
```

## 13.3 Atomic source write

Workflow:

```text
write temp
 ↓
validate write
 ↓
close/flush
 ↓
atomic move
 ↓
database marks sourceSafe
```

Never mark `sourceSafe` first.

## 13.4 Frame directory

```text
Frames/<UUID>/
  source.heic
  source.dng          optional
  preview.heic        derived
  render.heic         derived
  metadata.json       optional sidecar
```

## 13.5 Recovery

On launch:

- query incomplete frame states;
- verify durable source;
- requeue missing renders;
- remove abandoned drafts that never captured source.

States:

```text
pendingCapture
sourceSafe
previewReady
renderPending
rendered
photosSavePending
complete
recoverableError
failedCapture
```

## 13.6 Fast feedback

Once source is safe:

- update last-frame thumbnail;
- unlock normal camera flow;
- continue final rendering asynchronously.

## 13.7 Repeated shooting

V1 does not need Burst mode, but quick repeated taps must be safe.

Do not let final render backlog block source capture unless system memory pressure forces controlled throttling.

## M3 failure injection

Simulate:

- renderer failure;
- disk write failure;
- Photos save failure;
- app termination after source write;
- app termination during final render;
- low storage;
- missing preview cache.

Exit invariant:

> A captured frame that reached `sourceSafe` is recoverable after relaunch.

---

# 14. M4 — Shared Preview/Final Rendering Architecture

## Goal

Preview and final output must use the same film semantics.

## 14.1 Render descriptor

```swift
struct RenderDescriptor: Sendable {
    let film: FilmReference
    let recipe: FilmRecipe
    let deviceProfile: DeviceProfileReference
    let rendererVersion: RendererVersion
    let sceneParameters: SceneParameters?
    let grainSeed: UInt64
}
```

## 14.2 Render quality

```swift
enum RenderQuality {
    case realtimePreview
    case interactiveLab
    case final
}
```

Quality changes computational cost, not creative identity.

## 14.3 Render graph

```text
Decode/Input
 ↓
Input normalization
 ↓
Exposure
 ↓
Tone response
 ↓
Color response
 ↓
Highlight/shadow shaping
 ↓
Bloom
 ↓
Halation
 ↓
Grain
 ↓
Output transform
```

## 14.4 Immutable film render parameters

```swift
struct FilmRenderParameters {
    let tone: ToneParameters
    let color: ColorParameters
    let highlights: HighlightParameters
    let bloom: BloomParameters
    let halation: HalationParameters
    let grain: GrainParameters
}
```

Film changes should swap an immutable parameter/resource set.

## 14.5 Preview/final comparison tool

Build an internal tool that:

1. freezes/records preview;
2. captures still;
3. runs final renderer;
4. aligns crop;
5. shows side-by-side and difference.

This tool should exist before film tuning accelerates.

---

# 15. M5 — Film Engine V1

Start with three highly differentiated films:

- DAY 200;
- SKIN 400;
- NIGHT 800T.

Do not implement all eight before the pipeline is proven.

---

# 16. Film Engine Stages

## 16.1 Input normalization

Inputs may be:

- YCbCr live preview;
- processed HEIF/JPEG;
- RAW/ProRAW.

Convert to a documented internal representation.

Target:

- floating point;
- wide gamut;
- linear-light operations where appropriate.

## 16.2 Exposure

Implement development exposure separately from camera EV.

## 16.3 Tone response

Support explicit:

- toe;
- midtone contrast;
- shoulder;
- black behavior;
- highlight compression.

Avoid a stack of generic contrast filters.

## 16.4 Color response

Use a composable model such as:

- matrices;
- 3D LUT;
- hue/saturation functions.

3D LUT is a component, not the complete film simulation.

## 16.5 Highlight behavior

Film stocks differ strongly here.

Highlight shaping should occur before bloom/halation.

## 16.6 Bloom

Pipeline:

```text
luminance/highlight extraction
 ↓
soft threshold
 ↓
blur
 ↓
controlled recombination
```

Requirements:

- scene dependent;
- resolution scaled;
- no dark-region haze.

## 16.7 Halation

Requirements:

- highlight dependent;
- chromatically controlled;
- no global red overlay;
- resolution scaled.

## 16.8 Grain

Requirements:

- deterministic via persisted seed;
- no static PNG overlay;
- no visible tiling;
- resolution-aware;
- optionally luminance-dependent.

---

# 17. Film Profile Resource Format

Film resources remain data-driven.

Example:

```json
{
  "schema": 1,
  "id": "skin400",
  "version": 1,
  "display_name": "SKIN 400",
  "category": "color_negative",
  "iso_character": 400,
  "tone": {
    "toe": 0.18,
    "mid_contrast": 0.92,
    "shoulder": 0.28
  },
  "color_resource": "skin400_v1.cube",
  "bloom": {
    "enabled": true,
    "strength": 0.12
  },
  "halation": {
    "enabled": true,
    "strength": 0.07
  },
  "grain": {
    "model": "fine_color_v1",
    "strength": 0.25
  }
}
```

Film resources should be validated in CI.

---

# 18. Internal Film Playground

Build an internal authoring tool instead of changing constants in production code.

It should support:

- load reference image;
- choose film;
- tune internal parameters;
- A/B compare;
- render fixed regression set;
- export validated film resource;
- compare profile versions.

This tool is a first-class engineering asset.

---

# 19. Film Quality Gate

Every stock is tested across:

- light/medium/dark skin;
- daylight;
- warm indoor;
- foliage;
- blue sky;
- saturated red;
- neutrals;
- strong highlight;
- deep shadow;
- neon;
- overexposure;
- underexposure.

Each film must have a clear photographic use case.

---

# 20. M6 — CHEM Frame Persistence

## Goal

Persist enough state to re-develop later.

## 20.1 Metadata entities

Suggested SwiftData entities:

- `FrameRecord`;
- `FilmRecipeRecord`;
- `RollRecord`;
- `RenderRecord`.

Film profile definitions remain app resources, not user-mutated DB rows.

## 20.2 FrameRecord fields

At minimum:

```text
id
createdAt
updatedAt
captureSourceType
sourceRelativePath
rawRelativePath?
previewRelativePath?
renderRelativePath?
photosLocalIdentifier?
cameraDeviceModel
cameraLensID
captureISO?
captureShutter?
captureWB?
captureEV?
orientation
filmID
filmVersion
rendererVersion
deviceProfileID
deviceProfileVersion
grainSeed
state
rollID?
```

## 20.3 Repository API

```swift
protocol FrameRepository: Sendable {
    func createDraft(_ draft: FrameDraft) async throws -> UUID

    func markSourceSafe(
        frameID: UUID,
        source: StoredSource
    ) async throws

    func updateRecipe(
        frameID: UUID,
        recipe: FilmRecipe
    ) async throws

    func markRenderComplete(
        frameID: UUID,
        asset: StoredRender
    ) async throws

    func fetchFrame(id: UUID) async throws -> CHEMFrame
    func recentFrames(limit: Int) async throws -> [CHEMFrame]
    func recoverIncompleteFrames() async
}
```

## 20.4 Migration from day one

Define schema versioning and migration tests before public release.

---

# 21. M7 — CHEM Lab / Re-Development

## Goal

Captured frames can change film and process without changing source.

## 21.1 Interactive render quality

Do not render full resolution for every slider/film swipe.

Use:

- screen-sized decoded source;
- interactive render quality;
- cancellation of stale jobs.

## 21.2 Lab model

```swift
@MainActor
final class LabFeatureModel {
    var frame: CHEMFrame
    var workingRecipe: FilmRecipe
    var selectedFilm: FilmReference
    var renderState: LabRenderState
}
```

## 21.3 Film switching

When user swipes:

1. cancel older pending interactive job;
2. schedule newest descriptor;
3. show cached preview if available;
4. replace when latest render completes.

## 21.4 Development exposure

Persist separately from capture exposure.

## 21.5 Process

UI:

- Pull -1;
- Normal;
- Push +1.

Internally process affects multiple film parameters.

## 21.6 Grain

UI:

- Fine;
- Normal;
- Rough.

Actual values remain film-specific.

## 21.7 Before/after

Recommended:

> hold to show normalized original representation.

Do not expose raw Bayer-looking intermediate as "original".

## 21.8 Commit

Recommended:

- recipe auto-saves;
- source is immutable;
- exports are explicit new rendered assets.

---

# 22. M8 — Photos Import and Export

## 22.1 PhotosPicker

Prefer scoped selection.

Flow:

```text
Lab
 ↓
Import
 ↓
PhotosPicker
 ↓
Resolve asset
 ↓
Create imported CHEM frame
 ↓
Render with film
```

## 22.2 Source strategy

Two possibilities:

### Reference Photos asset

Pros:
- low storage.

Cons:
- source can become unavailable.

### Managed copy

Pros:
- dependable.

Cons:
- duplicates storage.

Recommended:

> Create a CHEM-managed durable source once the imported asset becomes a CHEM frame intended for re-development, while preserving reference metadata when useful.

## 22.3 Input color handling

Expect:

- sRGB JPEG;
- Display P3 HEIF;
- HDR-capable sources;
- RAW.

Never assume all imported photos are sRGB.

## 22.4 Export service

```swift
protocol ExportServicing {
    func export(
        frame: CHEMFrame,
        recipe: FilmRecipe,
        options: ExportOptions
    ) async throws -> ExportResult
}
```

## 22.5 V1 formats

- HEIF default;
- JPEG compatibility.

## 22.6 Metadata

Explicitly define:

- orientation;
- date;
- location preservation policy;
- camera model;
- CHEM film identifier if desired.

No fake analog-camera EXIF.

---

# 23. M9 — RAW / ProRAW

RAW is added only after processed capture is stable.

## 23.1 Runtime capabilities

```swift
struct CaptureCapabilities {
    let supportsRaw: Bool
    let supportsProRaw: Bool
    let supportedRawPixelFormats: [OSType]
    let maxPhotoDimensions: CMVideoDimensions
}
```

Query real runtime support.

## 23.2 Capture modes

### Standard

Processed source.

### Negative

RAW/ProRAW plus suitable processed companion/preview.

## 23.3 Source model must support multiple components

```swift
struct SourceBundle {
    let primary: SourceReference
    let raw: SourceReference?
    let companionProcessed: SourceReference?
}
```

## 23.4 RAW decode

Build `RawSourceDecoder`, likely using Core Image/ImageIO path where appropriate.

Output enters the same CHEM working representation.

## 23.5 User-facing simplicity

Do not expose RAW developer complexity.

CHEM chooses stable internal defaults.

## 23.6 Storage UX

Show:

- feature support;
- expected storage cost;
- negative-management controls.

---

# 24. M10 — Device-Aware Normalization

## Goal

Reduce lens/device drift before film rendering.

## 24.1 Device profile identity

Conceptually:

```text
hardware family
+ camera/lens identity
+ input source type
+ profile version
```

## 24.2 Provider

```swift
protocol DeviceProfileProviding: Sendable {
    func profile(
        device: DeviceIdentity,
        lens: LensIdentity,
        inputType: SourceType
    ) -> DeviceProfile
}
```

## 24.3 Responsibilities

Device profile may correct:

- color bias;
- baseline tone;
- WB tendency;
- lens-specific response.

It should not add artistic film character.

## 24.4 Fallback

Unsupported devices use a safe generic profile.

The app must never crash because a calibrated profile is missing.

## 24.5 Calibration tool

Internal capture workflow stores:

- device;
- lens;
- OS;
- illumination;
- chart;
- bracket;
- source files;
- notes.

Start small and calibrate real high-priority devices first.

---

# 25. M11 — Pro Controls

Add after automatic path is stable.

## 25.1 Manual exposure

Expose:

- ISO;
- exposure duration.

When active, disable conflicting automatic EV semantics.

## 25.2 White balance

Expose:

- Auto;
- Kelvin;
- Tint.

Clamp to valid device gains.

## 25.3 Manual focus

Normalized slider where supported.

## 25.4 Lens changes

After lens switch:

- recompute supported ranges;
- clamp invalid values;
- update UI.

Never apply Wide-lens constraints to Tele.

## 25.5 Separation from film recipe

Manual controls affect acquisition.

Film recipe affects development.

Do not conflate them.

---

# 26. M12 — Productization

## 26.1 StoreKit 2

Create `EntitlementStore`.

It owns:

- product loading;
- purchase;
- transaction update listener;
- current entitlement state;
- restore-equivalent access through StoreKit state.

Use verified StoreKit transaction/entitlement state, not a local permanent Boolean.

## 26.2 Feature gating

```swift
enum ProFeature {
    case rawCapture
    case premiumFilms
    case proControls
    case batchDevelop
}
```

Feature layer asks entitlement service.

Views do not hardcode product IDs.

## 26.3 Settings

Categories:

- camera;
- capture;
- storage;
- export;
- privacy;
- Pro;
- about.

## 26.4 Telemetry

Core correctness never depends on analytics.

No photo content.

## 26.5 Accessibility

Before public beta:

- VoiceOver;
- selected states;
- large enough controls;
- haptic + visual feedback;
- Reduce Motion;
- orientation testing.

---

# 27. Detailed Core Contracts

## 27.1 Camera

```swift
protocol CameraServicing: Sendable {
    var stateStream: AsyncStream<CameraState> { get }

    func requestPermission() async -> CameraPermission
    func start() async throws
    func stop() async

    func lenses() async -> [CameraLens]
    func selectLens(id: CameraLens.ID) async throws

    func focusAndExpose(at point: NormalizedPoint) async throws
    func setExposureCompensation(_ value: Float) async throws

    func capture(_ request: CaptureRequest) async throws -> CapturedSource
}
```

## 27.2 Preview frame source

```swift
protocol PreviewFrameProviding: Sendable {
    var frames: AsyncStream<PreviewFrame> { get }
}
```

Avoid converting preview to CPU image objects.

## 27.3 Renderer

```swift
protocol ChemRendering: Sendable {
    func renderPreview(
        _ input: RenderInput,
        descriptor: RenderDescriptor,
        quality: PreviewQuality
    ) async throws -> PreviewOutput

    func renderImage(
        _ input: RenderInput,
        descriptor: RenderDescriptor,
        quality: RenderQuality
    ) async throws -> RenderedImage
}
```

## 27.4 Render scheduler

Owns:

- priorities;
- cancellation;
- deduplication;
- concurrency;
- thermal behavior.

Priority order:

```text
realtime preview
interactive Lab
post-capture preview
current-frame final
background export
batch
```

## 27.5 Film library

```swift
protocol FilmLibraryProviding: Sendable {
    func allFilms() -> [FilmProfile]
    func film(id: FilmID, version: Int?) -> FilmProfile?
    func latestVersion(id: FilmID) -> FilmProfile?
}
```

## 27.6 Device profile provider

```swift
protocol DeviceProfileProviding: Sendable {
    func profile(
        device: DeviceIdentity,
        lens: LensIdentity,
        inputType: SourceType
    ) -> DeviceProfile
}
```

---

# 28. Domain Models

## 28.1 FilmReference

```swift
struct FilmReference: Codable, Hashable, Sendable {
    let id: String
    let version: Int
}
```

## 28.2 RendererVersion

```swift
struct RendererVersion: Codable, Hashable, Sendable {
    let major: Int
    let minor: Int
    let patch: Int
}
```

## 28.3 FilmRecipe

```swift
struct FilmRecipe: Codable, Hashable, Sendable {
    var film: FilmReference
    var exposureEV: Float
    var process: ProcessSetting
    var grainStyle: GrainStyle
    var warmth: Float
    var crop: CropState?
    let rendererVersion: RendererVersion
}
```

## 28.4 CHEMFrame

```swift
struct CHEMFrame: Identifiable, Sendable {
    let id: UUID
    let createdAt: Date
    let source: SourceBundle
    let captureMetadata: CaptureMetadata
    var recipe: FilmRecipe
    let deviceProfile: DeviceProfileReference
    let grainSeed: UInt64
    var renderState: RenderState
    var renderedAsset: RenderedAssetReference?
}
```

---

# 29. Render Input Abstraction

```swift
enum RenderInput {
    case preview(PreviewTexture)
    case processedImage(ImageSource)
    case raw(RawSource)
}
```

The input adapter owns:

- decode;
- orientation;
- color metadata;
- working-space conversion.

---

# 30. Memory Strategy

Rules:

1. Reuse Metal textures.
2. Pool resources where profiling shows benefit.
3. Avoid several simultaneous full-res float buffers.
4. Tile large final renders if required.
5. Keep thumbnail cache bounded.
6. Limit high-res render concurrency.
7. Release RAW decode resources quickly.

Memory use is a release metric, not only a debug concern.

---

# 31. Thermal Strategy

## Nominal

- highest preview tier;
- normal scene-analysis frequency.

## Serious thermal state

- stable 30 fps;
- lower preview resolution;
- pause/deprioritize background render.

## Critical

- protect source capture;
- disable expensive preview extras if necessary;
- suspend batch work.

Do not sacrifice capture reliability to preserve live halation quality.

---

# 32. Scene Analysis Rollout

Scene awareness should be incremental.

## Phase 1

Deterministic statistics:

- luminance histogram;
- highlights;
- chroma;
- approximate WB context.

## Phase 2

Optional on-device classification/segmentation features if they materially improve film behavior.

Keep base film model strong without ML dependency.

---

# 33. Preview Pipeline

```text
AVCaptureVideoDataOutput
 ↓
CMSampleBuffer
 ↓
CVPixelBuffer
 ↓
CVMetalTexture
 ↓
active RenderDescriptor
 ↓
device normalization
 ↓
film graph
 ↓
view geometry
 ↓
MTKView
```

Forbidden work on preview hot path:

- disk IO;
- SwiftData query;
- StoreKit;
- network;
- full-resolution export;
- expensive synchronous ML every frame.

---

# 34. Capture Pipeline

```text
Shutter
 ↓
CaptureIntent
 ↓
Create FrameDraft
 ↓
AVCapturePhotoOutput
 ↓
CapturedSource
 ↓
Atomic durable write
 ↓
sourceSafe commit
 ↓
quick thumbnail
 ↓
camera unlocked
 ↓
final render queued
 ↓
render stored
 ↓
optional Photos save
 ↓
complete
```

---

# 35. Lab Pipeline

```text
open frame
 ↓
resolve source + recipe
 ↓
decode display-sized source
 ↓
interactive render
 ↓
user changes recipe
 ↓
cancel stale render
 ↓
render latest
 ↓
persist recipe
 ↓
on export: full-res render
```

---

# 36. Imported Photo Pipeline

```text
PhotosPicker
 ↓
resolve source
 ↓
read orientation/color metadata
 ↓
create imported CHEM frame
 ↓
durable source strategy
 ↓
normalize input
 ↓
film renderer
 ↓
Lab
```

---

# 37. Cache Strategy

Derived-render cache key includes:

```text
source fingerprint
+ film ID/version
+ recipe hash
+ renderer version
+ device profile version
+ output dimensions
+ quality tier
```

Source is never a cache.

---

# 38. Renderer Determinism

Use:

- persisted grain seed;
- fixed graph order;
- versioned resources;
- explicit scene parameters.

Compression bytes may differ, but visual/pixel pipeline should be reproducible.

---

# 39. Orientation Rules

Keep orientation as metadata/transform where possible.

Test:

- portrait;
- landscape left/right;
- front camera mirror if front camera ships.

Do not rotate full-size pixels unnecessarily during source persistence.

---

# 40. Color Pipeline Contract

Document one working-space policy.

Concept:

```text
source decode
 ↓
explicit input transform
 ↓
extended linear working space
 ↓
CHEM process
 ↓
output transform
 ↓
Display P3 HEIF / sRGB JPEG
```

Color metadata errors are release blockers.

---

# 41. Imaging Tests

## Parameter tests

Validate film schema/resources.

## Golden renders

Fixed input → fixed film → reference output.

Use tolerant/perceptual comparison when GPU/platform variation requires it.

## Cross-quality

Preview, interactive Lab, and final should preserve the same artistic behavior.

---

# 42. Camera Tests

Physical devices are mandatory.

Test:

- permissions;
- start/stop;
- interruptions;
- focus;
- EV;
- lens switching;
- capture loops;
- orientation;
- app lifecycle;
- low storage.

Simulator tests cannot prove camera correctness.

---

# 43. Persistence Tests

Automate:

- draft creation;
- source-safe commit;
- simulated kill/recovery;
- missing derived render;
- cache purge;
- schema migration.

Invariant:

> `sourceSafe` means the durable source can actually be opened.

---

# 44. Performance Benchmark Suite

Measure per device:

## Preview

- FPS;
- median/p95 GPU frame time;
- dropped frames.

## Final

- 12 MP;
- 24 MP;
- 48 MP where available.

## Memory

Peak per final render.

## Startup

Cold/warm camera readiness.

Keep historical benchmark results by renderer version.

---

# 45. Debug HUD

Internal example:

```text
FPS: 59.8
GPU: 8.2 ms
CPU encode: 1.3 ms
Preview: 1080x1440
Thermal: nominal
Film: SKIN400@2
Renderer: 1.3.0
Profile: Device_Wide@1
Queue: 1
Memory: 242 MB
```

---

# 46. Dependency Graph

```text
M0 Foundation
 ├────────────┐
 ↓            ↓
M1 Camera   Design System
 ↓
M2 Preview Renderer
 ↓
M3 Capture Safety
 ↓
M4 Shared Renderer
 ↓
M5 Film Engine
 ├───────────────┐
 ↓               ↓
M6 Persistence   UI polish
 ↓
M7 Lab
 ↓
M8 Gallery
 ↓
M9 RAW
 ↓
M10 Calibration
 ↓
M11 Pro
 ↓
M12 Productization
 ↓
M13 Hardening
```

---

# 47. Execution Phases

## Phase A — Architecture + plain camera

Output:

A boring but dependable native camera.

## Phase B — Realtime film

Output:

Metal live transform with measured FPS.

## Phase C — Frame safety

Output:

Crash/re-render failures cannot silently destroy source.

## Phase D — Real film engine

Output:

Three strong profiles with shared preview/final semantics.

## Phase E — Lab

Output:

Non-destructive film switching.

## Phase F — Photos

Output:

Gallery input uses the same engine.

## Phase G — Advanced acquisition

Output:

RAW, calibration, manual controls.

## Phase H — Release product

Output:

StoreKit, settings, accessibility, hardening.

---

# 48. Team Parallelization

For a two-engineer implementation:

## iOS/platform engineer

Owns:

- SwiftUI;
- AVFoundation;
- lifecycle;
- persistence;
- PhotoKit;
- StoreKit.

## Imaging engineer

Owns:

- Metal;
- color;
- film profiles;
- calibration;
- rendering performance.

Shared contracts:

- `CapturedSource`;
- `RenderInput`;
- `RenderDescriptor`;
- `CHEMFrame`.

Avoid concurrent uncoordinated edits to these central contracts.

---

# 49. Pre-Code Contracts

Before implementing a module, write its contract:

- responsibility;
- public API;
- allowed dependencies;
- forbidden dependencies;
- actor/thread ownership;
- errors;
- persistence side effects;
- completion evidence.

Freeze these first:

- CameraService;
- CaptureCoordinator;
- ChemRenderer;
- RenderScheduler;
- FrameRepository;
- FilmLibrary;
- DeviceProfileProvider;
- PhotoLibraryService;
- ExportService;
- EntitlementStore.

---

# 50. Error Taxonomy

Use typed errors.

Example:

```swift
enum CaptureError: Error {
    case permissionDenied
    case sessionUnavailable
    case deviceUnavailable
    case sensorCaptureFailed
    case sourceEncodingFailed
    case sourcePersistenceFailed
}
```

Classify:

- retryable;
- user-actionable;
- unrecoverable;
- programmer/configuration error.

---

# 51. Correlated Logging

Every capture uses `frameID`.

Example:

```text
frame=ABC capture_requested
frame=ABC source_received
frame=ABC source_persisted
frame=ABC final_render_started
frame=ABC final_render_complete
frame=ABC photos_saved
```

This is essential for debugging camera reliability.

---

# 52. Privacy-Safe Diagnostics

Do not log:

- pixels;
- GPS;
- face data;
- arbitrary user filenames.

Log:

- anonymous frame ID;
- source type;
- lens role;
- stage;
- timing bucket;
- error category.

---

# 53. UI State Architecture

Camera UI is driven by explicit state.

```swift
struct CameraViewState {
    var permission: CameraPermission
    var lifecycle: CameraLifecycleState
    var selectedFilm: FilmReference
    var lenses: [CameraLens]
    var selectedLens: CameraLens.ID?
    var exposureEV: Float
    var focusIndicator: FocusIndicatorState?
    var captureState: CaptureUIState
    var lastFrame: FrameThumbnail?
    var proState: ProCameraState
}
```

This allows the HTML design to be recreated for every state in SwiftUI previews.

---

# 54. SwiftUI Preview Fixtures

Create fake preview states for:

- normal camera;
- focusing;
- capture processing;
- permission denied;
- camera interrupted;
- Pro controls;
- locked Pro feature;
- Lab loading;
- Lab render error.

Design work should not require physical camera.

---

# 55. Film Shelf Order

Implementation order:

1. static 3-film library;
2. live switching;
3. film details;
4. entitlement state;
5. expand to final library.

Do not add remote downloadable film packs in V1.

---

# 56. Shutter Rules

Shutter tap:

1. UI press feedback;
2. haptic;
3. immediate capture intent.

Do not wait for visual animation before triggering capture.

---

# 57. Lens Switching Rules

During transition:

- reject unsafe duplicate switch requests;
- update selection only when active;
- atomically update device profile.

---

# 58. Exposure Naming

Keep:

```text
captureExposureCompensationEV
developmentExposureEV
```

These are fundamentally different concepts.

---

# 59. Focus Rules

Focus UI is temporary and unobtrusive.

AE/AF lock can follow after basic focus/exposure correctness.

---

# 60. Source Storage Semantics

Directories:

```text
Application Support/CHEM/Frames/    durable
Caches/CHEM/                        disposable
```

`Clear Cache` can never remove frame source.

---

# 61. Delete Semantics

Deleting CHEM frame must distinguish:

- CHEM source/metadata;
- exported Apple Photos asset.

Never delete Photos asset implicitly.

---

# 62. Photos Resilience

If Photos reference disappears:

- managed CHEM source continues if present;
- otherwise frame becomes unavailable with clear error.

No crash.

---

# 63. Purchase Architecture

Entitlement:

```text
unknown
free
pro
```

On app launch:

- start transaction updates;
- read current verified entitlement;
- update feature availability asynchronously.

Purchase failure cannot block camera.

---

# 64. Recommended Free/Pro Boundary

Free:

- full camera;
- 3 films;
- gallery import;
- full-resolution output;
- no watermark.

Pro:

- all films;
- RAW/ProRAW;
- Pro controls;
- future batch;
- advanced recipes later.

---

# 65. Calibration Workflow

For each device/lens:

1. controlled setup;
2. reference chart;
3. neutral target;
4. exposure bracket;
5. real scenes;
6. metadata capture;
7. profile estimation;
8. regression validation;
9. profile version freeze.

---

# 66. Calibration Data

```text
CalibrationSession
├── deviceID
├── lensID
├── OSVersion
├── appBuild
├── illumination
├── chartType
├── exposureBracket
├── captureFiles
└── notes
```

---

# 67. Version Migration Policy

Existing frames store:

- film version;
- renderer version;
- device profile version.

App updates must not silently alter visual appearance of old frames.

If a new profile is available, future UI may offer explicit migration/re-develop.

---

# 68. Offline Guarantee

With airplane mode, verify:

- launch;
- camera;
- film switching;
- capture;
- Lab;
- import local Photos asset;
- export;
- known Pro entitlement behavior.

No core network spinner.

---

# 69. Launch Sequence

```text
Process starts
 ↓
lightweight AppEnvironment
 ↓
start transaction listener async
 ↓
start frame recovery async
 ↓
show camera shell
 ↓
start camera
 ↓
lazy-load nonessential resources
```

Do not block camera on:

- StoreKit network;
- gallery enumeration;
- every film resource;
- analytics.

---

# 70. Film Resource Loading

Preload:

- active film;
- possibly adjacent films.

Cache GPU resources with bounded strategy.

Do not upload all heavy resources at launch without profiling.

---

# 71. Lab Thumbnail Strategy

Use:

- small source;
- lazy film thumbnails;
- caching.

Never render eight full-resolution outputs just to display a picker.

---

# 72. Capture Queue

Explicit limits:

- capture source is highest durability priority;
- one/few final renders depending device memory;
- batch is lowest.

If queue grows, delay final rendering before denying safe source capture.

---

# 73. Processing UI

Use non-blocking states:

- thumbnail may display subtle developing state;
- Lab can use quick preview before full-resolution export.

---

# 74. Low-Light Testing

Test:

- computational processed source;
- high ISO;
- neon;
- indoor mixed light;
- long-ish exposure.

Be careful not to stack aggressive grain over already noisy input.

---

# 75. Skin-Tone Testing

SKIN 400 validation must span multiple skin tones and light types.

Scene-aware skin protection, if added, must be conservative.

---

# 76. HDR Policy

For V1, define a controlled SDR/wide-gamut output policy before adding HDR output.

Do not accidentally clip HDR sources through an undocumented transform.

---

# 77. Image Formats

Recommended:

- processed source: HEIF when appropriate;
- default render: HEIF;
- compatibility: JPEG;
- negative: DNG/ProRAW where supported.

---

# 78. CI

Every PR:

- build;
- unit tests;
- migration tests;
- film-resource validation.

On-device/nightly:

- camera smoke;
- render benchmark;
- golden images;
- export.

---

# 79. Branch / Agent Strategy

Use short-lived feature branches/worktrees.

Coding agents should own bounded modules.

Good:

> Implement FilmProfile parser and tests.

Bad:

> Build the CHEM app.

Each agent receives:

- contract;
- allowed files;
- tests;
- completion proof.

---

# 80. Pre-Code Checklist

```text
[ ] responsibility frozen
[ ] API frozen
[ ] dependencies listed
[ ] errors defined
[ ] actor ownership defined
[ ] persistence effects defined
[ ] tests defined
[ ] recovery defined
[ ] performance budget defined
```

---

# 81. Camera Definition of Done

Camera is complete only when:

- permissions;
- preview;
- still capture;
- lenses;
- focus;
- EV;
- orientation;
- interruptions;
- lifecycle;
- accessibility;
- physical-device test;

all pass.

---

# 82. Renderer Definition of Done

Renderer V1:

- one shared film model;
- three approved films;
- stable preview;
- acceptable full-res performance;
- correct color output;
- deterministic grain;
- renderer version persisted;
- regression suite active.

---

# 83. Persistence Definition of Done

- atomic source durability;
- source-safe invariant;
- recovery after kill;
- cache separation;
- schema version;
- migration tests.

---

# 84. Lab Definition of Done

- frame loads;
- film changes;
- exposure/process/grain;
- recipe persists;
- source immutable;
- export works;
- stale interactive renders cancel.

---

# 85. Gallery Definition of Done

- PhotosPicker;
- source resolution;
- color/orientation correct;
- source-unavailable state;
- shared renderer;
- export.

---

# 86. RAW Definition of Done

- capability-gated;
- valid RAW persisted;
- survives relaunch;
- decoder produces valid renderer input;
- re-development works;
- storage UX exists;
- RAW regression exists.

---

# 87. Calibration Definition of Done

- versioned profiles;
- first real target devices;
- generic fallback;
- cross-lens review;
- profile reference persisted with frame.

---

# 88. Release Hardening Tracks

## Reliability

- capture loops;
- interruption;
- recovery;
- low storage.

## Imaging

- regression;
- preview/final;
- skin;
- highlights;
- night.

## Performance

- startup;
- FPS;
- memory;
- thermal;
- full-resolution.

## Product

- onboarding;
- StoreKit;
- accessibility;
- localization;
- privacy.

---

# 89. Device Matrix Template

| Device | OS | Main | UW | Tele | RAW | Preview | Capture | Lab | Export |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Recent Pro | target | ✓ | ✓ | ✓ | ✓ | TBD | TBD | TBD | TBD |
| Recent base | target | ✓ | ✓ | varies | varies | TBD | TBD | TBD | TBD |
| Older baseline | minimum | ✓ | varies | varies | varies | TBD | TBD | TBD | TBD |

---

# 90. Release Candidate Manual Script

1. fresh install;
2. permission path;
3. capture;
4. select film;
5. shoot repeatedly;
6. switch lenses;
7. rotate;
8. background/foreground;
9. Lab;
10. re-develop;
11. import;
12. export;
13. Pro entitlement;
14. RAW where supported;
15. terminate during final render;
16. relaunch;
17. verify source/frame recovery.

---

# 91. Release Blockers

Never ship with:

- known frame loss;
- incorrect orientation;
- severe preview/final mismatch;
- wrong color-profile tagging;
- broken purchase entitlement;
- corrupted RAW;
- migration data loss;
- camera deadlock;
- common memory crash;
- cache cleanup deleting source.

---

# 92. Performance Targets

Targets must be confirmed on hardware.

## Camera readiness

- warm: perceptually near immediate;
- cold: target around <=1.5 s on primary hardware.

## Preview

- preferred 60 fps;
- stable 30 fps minimum.

## Shutter UI

Immediate feedback.

## Final render

May finish asynchronously after source safety.

---

# 93. Product Telemetry

Events:

```text
camera_ready
capture_requested
capture_source_safe
capture_complete
capture_failed
film_selected
lab_opened
film_redeveloped
import_completed
export_completed
raw_enabled
pro_purchase_completed
```

No image content.

---

# 94. Security

Imported image files are untrusted.

Validate:

- dimensions;
- decoder success;
- format;
- memory requirement;
- RAW support.

Use UUID-owned paths, not external filenames, for durable storage.

---

# 95. Architecture Gates

## Gate 1 — Camera

Is AVFoundation lifecycle owned by exactly one component?

## Gate 2 — Renderer

Do preview and final consume the same artistic model?

## Gate 3 — Persistence

Can the frame survive render/app failure?

## Gate 4 — RAW

Can source model represent paired sources without schema hack?

## Gate 5 — Beta

Can any known normal failure silently destroy a captured source?

---

# 96. First 20 Engineering Tickets

1. App environment / dependency container.
2. Native design tokens from HTML.
3. Camera screen native skeleton.
4. Camera permission service.
5. CameraSessionController.
6. Lens catalog.
7. VideoDataOutput pipeline.
8. Metal preview host.
9. Pixel-buffer → Metal texture.
10. Basic realtime tone/color shader.
11. Camera interruption recovery.
12. Plain still-photo capture.
13. CHEMFrame state model.
14. Frame file-store directories.
15. Atomic source persistence.
16. Capture correlation logging.
17. RenderDescriptor/version types.
18. FilmProfile loader.
19. DAY 200 prototype.
20. Preview/final comparison tool.

Do not start StoreKit before these are working.

---

# 97. Engineering Tickets 21–40

21. Full-resolution renderer.
22. Grain stage.
23. Bloom stage.
24. Halation stage.
25. SKIN 400 prototype.
26. NIGHT 800T prototype.
27. Regression image set.
28. Golden-render harness.
29. SwiftData frame repository.
30. Incomplete-frame recovery.
31. Last-frame thumbnail.
32. Lab native screen skeleton.
33. Interactive render scheduler.
34. Lab film switching.
35. Development exposure.
36. Push/pull.
37. Grain control.
38. Full export.
39. Photos save.
40. PhotosPicker import.

---

# 98. Engineering Tickets 41–60

41. Imported image color normalization.
42. HEIF/JPEG export options.
43. Film version persistence.
44. Renderer version persistence.
45. Render cache key.
46. Memory benchmark.
47. Thermal tiers.
48. RAW capability detector.
49. RAW capture.
50. RAW persistence.
51. RAW decode.
52. RAW regression fixtures.
53. DeviceProfile abstraction.
54. Generic DeviceProfile.
55. First real calibrated profile.
56. Pro Mode shell.
57. ISO.
58. shutter duration.
59. white balance.
60. manual focus.

---

# 99. Engineering Tickets 61–80

61. Final Film Shelf.
62. Expand production film library.
63. Film detail screen.
64. Favorite/default film.
65. Settings.
66. Storage management.
67. Permission/error states.
68. Accessibility pass.
69. StoreKit product loading.
70. Pro purchase.
71. Entitlement listener/restore behavior.
72. Feature gating.
73. Onboarding.
74. Privacy-safe telemetry.
75. Migration suite.
76. Low-storage hardening.
77. Device matrix.
78. Startup tuning.
79. GPU/memory optimization.
80. Public beta.

---

# 100. What To Build First

When implementation starts, first do:

```text
A. Extract HTML design tokens + Camera state inventory.
B. Rebuild Camera shell in SwiftUI.
C. Build CameraSessionController with zero film effects.
D. Feed camera frames into Metal.
E. Capture normal still photos reliably.
```

The first demo should look visually boring.

That is correct.

---

# 101. First Vertical Slice

After the foundation:

```text
Camera
 ↓
DAY 200 live preview
 ↓
Shutter
 ↓
source persisted
 ↓
DAY 200 final
 ↓
Lab
 ↓
switch to SKIN 400
 ↓
export
```

This proves the actual product thesis end-to-end.

---

# 102. Vertical Slice Exit Criteria

The slice is accepted only when:

- camera opens;
- DAY 200 is realtime;
- still source is durable;
- final output resembles live preview;
- frame opens in Lab;
- SKIN 400 can replace DAY;
- source remains immutable;
- export has correct orientation/color.

---

# 103. Technical Debt Rules

Temporary debt allowed:

- rough film tuning;
- incomplete settings polish;
- only 3 films.

Forbidden debt:

- save source only after final render;
- AVFoundation owned by SwiftUI view;
- unversioned frame schema;
- film without version;
- unrelated preview and final transforms;
- random grain without stored seed;
- image blobs in SwiftData;
- global mutable film renderer state.

---

# 104. Cut Order If Scope Is Tight

Protect:

1. capture reliability;
2. source persistence;
3. live preview;
4. final renderer;
5. re-development;
6. gallery workflow;
7. three excellent films.

Defer first:

- Rolls;
- batch;
- histogram;
- contact sheets;
- recipe sharing;
- front camera;
- advanced Pro UX.

---

# 105. Final Architecture

```text
                          ┌────────────────────┐
                          │      SwiftUI       │
                          │ Camera / Lab / UI  │
                          └─────────┬──────────┘
                                    │
                             Feature Models
                                    │
                          ┌─────────▼──────────┐
                          │    Domain Layer    │
                          │ Frames / Recipes   │
                          └─────┬───────┬──────┘
                                │       │
                   ┌────────────┘       └─────────────┐
                   │                                  │
        ┌──────────▼─────────┐             ┌──────────▼────────┐
        │     CameraCore     │             │      Imaging      │
        │    AVFoundation    │             │ Metal/Core Image  │
        └──────────┬─────────┘             └──────────┬────────┘
                   │                                  │
                   └────────────┬─────────────────────┘
                                │
                       CaptureCoordinator
                                │
                   ┌────────────▼────────────┐
                   │      Persistence       │
                   │ SwiftData + File Store │
                   └────────────┬────────────┘
                                │
             ┌──────────────────┼──────────────────┐
             │                  │                  │
          PhotoKit           StoreKit          Telemetry
```

---

# 106. Core System Invariants

## INV-01

`sourceSafe` implies a valid durable source.

## INV-02

Deleting cache never deletes source.

## INV-03

Film state is versioned film + recipe.

## INV-04

Preview and final use the same film semantics.

## INV-05

Device normalization happens before film character.

## INV-06

Full-resolution rendering never blocks `MainActor`.

## INV-07

No network dependency for capture.

## INV-08

RAW/manual features are runtime capability-gated.

## INV-09

App updates never silently change old public-frame look.

## INV-10

StoreKit/analytics failure never prevents capture.

---

# 107. Definition of Implementation Completion

A screen existing is not completion.

For a core feature, "done" means:

```text
UI
+ domain behavior
+ lifecycle
+ persistence
+ errors
+ recovery
+ performance
+ tests
+ logging
+ device verification
```

---

# 108. Companion Engineering Docs

Maintain alongside this plan:

```text
/docs/
  CHEM_PRD.md
  CHEM_IMPLEMENTATION_PLAN.md
  SYSTEM_ARCHITECTURE.md
  MODULE_CONTRACTS.md
  DATA_MODEL.md
  RENDERER_SPEC.md
  COLOR_PIPELINE.md
  DEVICE_CALIBRATION.md
  QA_MATRIX.md
  RELEASE_CHECKLIST.md
  DECISIONS/
    ADR-001-native-swiftui.md
    ADR-002-metal-renderer.md
    ADR-003-frame-storage.md
```

---

# 109. Initial ADRs

- ADR-001: Native SwiftUI, not runtime HTML/WKWebView.
- ADR-002: AVFoundation directly owns capture.
- ADR-003: Metal is primary artistic renderer.
- ADR-004: SwiftData metadata + filesystem pixels.
- ADR-005: Source persistence precedes final rendering.
- ADR-006: Renderer/film/device/schema are versioned.
- ADR-007: Core product is offline-first.

---

# 110. Technical Alpha Demo

A good Technical Alpha can:

1. open CHEM;
2. show camera;
3. switch lens;
4. select SKIN 400;
5. show live look;
6. tap focus/exposure;
7. shoot several photos;
8. open last frame;
9. change to NIGHT 800T;
10. push process +1;
11. force-quit;
12. reopen;
13. preserve frame/recipe;
14. export to Photos;
15. verify orientation/color.

If this works robustly, the architecture is healthy.

---

# 111. Public Beta Entry Criteria

Before external TestFlight:

- stable camera session;
- no known source-loss bug;
- frame recovery works;
- 3–5 strong films;
- preview/final acceptable;
- Lab stable;
- gallery import stable;
- export stable;
- common full-res images do not crash memory;
- RAW can remain disabled if not ready;
- privacy story is accurate.

---

# 112. V1 Ship Criteria

- final film set approved;
- capture safety validated;
- target device matrix completed;
- color output verified;
- purchase verified;
- migration verified;
- offline verified;
- accessibility verified;
- privacy labels accurate;
- beta crash/reliability quality acceptable;
- no release blockers.

---

# 113. Final Build Order

```text
01. Native design foundation
02. Camera session
03. Metal preview infrastructure
04. Plain still capture reliability
05. Transactional source persistence
06. Shared render graph
07. Three-film engine
08. Versioned frame model
09. Lab / re-development
10. Photos import/export
11. Regression/performance tooling
12. RAW/ProRAW
13. Device/lens calibration
14. Pro manual controls
15. Expand film library
16. StoreKit/settings/onboarding
17. Accessibility/privacy/telemetry
18. Device hardening
19. Beta
20. V1
```

---

# 114. Final Engineering Principle

CHEM is a **camera/imaging system**, not a filter UI project.

The HTML design defines how the app feels, but product quality depends on invisible infrastructure:

```text
camera lifecycle
+ source safety
+ Metal performance
+ color pipeline
+ versioned film semantics
+ deterministic rendering
+ device calibration
```

The implementation team should prioritize using this rule:

> **A beautiful frame is valuable only after CHEM can guarantee the frame exists.**

Then:

> **One excellent, consistent film pipeline is more valuable than fifty superficial presets.**

---

# Appendix A — Ownership Matrix

| Module | Owns | Must Not Own |
|---|---|---|
| CameraFeature | UI state/intents | raw AVFoundation session |
| CameraCore | session/devices/capture | film artistic state |
| CaptureCoordinator | capture transaction | SwiftUI |
| ChemRenderer | pixel transform | persistence policy |
| FilmLibrary | film definitions | user frame DB |
| FrameRepository | metadata/source state | camera config |
| RenderScheduler | render priority | navigation |
| PhotoLibraryService | Photos | film engine |
| EntitlementStore | Pro entitlement | camera correctness |
| Telemetry | non-sensitive events | feature dependency |

---

# Appendix B — Failure Ownership

| Failure | Owner | Recovery |
|---|---|---|
| Camera denied | Permissions/CameraFeature | Gallery + Settings |
| Session interrupted | CameraCore | resume |
| Sensor capture failed | CaptureCoordinator | retry |
| Source write failed | Persistence | capture failure |
| Final render failed | Renderer | source retained, retry |
| Photos save failed | PhotoLibraryService | CHEM frame retained |
| Import source missing | Gallery | unavailable state |
| RAW unsupported | Capability service | hide mode |
| Film invalid | FilmLibrary | CI/build failure |
| Store unavailable | EntitlementStore | camera remains available |

---

# Appendix C — Debug Flags

```text
CHEM_DEBUG_RENDER_STAGES
CHEM_SHOW_PERF_HUD
CHEM_ENABLE_RAW
CHEM_ENABLE_SCENE_ANALYSIS
CHEM_ENABLE_DEVICE_PROFILE
CHEM_ENABLE_PRO_CONTROLS
CHEM_SIMULATE_LOW_STORAGE
CHEM_SIMULATE_RENDER_FAILURE
```

---

# Appendix D — Render Job Example

```swift
struct RenderJob: Identifiable, Sendable {
    enum Priority: Int, Sendable {
        case batch = 0
        case backgroundFinal = 1
        case postCapture = 2
        case interactive = 3
    }

    let id: UUID
    let frameID: UUID
    let input: RenderInput
    let descriptor: RenderDescriptor
    let quality: RenderQuality
    let priority: Priority
}
```

---

# Appendix E — Frame State Example

```swift
enum FrameState: String, Codable, Sendable {
    case pendingCapture
    case sourceSafe
    case previewReady
    case finalRenderPending
    case rendered
    case exportPending
    case complete
    case recoverableError
    case captureFailed
}
```

---

# Appendix F — Capture Metadata Example

```swift
struct CaptureMetadata: Codable, Sendable {
    let deviceModel: String
    let lensID: String
    let iso: Float?
    let exposureDurationSeconds: Double?
    let exposureCompensationEV: Float?
    let whiteBalanceKelvin: Float?
    let orientation: Int
    let width: Int
    let height: Int
    let capturedAt: Date
}
```

---

# Appendix G — Review Questions

At every milestone ask:

1. What if the app dies at the worst possible moment?
2. Which state is durable?
3. Which actor owns this mutable resource?
4. Can this block the camera?
5. Can this allocate multiple full-res buffers?
6. Does this survive app update?
7. Is artistic behavior versioned?
8. Does a different lens break assumptions?
9. Can the user recover?
10. What evidence proves completion?

---

# Appendix H — Three Prototypes

## Prototype 1 — Plain camera

Prove AVFoundation lifecycle and capture.

## Prototype 2 — Live film

Prove Metal performance.

## Prototype 3 — Full vertical slice

Prove:

```text
live film
→ capture
→ source safe
→ final render
→ Lab
→ re-develop
→ export
```

Only after Prototype 3 should scope expand aggressively.

---

# Appendix I — Release Smoke Checklist

```text
[ ] cold launch
[ ] warm launch
[ ] rapid capture
[ ] all lenses
[ ] orientation
[ ] background/foreground
[ ] interruption recovery
[ ] source recovery
[ ] render-failure recovery
[ ] gallery import
[ ] P3 source
[ ] export
[ ] low storage
[ ] Pro entitlement
[ ] offline
[ ] schema migration
```

---

# Appendix J — Architecture Success Test

The architecture is successful when adding a new film primarily requires:

- a versioned film resource;
- visual/regression validation;

and does not require modifying:

- Camera UI;
- AVFoundation capture;
- PhotoKit;
- frame schema;
- a separate preview-specific filter.

Likewise:

- adding a new device profile should not modify films;
- adding RAW should not redefine Lab semantics;
- changing UI should not rewrite capture transaction logic.

That separation is the intended architecture.

---

# References / Implementation Notes

The implementation plan assumes current Apple platform capabilities and should be checked against the exact Xcode/iOS deployment target when implementation begins. Relevant Apple platform areas include:

- AVFoundation still-photo capture and camera session APIs.
- Metal / Metal Performance Shaders for GPU processing and image statistics.
- SwiftData `ModelContainer`, schema configuration, and migration plans.
- StoreKit 2 current-entitlement and transaction-update APIs.
- PhotoKit / system photo picker for user-selected photo access.

Apple documents SwiftData `ModelContainer` as the component managing schema-backed storage and schema migration, including explicit migration plans when automatic migration is insufficient. Apple also positions Metal Performance Shaders as optimized GPU kernels for image processing/statistics, which can complement custom Metal shaders where appropriate. StoreKit 2 uses Swift concurrency and verified transaction/entitlement flows; transaction updates should be listened to across app launches so entitlements remain current.

---

**End of CHEM iOS Core Features Implementation Plan v1.0**

# CHEM — Product Requirements Document (PRD)

> **Working product name:** CHEM  
> **Tagline:** Digital camera. Film chemistry.  
> **Document version:** 1.0  
> **Status:** Draft for product + engineering kickoff  
> **Platform:** iPhone / iOS  
> **Primary product type:** Camera-first film simulation app  
> **Primary language of implementation:** Swift  
> **Core graphics stack:** AVFoundation + Metal + Core Image  
> **Business model:** Free tier + one-time Pro unlock  
> **Core principle:** Shoot more. Edit less.

---

# 0. Document Purpose

This PRD defines the product, interaction model, technical constraints, system behavior, feature scope, quality bars, acceptance criteria, and phased delivery plan for **CHEM**, an iPhone camera application designed to provide a high-quality digital film photography experience.

CHEM is not intended to be another general-purpose photo editor with hundreds of filters.

The product is designed around a narrower promise:

> A user should be able to open CHEM, choose a film stock, see the intended look live, take a photo, and be confident that the rendered result will preserve the character they saw in the viewfinder.

The application also preserves a digital negative whenever possible so that the same frame can be re-developed later using a different film stock without destructively degrading the source.

This document is intended to be detailed enough for:

- Product management
- UX/UI design
- iOS engineering
- Imaging / computational photography engineering
- QA
- Growth / App Store preparation
- Privacy review
- Beta testing
- Coding-agent orchestration
- Architecture review

---

# 1. Executive Summary

CHEM is a **camera-first digital film application for iPhone**.

The product combines:

1. Live film rendering before capture.
2. A minimal camera interface.
3. A curated library of CHEM film stocks.
4. Non-destructive capture and development.
5. Gallery import.
6. Device-aware normalization.
7. A deterministic film rendering engine.
8. Optional RAW / ProRAW preservation when supported.
9. Simple analog-oriented adjustments rather than Lightroom-style editing.
10. Local-first processing with no mandatory account.

The target experience is closer to using a physical camera with a chosen film stock than opening a conventional image editor.

The user should think:

> “I shoot with CHEM.”

not:

> “I edit with CHEM.”

---

# 2. Product Vision

## 2.1 Long-term vision

CHEM aims to become:

> **The software equivalent of a dedicated film-oriented camera on iPhone.**

The product should become a habitual capture tool rather than an occasional post-processing utility.

The long-term ambition is to own a recognizable visual language through proprietary CHEM film stocks, device calibration, rendering consistency, and product taste.

---

## 2.2 Product identity

CHEM should feel:

- deliberate;
- quiet;
- photographic;
- fast;
- tactile;
- trustworthy;
- technically sophisticated;
- visually minimal.

CHEM should not feel:

- gimmicky;
- toy-like;
- overloaded;
- social-first;
- AI-first;
- editor-first;
- subscription-heavy;
- retro-for-the-sake-of-retro.

---

# 3. Product Thesis

CHEM is built around five product theses.

## 3.1 Photography apps do not necessarily need more controls

Many users want better photographic character without needing:

- HSL panels;
- RGB curves;
- masks;
- layers;
- complex local adjustment;
- dozens of effect sliders.

CHEM hides complexity inside the imaging engine.

---

## 3.2 A film look should behave like a process, not a static LUT

The same film stock should respond differently to:

- bright highlights;
- shadows;
- skin;
- tungsten light;
- daylight;
- neon;
- overexposure;
- underexposure.

Therefore, film rendering should be a parametric pipeline rather than only:

`image -> LUT -> grain overlay`.

---

## 3.3 Live preview and final render must be visually consistent

CHEM treats:

- live preview;
- capture preview;
- final image;
- gallery development;

as different execution modes of the same rendering model.

There should not be an unrelated “fast camera filter” and “high quality export filter”.

---

## 3.4 Original capture data must be preserved whenever practical

The user should be able to change their mind later.

CHEM should preserve:

- source image;
- source metadata;
- device profile;
- lens profile;
- film recipe;
- renderer version.

This makes re-development deterministic and non-destructive.

---

## 3.5 The strongest moat is not feature count

CHEM should not attempt to beat competitors by shipping 100 filters.

The long-term defensibility comes from:

- device calibration;
- film profiling;
- rendering behavior;
- output consistency;
- regression datasets;
- film stock identity;
- camera reliability;
- brand.

---

# 4. Goals

## 4.1 Product goals

### G-01 — Become an everyday camera

Users should feel comfortable using CHEM for daily photography.

### G-02 — Deliver recognizable film character

Each CHEM stock should look meaningfully different from the others.

### G-03 — Minimize friction from launch to capture

The user should be able to open the app and shoot immediately.

### G-04 — Make live preview trustworthy

The preview should be perceptually close to the final render.

### G-05 — Preserve optionality

Users should be able to re-develop captured photos later.

### G-06 — Keep the interface simple

Advanced imaging sophistication should not create a complicated default UI.

### G-07 — Work offline

The core camera and development workflow should not require a network connection.

### G-08 — Respect privacy

No mandatory account, no photo upload requirement, no advertising tracking.

### G-09 — Build a scalable imaging foundation

The engine architecture should support:

- new film stocks;
- additional iPhone devices;
- video in future;
- additional output formats;
- improved calibration;
- recipes.

---

# 5. Non-Goals

The following are explicitly out of scope for the first public release.

## NG-01 — General Lightroom replacement

CHEM will not provide:

- full RGB curve editing;
- full HSL panel;
- masks;
- local brush adjustments;
- clone/heal;
- perspective correction suite;
- compositing.

## NG-02 — Social network

No:

- follower graph;
- feed;
- likes;
- comments;
- public profiles.

## NG-03 — Generative image editing

No generative replacement of:

- people;
- faces;
- backgrounds;
- objects;
- skies;
- clothes.

## NG-04 — Beauty camera

No:

- face reshaping;
- skin whitening;
- eye enlargement;
- body reshaping.

## NG-05 — Fake camera collection

CHEM is not a library of simulated disposable-camera shells.

## NG-06 — Mandatory cloud

Users must not be forced to upload photos to use the app.

## NG-07 — Video in initial release

Video is deferred until still-photo architecture is stable.

---

# 6. Product Principles

Every proposed feature should be evaluated against these principles.

## P-01 — Camera first

Opening CHEM should open the camera by default.

## P-02 — One engine

Capture, re-development, and gallery processing use the same film engine.

## P-03 — Minimal by default

Do not expose advanced controls unless requested.

## P-04 — Non-destructive by design

Preserve source + recipe instead of repeatedly baking edits.

## P-05 — Film language over editor language

Prefer:

- film;
- process;
- exposure;
- grain;
- warmth;
- roll;
- develop;

instead of:

- preset stack;
- LUT intensity;
- color grading;
- layered adjustments.

## P-06 — Reliability over novelty

Never trade photo-save reliability for a visual trick.

## P-07 — Deterministic output

The same:

`source + recipe + device profile + renderer version`

should produce the same result.

## P-08 — Fast enough to disappear

The app should feel like a camera, not a rendering workstation.

---

# 7. Target Users

## 7.1 Persona A — Everyday aesthetic photographer

### Profile

- Age: roughly 18–35
- Shoots travel, people, cafe, street, daily life
- Uses Apple Camera, VSCO, Dazz, Fimii, Lightroom Mobile, or similar
- Likes film aesthetics
- Does not want to learn advanced color grading

### Pain points

- Too many filters.
- Too much post-processing.
- Hard to maintain a consistent aesthetic.
- Camera and editor are often separate workflows.
- Some film apps feel gimmicky.
- Some professional apps feel overwhelming.

### Desired outcome

> “I want to take photos that already look right.”

---

## 7.2 Persona B — Photographer who wants finished color at capture

### Profile

- Understands ISO, shutter, WB, exposure
- Values RAW
- May use dedicated cameras
- Wants strong visual character directly from iPhone

### Pain points

- iPhone stock output can feel computational.
- RAW workflow takes too long.
- Pro camera apps often lack strong film identity.
- Film apps often lack reliability and technical controls.

### Desired outcome

> “Give me a serious camera that already understands the look I want.”

---

## 7.3 Persona C — Existing-photo developer

### Profile

- Has photos already in Apple Photos
- Wants one coherent look for an album or trip
- Often edits 10–100 photos at a time

### Pain points

- Repeating edits manually.
- Different presets respond inconsistently.
- Difficult to get one cohesive result across mixed scenes.

### Desired outcome

> “I want to develop a whole set with one visual language.”

---

# 8. Jobs To Be Done

## JTBD-01

When I see a moment worth capturing, I want to open a camera that already has the visual style I like so I can take the photo immediately without editing later.

## JTBD-02

When I am unsure which film character fits a scene, I want to preview multiple stocks live so I can decide before taking the photo.

## JTBD-03

When I later dislike the film I originally chose, I want to re-develop the same image from the original source.

## JTBD-04

When I have an existing image in Photos, I want to process it with the same CHEM film engine used by the camera.

## JTBD-05

When I shoot an entire day or trip, I want to keep the visual identity consistent.

## JTBD-06

When I want manual control, I want ISO/shutter/WB/focus without turning the entire interface into a pro-control dashboard.

---

# 9. Success Metrics

CHEM should not optimize primarily for session duration.

A camera app should help the user leave the app with a photo.

## 9.1 North-star metric

### NSM

**Weekly active shooters who capture at least 5 CHEM photos in a week.**

This measures whether CHEM becomes a real camera habit.

---

## 9.2 Core product metrics

### M-01 — Camera reuse

Percentage of first-week users who return and take photos on 3 or more separate days.

### M-02 — Photos per active shooter

Median captured frames per weekly active shooter.

### M-03 — Time to first shot

From app foreground-ready to shutter press.

### M-04 — Favorite-film concentration

Percentage of users who develop a stable favorite stock.

### M-05 — Re-develop rate

Percentage of CHEM frames re-developed with another stock.

### M-06 — Gallery development rate

Percentage of active users who process imported photos.

### M-07 — Export / save success

Successful rendered-photo save rate.

### M-08 — Crash-free capture sessions

Critical reliability metric.

### M-09 — Failed capture rate

Capture attempts that do not produce a recoverable source.

### M-10 — Preview/final consistency score

Internal perceptual consistency benchmark.

---

# 10. Product Scope by Release

## 10.1 Technical prototype

Must prove:

- camera input;
- Metal live rendering;
- final rendering;
- 3 prototype film stocks;
- frame capture;
- acceptable latency.

No polished UI required.

---

## 10.2 Internal MVP

Includes:

- Camera
- Live preview
- 3 films
- Photo saving
- Lens switching
- EV compensation
- Focus/exposure
- Gallery import
- Re-development
- CHEM metadata

---

## 10.3 Public V1

Includes:

- 8 film stocks
- CHEM Lab
- Free/Pro model
- RAW/ProRAW support where available
- Device normalization
- Push/pull
- Grain control
- Pro Mode
- Rolls
- Privacy settings
- Full onboarding
- Accessibility
- App Store readiness

---

## 10.4 V1.5

Candidate scope:

- batch develop;
- recipe save;
- recipe import/export;
- widgets;
- Lock Screen quick launch;
- richer metadata view.

---

## 10.5 V2

Candidate scope:

- recipe sharing;
- advanced Film Maker;
- expanded device profiling;
- contact sheets;
- improved calibration engine;
- iCloud recipe sync.

---

## 10.6 V3

Candidate scope:

- video;
- temporal film grain;
- temporal halation;
- Apple Log input;
- advanced reference-match tools.

---

# 11. Navigation Model

CHEM uses three primary destinations:

1. **Camera**
2. **Lab**
3. **Films**

Optional fourth destination:

4. **Settings**

The app must not use a heavy multi-tab application shell that makes the camera feel secondary.

Recommended navigation:

- Camera = root/default.
- Swipe or bottom action for Lab.
- Tap active film name for Films.
- Settings accessed from camera top bar.

---

# 12. Information Architecture

```text
CHEM
├── Camera
│   ├── Viewfinder
│   ├── Film selector
│   ├── Lens selector
│   ├── Exposure
│   ├── Flash
│   ├── Pro controls
│   └── Last frame
│
├── Lab
│   ├── CHEM frames
│   ├── Imported photos
│   ├── Frame detail
│   ├── Film switching
│   ├── Process
│   ├── Exposure
│   ├── Grain
│   └── Export
│
├── Films
│   ├── Film shelf
│   ├── Film detail
│   └── Favorite film
│
├── Rolls
│   ├── Roll list
│   ├── Roll detail
│   └── Contact sheet
│
└── Settings
    ├── Capture
    ├── Negative storage
    ├── Pro Mode
    ├── Save behavior
    ├── Haptics
    ├── Privacy
    ├── Color/export
    └── About
```

---

# 13. Onboarding

## 13.1 Requirements

Onboarding must:

- take less than 30 seconds;
- require no account;
- explain the camera mental model;
- explain negative preservation;
- request permissions only when contextually needed.

---

## 13.2 Screen 1 — Choose a film

Headline:

> Choose a film.

Body:

> CHEM changes how light becomes color before you take the photo.

Action:

`Continue`

---

## 13.3 Screen 2 — Shoot what you see

Headline:

> Shoot what you see.

Body:

> Your selected film is rendered directly in the viewfinder.

---

## 13.4 Screen 3 — Your negative stays yours

Headline:

> Your negative stays yours.

Body:

> Change the film later without losing the original frame.

---

## 13.5 Screen 4 — Camera permission

Permission should only be requested immediately before entering camera.

If denied:

- show non-blocking explanation;
- allow Gallery-only mode;
- provide Settings deep-link.

---

# 14. Camera — Functional Requirements

## CAM-001 — Camera is default launch destination

**Priority:** P0

### Requirement

When camera permission is granted, opening CHEM lands directly in the camera interface.

### Acceptance criteria

- No feed or dashboard appears before camera.
- Warm launch restores previously used film.
- Previous valid lens selection is restored when possible.

---

## CAM-002 — Live film preview

**Priority:** P0

### Requirement

The currently selected CHEM film must be visible in the viewfinder in real time.

### Acceptance criteria

- Preview uses the same renderer parameter graph as final render.
- Minimum acceptable preview performance: stable 30 fps.
- Target performance on supported recent devices: 60 fps.
- Preview must recover gracefully after app interruption.

---

## CAM-003 — Shutter capture

**Priority:** P0

### Requirement

Shutter button captures a frame immediately.

### Acceptance criteria

- Tap receives immediate visual feedback.
- Haptic feedback occurs within perceived instant response.
- Captured frame is queued even if final render is still processing.
- UI must not falsely indicate success before a recoverable source exists.

---

## CAM-004 — Lens switching

**Priority:** P0

### Requirement

Users can switch between available physical camera lenses.

### UX

Common labels:

- `.5×`
- `1×`
- `2×`
- tele factor based on hardware

### Acceptance criteria

- Only actually available camera factors are shown.
- Unsupported lens transitions are hidden or disabled.
- Film rendering remains active through lens switch.
- Active device/lens calibration profile changes accordingly.

---

## CAM-005 — Tap focus and exposure

**Priority:** P0

### Requirement

Tap on viewfinder sets focus/exposure point where supported.

### Acceptance criteria

- Focus indicator is visible.
- Indicator fades without blocking composition.
- Exposure changes do not reset selected film.

---

## CAM-006 — AE/AF lock

**Priority:** P1

Long press locks auto exposure/focus.

Unlock by:

- tap elsewhere;
- explicit lock control;
- lens change;
- camera session reset.

---

## CAM-007 — EV compensation

**Priority:** P0

User can adjust exposure compensation.

### Recommended range

`-2.0 EV to +2.0 EV`

Device constraints may vary.

### UX

Swipe vertically on viewfinder or tap compact EV control.

### Acceptance criteria

- EV appears temporarily while changing.
- EV is stored in frame metadata.
- EV affects final render consistently.

---

## CAM-008 — Flash

**Priority:** P1

Modes:

- Off
- Auto
- On

Future:

- torch as composition aid.

---

## CAM-009 — Last-frame thumbnail

**Priority:** P0

Bottom corner shows last captured CHEM frame.

Tap opens Lab frame detail.

---

## CAM-010 — Film selector

**Priority:** P0

Active film name is always visible.

Examples:

`SKIN 400`
`DAY 200`

User can:

- tap to open Film Shelf;
- swipe horizontally through films.

---

# 15. Camera — UI Specification

Default interface should contain no more than essential controls.

## 15.1 Top bar

Possible controls:

- flash;
- settings;
- optional Pro Mode indicator.

Avoid more than 3 simultaneous top-level controls.

---

## 15.2 Viewfinder

The viewfinder should occupy as much vertical area as possible.

No decorative fake camera body.

No thick borders unless required for aspect ratio.

---

## 15.3 Bottom area

Contains:

- last frame;
- shutter;
- film entry;
- lens selector.

Shutter remains the dominant visual control.

---

# 16. Pro Mode

## PRO-001 — Pro Mode is opt-in

Default = off.

Enable in Settings or contextual shortcut.

---

## PRO-002 — Manual ISO

Available only when supported by capture session.

---

## PRO-003 — Manual shutter speed

Must respect camera device limits.

UI should avoid arbitrary unsupported values.

---

## PRO-004 — Manual white balance

Controls:

- Kelvin
- Tint

Optional presets:

- Daylight
- Cloudy
- Tungsten

---

## PRO-005 — Manual focus

Use normalized focus distance control.

Optional focus peaking deferred unless quality is strong.

---

## PRO-006 — Histogram

Optional in V1 if performance allows.

Default hidden.

---

# 17. Film Shelf

The Film Shelf is a core product surface.

## 17.1 Design goals

The shelf should feel curated, not infinite.

Every film should have:

- name;
- speed/identity;
- short character description;
- recommended use;
- live preview.

---

## FILM-001 — Film list

Initial V1 library:

1. DAY 200
2. SKIN 400
3. STREET 400
4. SOFT 160
5. CINE 250D
6. NIGHT 800T
7. SLIDE 50
8. MONO 400

Names are working names until brand/legal review.

---

## FILM-002 — Film detail

Each film detail page includes:

### Identity

Name and type.

Example:

`SKIN 400`
`Color Negative`

### Character

Example:

- soft contrast;
- gentle warmth;
- natural reds;
- fine grain;
- broad highlight latitude.

### Recommended scenes

- portrait;
- golden hour;
- people;
- daylight.

### Live scene preview

Show current camera feed if camera permission exists.

---

## FILM-003 — Favorite film

User can mark one favorite.

Favorite film may become default launch film.

---

## FILM-004 — Film ordering

Default curated order.

Optional user reorder deferred.

---

# 18. Film Definitions

A FilmProfile should not be represented only by a LUT path.

Conceptual model:

```swift
struct FilmProfile {
    let id: FilmID
    let version: Int
    let displayName: String
    let isoCharacter: Int?
    let category: FilmCategory
    let toneModel: ToneModel
    let colorModel: ColorModel
    let highlightModel: HighlightModel
    let shadowModel: ShadowModel
    let grainModel: GrainModel
    let halationModel: HalationModel
    let bloomModel: BloomModel
    let defaultProcess: ProcessSetting
    let supportedInputRanges: InputCapability
}
```

Actual implementation may use GPU-friendly packed resources.

---

# 19. Initial Film Behavior Definitions

These are product-direction definitions, not final scientific profiles.

## 19.1 DAY 200

Character:

- warm-neutral;
- moderate saturation;
- fine grain;
- gentle highlight compression;
- low-moderate contrast.

Purpose:

Everyday daylight stock.

---

## 19.2 SKIN 400

Character:

- skin-priority color response;
- warm but restrained;
- soft contrast;
- subtle red/orange protection;
- fine-to-medium grain;
- broad highlights.

Purpose:

People and portraits.

---

## 19.3 STREET 400

Character:

- moderate contrast;
- cooler shadows;
- slightly restrained saturation;
- medium grain;
- stronger local separation.

Purpose:

street, architecture, urban scenes.

---

## 19.4 SOFT 160

Character:

- pastel;
- low contrast;
- gentle colors;
- soft bloom;
- fine grain.

Purpose:

portrait, cloudy light, romantic scenes.

---

## 19.5 CINE 250D

Character:

- cinema-inspired response;
- natural daylight balance;
- dense but controlled colors;
- smooth shoulder;
- subtle halation.

Purpose:

cinematic daylight scenes.

---

## 19.6 NIGHT 800T

Character:

- tungsten bias;
- cyan/blue shadow behavior;
- stronger grain;
- visible highlight halation;
- controlled neon rendering.

Purpose:

night, signage, indoor tungsten.

---

## 19.7 SLIDE 50

Character:

- saturated;
- deep blacks;
- lower latitude;
- crisp color separation;
- low grain.

Purpose:

landscape and daylight color.

---

## 19.8 MONO 400

Character:

- black-and-white;
- medium grain;
- moderate contrast;
- controllable highlight roll-off.

Purpose:

documentary and street.

---

# 20. CHEM Frame Model

A CHEM frame is not only an exported image.

It is a reconstructable photographic state.

## 20.1 Required frame metadata

```text
CHEMFrame
├── id
├── createdAt
├── sourceAssetType
├── sourceAssetReference
├── localSourcePath
├── sourceChecksum
├── cameraDeviceModel
├── cameraLensIdentifier
├── captureSettings
├── deviceProfileVersion
├── filmProfileID
├── filmProfileVersion
├── recipe
├── rendererVersion
├── grainSeed
├── previewPath
├── renderedAssetPath
├── PhotosAssetIdentifier?
└── rollID?
```

---

# 21. Digital Negative

## NEG-001 — Preserve source

If CHEM captured the photo, the source representation must be recoverable until user deletes it.

Possible source types:

- HEIF source;
- JPEG source;
- RAW DNG;
- Apple ProRAW;
- paired RAW + processed.

---

## NEG-002 — Storage modes

### Standard

Stores:

- high-quality source;
- metadata;
- rendered result.

### Negative

When supported:

- RAW/ProRAW;
- metadata;
- rendered result.

---

## NEG-003 — Storage transparency

Settings should show:

- current source mode;
- approximate storage impact;
- whether RAW is supported.

---

# 22. Re-Development

## DEV-001 — Change film after capture

User opens CHEM frame in Lab and switches film.

### Acceptance criteria

- Original source remains unchanged.
- New result is rendered from source.
- Previous recipe may be restored.
- Export does not overwrite source unless explicitly requested.

---

## DEV-002 — Determinism

Given same source + metadata + engine version + recipe, output should be byte-stable where practical, or perceptually identical if platform-level encoding introduces differences.

---

# 23. CHEM Lab

Lab is intentionally not called “Editor”.

## 23.1 Default controls

Allowed V1 controls:

- Film
- Exposure
- Process
- Grain

Optional:

- Warmth
- Crop
- Straighten

Avoid full professional editing panels.

---

## LAB-001 — Film switching

Horizontal film carousel.

Must update preview interactively.

---

## LAB-002 — Exposure

Recommended range:

`-2 to +2 EV`

This is post-capture rendering exposure, not capture exposure.

Store separately from original capture EV.

---

## LAB-003 — Process

User-facing values:

- Pull -1
- Normal
- Push +1

Optional future:

-2, +2

A process change can affect multiple rendering dimensions:

- tone;
- grain;
- saturation;
- shoulder;
- toe.

---

## LAB-004 — Grain

Values:

- Fine
- Normal
- Rough

Avoid numeric opacity unless needed internally.

---

## LAB-005 — Before/after

Press-and-hold to temporarily show source-normalized view or original.

---

## LAB-006 — Export

Options:

- Save Copy
- Share
- Export JPEG
- Export HEIF

Advanced export settings in Settings, not every time.

---

# 24. Gallery Import

## GAL-001 — Import from Photos

Use PhotosPicker.

User should not need full-library access where limited picker access is sufficient.

---

## GAL-002 — Supported formats

V1 target:

- HEIF/HEIC
- JPEG
- supported RAW formats
- ProRAW/DNG where readable

---

## GAL-003 — Same film engine

Imported photos must use the same FilmProfile and renderer path as captured CHEM frames after input normalization.

---

## GAL-004 — Import strategy

Do not duplicate the entire original unnecessarily.

Store:

- asset identifier when safe;
- metadata;
- thumbnail/cache;
- recipe.

If source access may disappear, allow “Keep source inside CHEM”.

---

# 25. Rolls

A Roll is a creative organizational container.

## ROLL-001 — Create roll

Fields:

- title;
- default film;
- optional note;
- date range.

---

## ROLL-002 — Active roll

When active, new CHEM frames are assigned automatically.

---

## ROLL-003 — Roll film

A roll can have a default film, but user may override individual frames.

---

## ROLL-004 — Contact sheet

Generate visual contact sheet.

V1 optional; V1.5 recommended.

---

# 26. Recipes

A recipe customizes a film.

## Recipe schema

```swift
struct FilmRecipe: Codable {
    let filmID: String
    let filmVersion: Int

    var exposureOffset: Float
    var process: ProcessSetting
    var grainStyle: GrainStyle
    var warmthBias: Float

    var rendererVersion: String
}
```

Future recipe fields must be backwards-compatible.

---

# 27. Recipe Versioning

Recipe reproducibility requires version management.

If FilmProfile changes:

- existing frame retains original film profile version;
- user may optionally migrate to newest version;
- migration should create a new recipe revision.

Never silently alter old photos.

---

# 28. Device-Aware Rendering

This is a core CHEM differentiator.

## 28.1 Problem

Different iPhone models and lenses may differ in:

- sensor;
- lens;
- ISP;
- tone mapping;
- noise processing;
- white balance;
- sharpening;
- dynamic range.

Applying the same transform may not produce the same visual result.

---

## 28.2 DeviceProfile

Conceptual structure:

```swift
struct DeviceProfile {
    let deviceModel: String
    let cameraID: String
    let profileVersion: Int

    let inputColorTransform: ColorTransform
    let toneNormalization: ToneNormalization
    let whiteBalanceCompensation: WBModel
    let lensCharacterization: LensModel?
}
```

---

## 28.3 Calibration priority

Initial supported profiles should focus on current and recent high-usage iPhones.

Fallback behavior for unsupported devices:

- generic profile;
- clearly tested safe transform;
- no crash;
- no incorrect assumption.

---

# 29. Calibration Dataset

Each supported camera/lens profile should be calibrated using controlled and real-world samples.

## 29.1 Controlled targets

- ColorChecker-style target
- neutral gray scale
- saturation patches
- highlight step wedge
- skin-tone references

---

## 29.2 Lighting conditions

Minimum:

- daylight/D65-style;
- cloudy;
- warm tungsten;
- warm LED;
- cool LED;
- mixed indoor light.

---

## 29.3 Scene categories

- skin;
- foliage;
- blue sky;
- red fabric;
- neon;
- reflective highlights;
- high dynamic range;
- deep shadow;
- neutral architecture.

---

# 30. Scene Analyzer

Scene analysis must not generate pixels.

It estimates rendering context.

## Inputs may include

- luminance histogram;
- highlight occupancy;
- white balance estimate;
- dominant chroma;
- skin-likelihood mask/statistics;
- local contrast;
- global contrast;
- shadow saturation;
- clipped region estimate.

---

## 30.1 Determinism

Scene analyzer output must be deterministic for identical source data and model version.

---

## 30.2 On-device only

V1 scene analysis must run locally.

---

# 31. CHEM Rendering Pipeline

Recommended conceptual pipeline:

```text
Input
  ↓
Decode / RAW development
  ↓
Camera/device normalization
  ↓
Linear working space
  ↓
Exposure normalization
  ↓
White balance / chromatic adaptation
  ↓
Film exposure response
  ↓
Tone / density transform
  ↓
Color response
  ↓
Highlight shoulder
  ↓
Shadow toe
  ↓
Bloom
  ↓
Halation
  ↓
Grain
  ↓
Output color transform
  ↓
Display P3 HEIF / sRGB JPEG
```

---

# 32. Rendering Engine Requirements

## ENG-001 — Shared parameter graph

Preview and final render use same FilmProfile semantics.

---

## ENG-002 — Precision

Use sufficient floating-point precision internally to avoid banding and transform accumulation artifacts.

---

## ENG-003 — Wide-gamut support

Prefer wide-gamut intermediate space where device pipeline permits.

---

## ENG-004 — Grain

Grain must:

- vary spatially;
- respect output scale;
- remain deterministic using grain seed;
- avoid appearing as a transparent PNG texture.

---

## ENG-005 — Halation

Halation should be highlight-dependent.

Avoid uniform red glow.

---

## ENG-006 — Bloom

Bloom should respond to luminance and local context.

Avoid haze over dark regions.

---

## ENG-007 — Tone response

Tone model should support nonlinear toe and shoulder.

---

# 33. Preview vs Final Render

## 33.1 Preview mode

Target:

- 60 fps preferred;
- 30 fps minimum stable baseline.

Preview may lower:

- resolution;
- sample count;
- blur kernel complexity;
- intermediate precision only where safe.

Preview must not substitute a different artistic transform.

---

## 33.2 Final mode

Uses:

- full source resolution;
- full-quality kernels;
- final grain sizing;
- final export color space;
- final metadata.

---

## 33.3 Consistency QA

CHEM should maintain internal test scenes where preview snapshot and final output are compared for:

- color;
- tone;
- highlight behavior;
- apparent grain amount;
- halation placement.

---

# 34. Camera Architecture

Recommended high-level modules:

```text
CameraSessionController
├── CaptureDeviceManager
├── LensController
├── ExposureController
├── FocusController
├── WhiteBalanceController
├── PhotoCaptureCoordinator
├── PreviewFrameProvider
└── SessionRecoveryController
```

---

# 35. Rendering Architecture

```text
ChemRenderer
├── InputDecoder
├── DeviceNormalizer
├── SceneAnalyzer
├── FilmPipeline
│   ├── ExposureStage
│   ├── ToneStage
│   ├── ColorStage
│   ├── BloomStage
│   ├── HalationStage
│   └── GrainStage
├── OutputTransform
└── RenderScheduler
```

---

# 36. Data Architecture

Recommended domains:

```text
Domain
├── Frame
├── Film
├── Recipe
├── Roll
├── DeviceProfile
├── RenderJob
└── ExportJob
```

---

# 37. Suggested Project Structure

```text
CHEM/
├── App/
│   ├── CHEMApp.swift
│   └── AppEnvironment.swift
│
├── Features/
│   ├── Camera/
│   ├── Lab/
│   ├── Films/
│   ├── Rolls/
│   ├── Onboarding/
│   └── Settings/
│
├── Imaging/
│   ├── Camera/
│   ├── Renderer/
│   ├── Metal/
│   ├── RAW/
│   ├── Color/
│   ├── Calibration/
│   └── Export/
│
├── Domain/
│   ├── Models/
│   ├── Repositories/
│   └── Services/
│
├── Persistence/
│   ├── SwiftData/
│   ├── Files/
│   └── Cache/
│
├── Platform/
│   ├── Photos/
│   ├── Haptics/
│   ├── Permissions/
│   └── Device/
│
├── DesignSystem/
│
└── Tests/
    ├── Unit/
    ├── Integration/
    ├── ImagingRegression/
    └── UI/
```

---

# 38. Render Scheduling

The camera thread must never be blocked by full-resolution export.

Use separated priorities:

## Priority A

Live preview.

## Priority B

Shutter source preservation.

## Priority C

Immediate post-capture preview.

## Priority D

Full-resolution render.

## Priority E

Background batch render.

---

# 39. Capture Reliability

## REL-001

Source image persistence must occur before nonessential final rendering.

## REL-002

If render fails but source exists:

- frame is recoverable;
- Lab displays “Needs Development”;
- retry automatically or manually.

## REL-003

If Photos save fails:

- CHEM internal source remains;
- user sees recoverable error.

## REL-004

Never silently discard frame.

---

# 40. App Lifecycle Behavior

## 40.1 Background interruption

If camera session is interrupted by:

- phone call;
- Control Center;
- app switch;
- system resource pressure;

CHEM must stop/recover camera cleanly.

---

## 40.2 Session recovery

When returning:

- resume previous film;
- restore lens if possible;
- reset invalid manual controls safely.

---

# 41. Performance Budgets

These are target product budgets, to be validated against actual hardware.

## 41.1 Camera startup

### Warm launch target

Viewfinder interactive as close to immediate as technically possible.

Product target:

`< 500 ms perceived ready` on recent supported devices where feasible.

---

## 41.2 Cold launch

Target:

`< 1.5 s to usable camera` on target baseline hardware.

---

## 41.3 Shutter response

UI feedback:

`< 50 ms perceived response`

Actual sensor capture may vary.

---

## 41.4 Preview

Preferred:

`60 fps`

Minimum:

`stable 30 fps`

No oscillation between frame rates if avoidable.

---

## 41.5 Memory

Full-res rendering should use tiling or resource reuse where needed.

Never assume largest image fits through multiple full-size float buffers simultaneously.

---

# 42. Thermal Strategy

CHEM must react to thermal state.

## Nominal

60 fps preview.

## Elevated

Potentially reduce:

- internal preview resolution;
- nonessential analysis frequency.

## Serious

Move to stable 30 fps.

## Critical

Prioritize:

- capture reliability;
- source saving;
- disable expensive preview extras if needed.

Never silently reduce final image quality without explicit technical necessity.

---

# 43. Color Management

## 43.1 Internal working representation

Prefer:

- linear-light operations where mathematically appropriate;
- wide-gamut floating point representation.

---

## 43.2 Default output

Recommended:

- HEIF
- Display P3 when safe and metadata-correct

---

## 43.3 Compatibility output

JPEG:

- sRGB

---

## 43.4 Color metadata

ICC/color profile metadata must be correct.

Incorrect tagging is considered a release-blocking imaging bug.

---

# 44. RAW / ProRAW

## RAW-001

Detect support at runtime.

Do not show unsupported modes.

## RAW-002

RAW option belongs in advanced capture settings.

## RAW-003

If paired capture is enabled:

preserve association between:

- RAW source;
- processed source;
- CHEM metadata.

## RAW-004

RAW development path must be tested separately from HEIF/JPEG path.

---

# 45. Storage Model

Potential storage locations:

```text
Application Support/
  Frames/
    <frame-id>/
      source.*
      metadata.json
      preview.heic
      render.heic

Caches/
  Thumbnails/
  Renderer/

Documents/
  exported recipes if needed
```

Do not put recoverable source only in caches.

---

# 46. Frame Deletion

Deleting a CHEM frame should clearly explain whether it removes:

- CHEM metadata only;
- CHEM local negative;
- exported Photos copy.

Default should not delete Apple Photos assets automatically without explicit confirmation.

---

# 47. Privacy Requirements

## PRIV-001 — No mandatory account

V1 requires no authentication.

## PRIV-002 — No photo upload

Core capture and render stay on-device.

## PRIV-003 — No ad SDK

No advertising SDK in V1.

## PRIV-004 — No cross-app tracking

No tracking identifier for advertising.

## PRIV-005 — Limited Photos access

Use scoped picker where possible.

## PRIV-006 — Analytics minimized

If product telemetry is used, avoid photo content and sensitive metadata.

---

# 48. Analytics

Analytics must be privacy-conscious.

Allowed examples:

- app_open
- camera_ready
- shutter_pressed
- capture_succeeded
- capture_failed
- film_selected
- lab_opened
- redevelop_started
- redevelop_completed
- export_succeeded
- export_failed
- raw_mode_enabled
- pro_mode_enabled
- purchase_started
- purchase_completed

Do not log:

- photo pixels;
- GPS by default;
- faces;
- captions;
- image embeddings;
- full EXIF without explicit need.

---

# 49. Telemetry Event Schema

Example:

```json
{
  "event": "capture_succeeded",
  "app_version": "1.0.0",
  "device_family": "iPhone",
  "film_id": "skin400",
  "raw_enabled": true,
  "lens_role": "wide",
  "preview_fps_bucket": "55_60",
  "render_latency_bucket_ms": "500_1000"
}
```

Avoid exact personal identifiers.

---

# 50. Accessibility

Accessibility is a release requirement.

## A11Y-001 — VoiceOver

All camera controls must have meaningful labels.

Examples:

- “Shutter”
- “Film: SKIN 400”
- “Lens: 1x”
- “Exposure compensation: minus 0.3”

## A11Y-002 — Control target size

Follow Apple minimum touch target recommendations.

## A11Y-003 — Color independence

Do not use color alone to indicate selected state.

## A11Y-004 — Reduced motion

Respect Reduce Motion where practical.

## A11Y-005 — Haptics

Haptics should supplement, not replace, visible feedback.

---

# 51. Localization

V1 should be architecture-ready for localization.

Recommended initial languages:

- English
- Vietnamese

Potential next:

- Japanese
- Korean
- Chinese
- Thai

Film names should remain brand names and not be translated unless intentionally localized.

---

# 52. Error Handling Principles

Errors must be:

- specific;
- recoverable;
- non-technical where possible.

Examples:

### Camera unavailable

> Camera is unavailable right now. Try reopening CHEM.

### Source preserved, render failed

> Your frame is safe. CHEM could not finish developing it yet.

### Storage low

> Your iPhone is low on storage. CHEM can capture in Standard mode or free space first.

---

# 53. Offline Behavior

All core workflows must work offline:

- camera;
- film preview;
- capture;
- Lab;
- re-development;
- import;
- export.

Only optional future services may require internet.

---

# 54. Monetization

## 54.1 Free tier

Includes:

- camera;
- full-resolution capture;
- gallery import;
- no watermark;
- DAY 200;
- SKIN 400;
- MONO 400.

---

## 54.2 CHEM Pro

One-time purchase.

Initial candidate price:

- Launch: USD 19.99
- Mature price: USD 29.99

Regional pricing should be App Store localized.

---

## 54.3 Pro unlock candidates

- all 8 stocks;
- RAW/ProRAW;
- custom recipes;
- push/pull;
- batch development;
- advanced capture controls;
- future premium stock drops.

Core camera should remain genuinely useful in free tier.

---

# 55. Purchase Requirements

## PAY-001

Use StoreKit.

## PAY-002

Restore purchases must work reliably.

## PAY-003

No dark patterns.

## PAY-004

No fake countdown timers.

## PAY-005

No watermark on free output.

---

# 56. Future Stock Packs

Possible optional packs:

## Cinema Pack

- CINE 50D
- CINE 250D
- CINE 500T

## Mono Pack

- MONO 100
- MONO 400
- MONO 1600/3200

Only introduce packs after core library is strong.

Do not create hundreds of low-quality presets.

---

# 57. Design System

## Visual direction

Industrial lab + modern photography.

Avoid:

- fake plastic;
- fake screws;
- fake leather;
- disposable-camera skeuomorphism.

---

## Base palette

- off-white
- charcoal
- warm gray
- film-pack accent colors

---

## Typography

Use a modern neutral grotesk style.

Prioritize:

- legibility;
- restraint;
- hierarchy.

---

# 58. App Icon

Concept direction:

- abstract C;
- film chemistry;
- exposed circle;
- aperture-like geometry.

Avoid generic camera-lens icon.

---

# 59. Haptic Design

Recommended haptics:

## Shutter

Firm but subtle impact.

## Film switch

Very light tick.

## Control limit

Small boundary haptic.

## Successful development

Optional soft completion haptic.

Haptics must not become noisy.

---

# 60. Sound Design

Default shutter behavior should respect platform and regional rules.

Optional interface sound should be minimal.

No fake film-wind sound by default.

---

# 61. Film Regression Suite

Every engine change must run a fixed image set.

Dataset should include:

- portraits;
- dark skin;
- light skin;
- mixed skin groups;
- red objects;
- foliage;
- blue sky;
- snow/white;
- black clothing;
- neon signs;
- night street;
- tungsten indoor;
- LED indoor;
- sunrise/sunset;
- high-contrast daylight;
- low-light interiors.

---

# 62. Regression Outputs

For every film stock, save standardized outputs.

Compare engine versions through:

- visual review;
- histogram/tone statistics;
- selected color patch measurements;
- highlight clipping metrics;
- optional perceptual distance metrics.

Human photographic review remains necessary.

---

# 63. Film QA Checklist

A film cannot ship until reviewed for:

- skin;
- foliage;
- red;
- yellow;
- blue;
- neutral gray;
- deep shadows;
- highlights;
- mixed light;
- low exposure;
- high exposure;
- all supported major lenses.

---

# 64. Device QA Matrix

For each supported iPhone family, test:

- rear main camera;
- ultra-wide;
- tele where present;
- front camera if supported;
- RAW path;
- standard path;
- low-light;
- high brightness;
- lens switching;
- app resume;
- thermal load.

---

# 65. Supported Device Policy

Rather than pretending every iPhone receives identical quality:

- define minimum iOS version;
- define full-calibration devices;
- define generic-profile devices;
- define unsupported advanced features.

CHEM should remain honest internally about quality tiers.

---

# 66. iOS Version Strategy

Initial engineering decision required.

Candidate approach:

- support current iOS major version and one prior major version;
- avoid supporting very old versions if they compromise camera APIs or Metal architecture.

Final minimum must be chosen after market/device data review.

---

# 67. Front Camera

Decision for V1:

Recommended to support front camera only if:

- orientation handling is correct;
- image quality is acceptable;
- mirrored preview/save behavior is clear;
- film output has been tested.

Otherwise defer rather than ship a poor implementation.

---

# 68. Orientation

V1 must support:

- portrait;
- landscape left;
- landscape right.

Metadata and output orientation must be correct.

Avoid destructive pixel rotation where metadata can safely represent orientation.

---

# 69. Aspect Ratios

Recommended V1:

- 4:3 default
- 3:2
- 1:1

Potential future:

- 16:9
- 65:24 style panoramic crop

Capture source should preserve maximum useful area where practical, while crop remains non-destructive.

---

# 70. Crop Model

Store crop as recipe metadata.

Example:

```swift
struct CropState: Codable {
    var aspectRatio: CropAspect
    var normalizedRect: CGRect
    var rotation: Float
}
```

---

# 71. Metadata / EXIF

Exported image should preserve appropriate metadata.

User settings may control:

- location;
- camera info;
- CHEM film name;
- date/time.

Do not inject fake camera metadata.

---

# 72. Location

Default recommendation:

- only preserve location if user grants Photos/camera-related location permission where applicable;
- do not require location for core app;
- include toggle to strip location on export.

---

# 73. Settings

Recommended Settings sections:

## Camera

- preserve last film
- favorite film at launch
- default lens
- grid
- haptics
- Pro Mode

## Capture

- Standard / Negative
- RAW where supported
- HEIF / JPEG preference
- aspect ratio

## Lab

- default export format
- keep imported source

## Privacy

- analytics opt-in/out
- location metadata behavior

## Storage

- CHEM local storage
- clear cache
- manage negatives

## About

- app version
- renderer version
- licenses
- privacy
- support

---

# 74. Grid

Optional camera grid:

- Off
- Rule of thirds

Future:

- square
- horizon.

---

# 75. Focus / Exposure UI

Tap indicator should separate focus and exposure mental models only if necessary.

Default simple approach:

- single focus box;
- vertical EV gesture.

Avoid Apple Camera clone where not useful.

---

# 76. Undo / History

Lab changes should be non-destructive.

No conventional undo stack is strictly required for V1 if recipe state can be reset.

Must support:

- Reset to captured recipe
- Reset to film defaults

---

# 77. Render Job Model

```swift
struct RenderJob {
    let id: UUID
    let frameID: UUID
    let source: SourceReference
    let recipe: FilmRecipe
    let deviceProfile: DeviceProfileReference
    let quality: RenderQuality
    let priority: RenderPriority
}
```

---

# 78. Render Cache

Cache key should incorporate:

- source checksum;
- recipe hash;
- film version;
- renderer version;
- output size;
- device normalization version.

This prevents stale image reuse.

---

# 79. Concurrency

Use structured concurrency.

Potential actors/services:

- CameraSessionActor
- RenderQueueActor
- FrameRepositoryActor
- ExportActor

Avoid unmanaged shared mutable renderer state.

---

# 80. State Management

Feature screens should have explicit state.

Example CameraState:

```swift
struct CameraState {
    var sessionStatus: SessionStatus
    var activeFilm: FilmID
    var activeLens: LensID
    var exposureCompensation: Float
    var focusState: FocusState
    var captureState: CaptureState
    var thermalState: ThermalState
    var proControls: ProControlState
}
```

---

# 81. Persistence

Recommended:

- SwiftData or SQLite-backed domain data
- filesystem for image assets
- Codable metadata sidecars where useful

Do not store large binary images directly inside a relational database.

---

# 82. Data Migration

Every persisted schema must be versioned.

Public release requires migration tests.

Users must not lose:

- frames;
- recipes;
- rolls;
- purchase state;
- source references

during app updates.

---

# 83. Renderer Versioning

Every frame stores renderer version.

Example:

`rendererVersion = "1.2.0"`

Reasons:

- deterministic re-render;
- regression control;
- optional migration.

---

# 84. Film Versioning

Every film stores semantic or integer version.

Example:

`skin400@3`

Never silently replace stock behavior for old frames.

---

# 85. Recipe Sharing — Future Contract

Even if V1 does not expose sharing, recipe format should be exportable.

Candidate payload:

```json
{
  "schema": 1,
  "film": "street400",
  "film_version": 2,
  "exposure": -0.3,
  "process": 1,
  "grain": "rough",
  "warmth": -0.1
}
```

Avoid device-specific binary content in recipes.

---

# 86. Security

CHEM has low server-side attack surface in V1 because no account/backend is required.

Still protect:

- malformed imported RAW files;
- corrupted image files;
- recipe parser;
- external share imports;
- path traversal if files are imported;
- resource exhaustion from huge images.

---

# 87. Import Safety

Validate:

- file type;
- dimensions;
- memory requirements;
- decoder errors.

Use sandbox-safe file access.

---

# 88. Crash Recovery

If app terminates during capture:

On next launch:

- scan unfinished frame transaction;
- recover preserved source;
- recreate missing render job;
- show recovered frame if successful.

---

# 89. Transactional Capture

Capture lifecycle:

```text
1. user taps shutter
2. create pending frame record
3. capture source
4. persist source atomically
5. mark source safe
6. generate quick preview
7. enqueue full render
8. save/export according to settings
9. mark frame complete
```

Never reverse steps 4 and 6.

---

# 90. Low Storage Behavior

When storage is low:

1. warn user before capture where possible;
2. disable RAW first if necessary;
3. preserve standard capture;
4. avoid catastrophic app crash;
5. offer storage management.

---

# 91. Permissions

CHEM may request:

- Camera
- Photos read/select
- Photos add/save
- optional location metadata

Request only when feature is used.

---

# 92. Permission Denied States

## Camera denied

Allow:

- Lab;
- gallery import;
- film browsing.

Show `Open Settings`.

## Photos denied

Camera still works if internal storage allowed.

Saving behavior must be clear.

---

# 93. Export

## EXP-001 — Save copy

Creates a new asset.

## EXP-002 — Share sheet

Uses system share sheet.

## EXP-003 — Format

V1:

- HEIF
- JPEG

Future:

- TIFF
- high-bit-depth output where justified.

---

# 94. Watermarks

No default watermark.

Optional aesthetic borders may be future features, but must not be forced.

---

# 95. Batch Development — V1.5

User selects multiple imported/captured frames.

Apply one:

- film;
- process;
- grain setting.

Render asynchronously.

Show:

- queued;
- processing;
- completed;
- failed.

---

# 96. Batch Safety

Individual failures must not fail the entire batch.

---

# 97. App Store Product Positioning

Working title:

**CHEM — Film Camera**

Subtitle:

**Digital camera. Film chemistry.**

Core screenshot messages:

1. Load a film.
2. See it before you shoot.
3. Your negative stays yours.
4. Develop any photo.
5. Built for each iPhone camera.
6. No ads. No tracking. No account.

---

# 98. Marketing Positioning

Primary statement:

> Your iPhone has a new film camera.

Secondary:

> Choose a film. See the look live. Shoot. Re-develop later if you change your mind.

Avoid:

> 100+ vintage filters.

---

# 99. Launch Content Strategy

## Campaign A — One city, one film

Examples:

- Hanoi / STREET 400
- Bangkok / NIGHT 800T
- Da Lat / SOFT 160

## Campaign B — Exposure tests

Show:

-2
-1
0
+1
+2

## Campaign C — Same stock, different iPhones

Show calibration consistency.

---

# 100. Beta Program

Recruit:

- street photographers;
- portrait photographers;
- iPhone photographers;
- analog shooters;
- casual creators.

Beta questions should focus on:

- color trust;
- camera reliability;
- speed;
- favorite film;
- situations where user returned to Apple Camera instead.

---

# 101. Beta Success Criteria

Before public launch:

- no known frame-loss bug;
- acceptable crash-free sessions;
- no major color-management bug;
- stable camera resume;
- reliable Photos saving;
- preview/final mismatch within accepted internal bar;
- at least 3 stocks strongly preferred by beta users for distinct use cases.

---

# 102. QA Test Categories

## Functional

- capture;
- save;
- import;
- export;
- lens;
- focus;
- EV;
- films;
- Lab.

## Imaging

- color;
- tone;
- highlight;
- shadow;
- grain;
- halation;
- consistency.

## Device

- multiple iPhone generations;
- multiple lenses.

## System

- low battery;
- low storage;
- background;
- interruptions;
- thermal;
- orientation.

## Permission

- deny;
- limited Photos;
- revoke after use.

---

# 103. Release Blockers

The following are P0 blockers:

- lost captured photo;
- corrupted source;
- app crash during normal capture;
- wrong orientation;
- severe preview/final discrepancy;
- Photos save silently failing;
- incorrect color profile tagging;
- inability to restore Pro purchase;
- migration deleting frame metadata;
- RAW mode producing invalid file.

---

# 104. Risk Register

## RISK-01 — Camera/renderer performance

### Risk

Full film effects may be too expensive for live preview.

### Mitigation

- Metal;
- reduced preview resolution;
- optimized shader graph;
- precomputed resources;
- selective scene analysis frequency.

---

## RISK-02 — Preview/final mismatch

### Risk

Preview looks different from final render.

### Mitigation

Single parameter model and shared rendering stages.

---

## RISK-03 — Device fragmentation

### Risk

Different iPhones produce inconsistent results.

### Mitigation

DeviceProfile architecture + calibrated priority device list.

---

## RISK-04 — RAW complexity

### Risk

RAW path multiplies testing burden.

### Mitigation

Treat RAW as advanced path with explicit support matrix.

---

## RISK-05 — Film stocks feel too similar

### Mitigation

Limit stock count and enforce differentiated design review.

---

## RISK-06 — Film stocks look artificial

### Mitigation

Controlled scene dataset + analog reference studies + photographer review.

---

## RISK-07 — Storage growth

### Mitigation

Storage settings, source strategy, cache clearing, optional RAW.

---

## RISK-08 — Scope creep into editor

### Mitigation

Any new control must pass product-principle review.

---

## RISK-09 — CHEM naming conflict

### Mitigation

Perform formal trademark, domain, App Store, and social-handle clearance before branding lock.

---

# 105. Product Decision Framework

Before adding a feature, answer:

1. Does this improve capture?
2. Does this improve output trust?
3. Does this strengthen CHEM film identity?
4. Does this preserve interface simplicity?
5. Can the engine own the complexity instead?
6. Does this create long-term defensibility?
7. Does this harm launch speed or reliability?

If most answers are no, do not build it.

---

# 106. MVP Priority Table

| ID | Feature | Priority |
|---|---|---:|
| CAM-001 | Default camera launch | P0 |
| CAM-002 | Live film preview | P0 |
| CAM-003 | Capture | P0 |
| CAM-004 | Lens switch | P0 |
| CAM-005 | Tap focus/exposure | P0 |
| CAM-007 | EV | P0 |
| CAM-009 | Last frame | P0 |
| CAM-010 | Film selector | P0 |
| FILM-001 | 3 prototype films | P0 |
| NEG-001 | Source preservation | P0 |
| DEV-001 | Re-develop | P0 |
| GAL-001 | Photos import | P0 |
| LAB-001 | Film switching | P0 |
| LAB-002 | Exposure | P1 |
| LAB-003 | Process | P1 |
| RAW | RAW/ProRAW | P1 |
| PRO | Pro controls | P1 |
| ROLL | Rolls | P1 |
| BATCH | Batch | P2 |
| RECIPE SHARE | Sharing | P2 |

---

# 107. Suggested Engineering Milestones

## Milestone 0 — Spike

Deliver:

- AVFoundation preview;
- Metal texture path;
- one simple film transform;
- capture frame;
- final render.

Exit:

One end-to-end photo exists.

---

## Milestone 1 — Renderer foundation

Deliver:

- FilmProfile abstraction;
- tone stage;
- color stage;
- grain;
- bloom;
- halation;
- shared preview/final parameter model.

Exit:

3 visually distinct stocks.

---

## Milestone 2 — Camera MVP

Deliver:

- camera UI;
- lens;
- EV;
- focus;
- shutter;
- last frame.

Exit:

Usable daily camera build.

---

## Milestone 3 — Persistence

Deliver:

- CHEMFrame;
- source preservation;
- metadata;
- render queue;
- crash recovery.

Exit:

No frame loss in normal test matrix.

---

## Milestone 4 — Lab

Deliver:

- film switching;
- exposure;
- process;
- grain;
- save/share.

---

## Milestone 5 — Gallery

Deliver:

- PhotosPicker;
- source import;
- development;
- export.

---

## Milestone 6 — RAW

Deliver:

- capability detection;
- RAW capture;
- ProRAW;
- RAW decode path.

---

## Milestone 7 — Calibration

Deliver:

- DeviceProfile;
- calibration toolchain;
- first supported devices;
- regression test set.

---

## Milestone 8 — Productization

Deliver:

- onboarding;
- purchase;
- accessibility;
- settings;
- storage UI;
- localization;
- analytics.

---

## Milestone 9 — Beta hardening

Deliver:

- crash fixes;
- performance tuning;
- imaging tuning;
- App Store assets.

---

# 108. Suggested Team

Minimum practical team:

## 1 Product / founder

Owns:

- scope;
- film direction;
- beta;
- prioritization.

## 1 iOS engineer

Owns:

- app shell;
- AVFoundation;
- persistence;
- StoreKit;
- Photos.

## 1 imaging/graphics engineer

Owns:

- Metal;
- color pipeline;
- calibration;
- renderer.

Can be same person as iOS engineer if highly capable, but schedule risk increases.

## 1 designer

Part-time possible.

Owns:

- camera UI;
- Film Shelf;
- branding;
- App Store.

## Photographer/color consultant

Part-time/advisory.

---

# 109. Internal Tooling Required

CHEM should build internal tools rather than tune film blindly inside production code.

Recommended tools:

## Film Playground

Desktop or internal iOS tool to:

- load reference images;
- adjust film parameters;
- compare stocks;
- export test grid.

## Regression Renderer

Batch render fixed dataset for all films.

## Device Calibration Tool

Collect:

- reference chart;
- camera metadata;
- lens;
- illumination.

## Preview/Final Comparator

Capture preview frame and final frame for mismatch analysis.

---

# 110. Film Parameter Authoring

Film profiles should be data-driven.

Avoid hardcoding artistic constants across Metal shaders.

Possible resource package:

```text
Films/
  skin400/
    manifest.json
    tone.bin
    color.cube
    grain.json
    halation.json
    bloom.json
```

Exact format can change.

---

# 111. Film Manifest Example

```json
{
  "id": "skin400",
  "version": 1,
  "display_name": "SKIN 400",
  "category": "color_negative",
  "iso_character": 400,
  "default_process": 0,
  "grain_model": "fine_color_v1",
  "halation_model": "subtle_red_v1",
  "bloom_model": "soft_v1"
}
```

---

# 112. Renderer API Concept

```swift
protocol ChemRendering {
    func renderPreview(
        frame: PreviewFrame,
        film: FilmProfile,
        recipe: FilmRecipe,
        deviceProfile: DeviceProfile
    ) async throws -> RenderedPreview

    func renderFinal(
        source: SourceImage,
        film: FilmProfile,
        recipe: FilmRecipe,
        deviceProfile: DeviceProfile,
        output: OutputDescriptor
    ) async throws -> RenderedImage
}
```

---

# 113. Frame Repository Concept

```swift
protocol FrameRepository {
    func createPendingFrame(_ draft: FrameDraft) async throws -> FrameID
    func persistSource(_ source: SourceImage, for frameID: FrameID) async throws
    func markSourceSafe(_ frameID: FrameID) async throws
    func saveRecipe(_ recipe: FilmRecipe, frameID: FrameID) async throws
    func saveRenderedAsset(_ asset: RenderedAsset, frameID: FrameID) async throws
    func frame(id: FrameID) async throws -> CHEMFrame
}
```

---

# 114. Capture Coordinator Concept

```swift
protocol PhotoCaptureCoordinating {
    func capture(
        settings: CaptureSettings,
        activeFilm: FilmProfile,
        recipe: FilmRecipe
    ) async throws -> FrameID
}
```

---

# 115. State Machine — Capture

```text
Idle
 ↓
Preparing
 ↓
Capturing
 ↓
PersistingSource
 ↓
SourceSafe
 ↓
PreviewReady
 ↓
RenderingFinal
 ↓
Complete
```

Failure can occur after `SourceSafe` without losing frame.

---

# 116. State Machine — Camera Session

```text
Uninitialized
 ↓
RequestingPermission
 ↓
Configuring
 ↓
Running
 ↙       ↘
Interrupted  Failed
 ↓
Recovering
 ↓
Running
```

---

# 117. Film Selection State

Film switching should not reconfigure AVFoundation session unnecessarily.

Only renderer state should change.

---

# 118. Performance Instrumentation

Internal debug overlay may show:

- preview fps;
- GPU frame time;
- CPU frame time;
- render queue depth;
- thermal state;
- memory;
- active device profile;
- film profile/version;
- dropped frames.

Never ship debug overlay enabled to normal users.

---

# 119. Imaging Debug Export

Internal builds should be able to export:

- normalized input;
- post-tone;
- post-color;
- pre-grain;
- final.

This makes film tuning possible.

---

# 120. Development Constraints

Do not prematurely implement:

- cloud backend;
- social account;
- collaboration;
- AI image generation.

The primary technical risk is imaging and capture quality.

Spend complexity budget there.

---

# 121. Definition of Done — Film Stock

A film is “done” only if:

1. Profile version is frozen.
2. Regression outputs generated.
3. Photographer review completed.
4. Skin-tone test passed.
5. Night/day behavior checked.
6. All primary lenses tested.
7. Preview/final match reviewed.
8. Memory/performance impact approved.
9. Film description written.
10. Film assets packaged.

---

# 122. Definition of Done — Camera Feature

A camera feature is done only if:

1. Works on all supported devices or is capability-gated.
2. Handles interruption.
3. Handles denied permission where relevant.
4. Has accessibility label.
5. Has analytics event if required.
6. Has unit/integration test where practical.
7. Does not cause frame loss.
8. Has no known P0/P1 bugs.

---

# 123. Definition of Done — Release

Public V1 is done only if:

- App Store purchase works;
- restore works;
- privacy labels are accurate;
- camera launch is stable;
- capture is reliable;
- no known source-loss defect;
- color profile output correct;
- migration test passes;
- 8 stocks approved;
- minimum device matrix tested;
- onboarding complete;
- localization complete;
- accessibility review complete;
- App Store screenshots complete;
- support/privacy pages ready.

---

# 124. Open Product Questions

These require explicit decisions before architecture freeze.

## Q-01

Minimum supported iOS version?

## Q-02

Minimum supported iPhone generation?

## Q-03

Does free tier allow RAW or only Pro?

## Q-04

Do imported photos copy source locally or reference Photos by default?

## Q-05

Should active film persist across app launches?

Recommended: yes.

## Q-06

Should front camera ship in V1?

## Q-07

Should Rolls ship in V1 or V1.5?

## Q-08

Should one-time Pro include all future stocks forever, or only core library?

Recommended: core future updates included; special optional packs may be separate later.

## Q-09

Will user-created recipes exist in V1 or V1.5?

## Q-10

Will CHEM support Live Photos?

Recommended: not V1 unless implementation is excellent.

---

# 125. Suggested Decisions for First Implementation

To avoid blocking development, recommended defaults are:

- iPhone only;
- portrait + landscape;
- 4:3 default;
- rear cameras first;
- 3 prototype stocks;
- HEIF standard source;
- optional ProRAW later;
- no account;
- no backend;
- no batch in MVP;
- no Rolls until camera + Lab stable;
- no video;
- Metal renderer from day one;
- FilmProfile + DeviceProfile versioning from day one.

---

# 126. Product Roadmap

## Stage 0 — Proof

Question:

> Can CHEM render a genuinely attractive film look live?

Deliverable:

technical prototype.

---

## Stage 1 — Habit

Question:

> Will users choose CHEM instead of Apple Camera?

Deliverable:

camera-first MVP.

---

## Stage 2 — Trust

Question:

> Can users trust CHEM not to lose photos and to reproduce the preview?

Deliverable:

reliability + persistence + QA.

---

## Stage 3 — Ownership

Question:

> Do users identify with a CHEM stock?

Deliverable:

film library + brand.

---

## Stage 4 — Workflow

Question:

> Can CHEM handle a full trip/session?

Deliverable:

Lab + Rolls + batch.

---

## Stage 5 — Ecosystem

Question:

> Can CHEM stocks/recipes become shareable photographic language?

Deliverable:

recipes + creator ecosystem.

---

# 127. Why CHEM Can Win

CHEM does not need to own every editing use case.

It needs to own one highly valuable moment:

> The second before the user presses the shutter.

If the user trusts that:

- the color is right;
- the preview is honest;
- the frame will be saved;
- the original is preserved;
- the film has character;

then CHEM can become a default capture habit.

That is stronger than being one more editor installed on the phone.

---

# 128. Product Mantra

When facing a product decision, return to:

> **Shoot more. Edit less.**

And the architectural counterpart:

> **Complexity belongs in the engine, not in the interface.**

---

# 129. Final One-Sentence Product Definition

> **CHEM is a calibrated film camera for iPhone that renders its film character live, preserves a re-developable digital negative, and uses the same deterministic imaging engine from viewfinder to final export.**

---

# 130. Immediate Next Actions

## Product

- Freeze MVP scope.
- Validate working name CHEM legally.
- Confirm free/Pro boundary.
- Decide first supported iPhone matrix.

## Design

- Create low-fidelity camera flow.
- Design Film Shelf.
- Design Lab.
- Define visual identity.

## Imaging

- Prototype 3 stocks:
  - DAY 200
  - SKIN 400
  - NIGHT 800T
- Create regression image set.
- Define working color space.
- Prototype grain/halation/bloom.

## iOS Engineering

- Build AVFoundation camera session.
- Build Metal preview path.
- Implement capture transaction.
- Implement CHEMFrame persistence.
- Implement Photos import/export.

## QA

- Build device matrix.
- Define frame-loss test.
- Define interruption test.
- Define preview/final comparison workflow.

---

# Appendix A — MVP User Flow

```text
Launch
 ↓
Camera
 ↓
Film already selected
 ↓
User swipes film
 ↓
Live view changes
 ↓
User taps shutter
 ↓
Source is persisted
 ↓
Immediate thumbnail appears
 ↓
Full render finishes
 ↓
Saved / available in CHEM
```

---

# Appendix B — Re-Development Flow

```text
Camera / Lab
 ↓
Select frame
 ↓
Open Lab
 ↓
Swipe SKIN 400 → STREET 400
 ↓
Preview re-renders
 ↓
User adjusts Process +1
 ↓
Recipe saved
 ↓
Export copy
```

---

# Appendix C — Gallery Flow

```text
Lab
 ↓
Import
 ↓
PhotosPicker
 ↓
Select image(s)
 ↓
CHEM normalizes source
 ↓
Choose film
 ↓
Develop
 ↓
Save copy / share
```

---

# Appendix D — Pro Mode Flow

```text
Camera
 ↓
Pro Mode enabled
 ↓
ISO / shutter / WB / focus strip appears
 ↓
User sets manual values
 ↓
CHEM film preview remains active
 ↓
Capture
```

---

# Appendix E — Suggested Requirement ID Prefixes

```text
CAM   Camera
FILM  Film library
LAB   Lab
GAL   Gallery
NEG   Negative/source
DEV   Development
PRO   Pro controls
ROLL  Rolls
REC   Recipes
ENG   Imaging engine
CAL   Calibration
EXP   Export
PRIV  Privacy
A11Y  Accessibility
PAY   Monetization
REL   Reliability
PERF  Performance
DATA  Persistence
```

---

# Appendix F — Example Initial Backlog

## Epic: Camera Foundation

- CAM-001 Default camera launch
- CAM-002 Live film preview
- CAM-003 Shutter
- CAM-004 Lens selection
- CAM-005 Focus/exposure
- CAM-007 EV
- Camera interruption recovery
- Permission states

## Epic: Imaging

- FilmProfile schema
- DAY 200 prototype
- SKIN 400 prototype
- NIGHT 800T prototype
- Grain stage
- Bloom stage
- Halation stage
- Output transform
- Preview/final consistency test

## Epic: Frame Safety

- CHEMFrame schema
- capture transaction
- source persistence
- recovery scan
- render queue

## Epic: Lab

- film carousel
- exposure
- process
- grain
- export

## Epic: Gallery

- PhotosPicker
- imported source adapter
- gallery render
- save/share

---

# Appendix G — Critical Product Anti-Patterns

Do not:

- add features just because competitors have them;
- expose every rendering parameter;
- require sign-up before camera;
- make film preview noticeably different from export;
- silently replace an old film profile;
- save only the baked result;
- block shutter while a previous full render is running;
- let analytics interfere with capture;
- use cloud connectivity as a camera dependency;
- force watermark;
- bury camera under home/dashboard;
- create 50 nearly identical stocks;
- call every artistic transform “AI”;
- turn CHEM into a social network before the camera is excellent.

---

# Appendix H — V1 Review Checklist

Before calling V1 ready, answer YES to all:

- Can the app open directly into a usable camera?
- Can I shoot 50 photos without a save failure?
- Can I switch films without restarting camera?
- Does the final image look like the viewfinder?
- Can I recover a photo if rendering fails?
- Can I re-develop a CHEM frame?
- Can I import a Photos image?
- Can I export without a watermark?
- Do all 8 stocks have distinct identities?
- Are RAW controls capability-gated?
- Does the app work offline?
- Does the app work without an account?
- Are privacy disclosures accurate?
- Is Pro purchase restorable?
- Is color profile metadata correct?
- Are low-storage states handled?
- Are interruptions handled?
- Are accessibility labels present?
- Are migration tests passing?
- Is there any known frame-loss bug?

If any critical answer is NO, V1 should not ship.

---

**End of PRD v1.0**

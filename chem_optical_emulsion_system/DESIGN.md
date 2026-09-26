---
name: CHEM Optical / Emulsion System
colors:
  surface: '#111316'
  surface-dim: '#111316'
  surface-bright: '#37393d'
  surface-container-lowest: '#0c0e11'
  surface-container-low: '#1a1c1f'
  surface-container: '#1e2023'
  surface-container-high: '#282a2d'
  surface-container-highest: '#333538'
  on-surface: '#e2e2e6'
  on-surface-variant: '#d9c2b2'
  inverse-surface: '#e2e2e6'
  inverse-on-surface: '#2f3034'
  outline: '#a18d7e'
  outline-variant: '#544437'
  surface-tint: '#ffb77b'
  primary: '#ffb77b'
  on-primary: '#4d2700'
  primary-container: '#e58e3c'
  on-primary-container: '#592e00'
  inverse-primary: '#8f4e00'
  secondary: '#ffb4aa'
  on-secondary: '#690003'
  secondary-container: '#92130f'
  on-secondary-container: '#ff9f92'
  tertiary: '#69d9c5'
  on-tertiary: '#003730'
  tertiary-container: '#3fb4a2'
  on-tertiary-container: '#004138'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdcc2'
  primary-fixed-dim: '#ffb77b'
  on-primary-fixed: '#2e1500'
  on-primary-fixed-variant: '#6d3a00'
  secondary-fixed: '#ffdad5'
  secondary-fixed-dim: '#ffb4aa'
  on-secondary-fixed: '#410001'
  on-secondary-fixed-variant: '#8f100d'
  tertiary-fixed: '#87f6e1'
  tertiary-fixed-dim: '#69d9c5'
  on-tertiary-fixed: '#00201b'
  on-tertiary-fixed-variant: '#005046'
  background: '#111316'
  on-background: '#e2e2e6'
  surface-variant: '#333538'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 38px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 26px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 18px
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 12px
  telemetry-num:
    fontFamily: JetBrains Mono
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 22px
  roll-counter:
    fontFamily: JetBrains Mono
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 32px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes a high-precision digital film camera interface. The aesthetic bridges high-end laboratory instrumentation with precision mechanical rangefinders—rational, functional, and rigorously calibrated.

### Creative Tenets
- **Instrument, Not Toy:** Zero decorative skeuomorphism, fake leather textures, or nostalgic film grain overlays on chrome. Depth is created through mechanical precision, matte finishes, tight clearances, and calibrated physical-digital readouts.
- **Scientific Restraint:** The interface recedes entirely to support framing. Controls use high-density feedback, machined edges, and strict utilitarian iconography.
- **Chromatographic Accents:** Functional color is treated as chemical reactive agents—sparingly deployed strictly for emulsion states, color temperature, and spectral warnings (halation, clipping).
- **Haptic Tactility:** Interactions model the tight, positive detents of physical aperture rings and stepped shutter dials rather than frictionless digital sliders.

### Target Audience & Tone
Engineered for dedicated photographers, cinematographers, and visual artists demanding authentic emulsion science with exact optical parameter control. The tone is authoritative, understated, and uncompromised.

## Colors

The palette draws directly from darkroom safelights, titanium bodies, and reactive photographic chemistry. Built upon an ultra-deep charcoal core, high-luminance off-white typography ensures immediate daylight legibility while preserving night-adapted vision.

### Palette Architecture
- **Obsidian / Substrate (`#0D0E10`):** Base canvas and letterboxed optical viewfinder border. Non-reflective, infinite depth.
- **Charcoal Deck (`#141619`):** Primary card, control shelf, and dial backing plane.
- **Machined Graphite (`#1C1E22`):** Elevated control housings, active segment fills, and sheet overlays.
- **Titanium Seam (`#2A2D34`):** Crisp 1px structural dividing lines, knurling textures, and mechanical boundaries.
- **Technical Off-White (`#F2F2F0`):** High-contrast readout data, primary glyphs, and target crosshairs.
- **Silver Oxide (`#8A8D95`):** Secondary optical telemetry, inactive states, unit labels (e.g., `SEC`, `MM`, `ISO`).

### Emulsion & Chemistry Accents
- **Amber Emulsion (`#E58E3C`):** Primary interaction point, active exposure locks, tungsten/daylight color balance indicators, and processing progress.
- **Cadmium Halation (`#D9483B`):** Shutter release active rim, critical clipping, film roll expiration, and halation module active states.
- **Orthochromatic Emerald (`#2FA896`):** Monochrome profiles, chemical development ready status, and spectral balance locks.

## Typography

The typographic hierarchy implements a dual-engine architecture:
1. **Rational Grotesque (`Inter`):** Assigned to structural headings, navigation titles, narrative film stock descriptions, and settings hierarchy. Provides crystalline clarity without distracting geometry.
2. **Machined Monospace (`JetBrains Mono`):** Assigned to all camera HUD data, telemetry strings, numeric parameters (ISO, ƒ-stop, shutter, color temperature), frame counters, and canister lot codes. 

### Typographic Rules
- All numeric readouts must activate tabular figures (`tnum`) and slashed zeros (`zero`) to guarantee stable element widths during real-time scene metering.
- Telemetry labels (`label-sm`) default to uppercase with `+0.08em` tracking.
- Units (`K`, `EV`, `S`, `ƒ`, `ISO`) are set 2pt smaller than their parent values in `Silver Oxide` (`#8A8D95`) to preserve numeric legibility at a glance.

## Layout & Spacing

Layouts are derived from physical rangefinder viewfinders and laboratory instrumentation panels, favoring zero wasted space, deterministic thumb zones, and unencumbered optical review areas.

### Spatial Structure
- **Viewfinder Well:** A centered, geometrically rigid aspect window (3:2 or 4:5 native film ratio) pinned to safe areas, framed by 1px precision crop marks.
- **Top Utility Deck (Metadata Bar):** Height-locked at 44px for battery, frame counter remaining (`EXP 24/36`), focal length, and active grain engine status.
- **Lower Control Console (Thumb Deck):** 160px primary interaction shelf optimized for one-handed thumb sweep, holding the tactile shutter release, exposure wheel, and chemistry swap badge.
- **Grid Architecture:** 4-column layout on mobile devices with tight 12px (`0.75rem`) gutters and 16px (`1rem`) screen margins to maximize viewfinder real estate.

## Elevation & Depth

Depth is defined strictly by precision mechanical layering and zero-blur edge definition. The design avoids diffuse, floaty drop shadows in favor of milled reliefs and distinct material plane steps.

### Level Hierarchy
- **Level 0 (Base Substrate - `#0D0E10`):** Ground plane, inactive viewfinder matte, bottom chassis.
- **Level 1 (Recessed Well - `#08090A`):** The optical aperture area and value wheel wells. Inset 1px borders (`#1C1E22`) simulate physically sunken control bays.
- **Level 2 (Console Deck - `#141619`):** Lower control deck and top metadata bar, framed with a 1px border (`#2A2D34`).
- **Level 3 (Tactile Elements - `#1C1E22`):** Stepped buttons, segmented switches, and canister badges. Uses a 1px top highlight border (`#3A3E48`) and 1px bottom shadow border (`#000000`) to evoke a CNC-milled bevel.
- **Level 4 (Modal Sheets / Emulsion Selector - `#141619`):** Overlays feature a hairline border (`#2A2D34`) accompanied by a tight, directional ambient shadow: `0 8px 24px rgba(0, 0, 0, 0.75)`.

## Shapes

The shape system adopts a machined industrial corner radius (`roundedness: 1`). Controls exhibit tight, purposeful corners reminiscent of milled aluminum camera chassis, precision filter threads, and industrial test equipment.

### Geometry Specifications
- **Standard Surfaces & Trays:** 4px (`0.25rem`) corner radius.
- **Cards & Modals:** 8px (`0.5rem`) corner radius.
- **Canister Badges & Emulsion Tags:** Flat pill on the left, chamfered or right-angle indexed on the right to mimic 35mm film cassette tabs.
- **Optical Shutter Trigger:** Perfect concentric circle with mechanical knurling rings.

## Components

### Shutter Release Assembly
- **Idle:** 72px diameter outer ring with a 1px titanium border (`#2A2D34`). Inner core sits at 58px solid off-white (`#F2F2F0`).
- **Engaged / Pressed:** Scale drops to `0.94` with an inner fill swap to Cadmium Halation (`#D9483B`) and an immediate 10ms haptic transient.
- **Locked Exposure:** A 2px concentric halo lights in Amber Emulsion (`#E58E3C`).

### Stepped Telemetry Dials (ISO, Shutter, EV)
- Horizontal sliding scale resting in an inset recessed well (`#08090A`).
- Active center value displays in `JetBrains Mono 18px Bold` (`#F2F2F0`) accompanied by a fixed top-down amber reticle tick (`#E58E3C`).
- Inactive side values transition to 12px Monospace in `#8A8D95` with opacity fading smoothly to `0.2` at the mask edges.

### Film Canister Badges
- Compact rectangular tags displaying active film chemistry (e.g., `PORTRA 400`, `TRI-X 400`, `CINE 800T`).
- Structural body in `#1C1E22` with a 1px border in `#2A2D34`.
- Left-edge vertical chemical accent stripe (2px) color-coded to the emulsion profile:
  - Tungsten/Color Negative: `#E58E3C`
  - Orthochromatic/B&W: `#2FA896`
  - Experimental Halation: `#D9483B`
- Monospaced metadata labels showing remaining frames in high-contrast off-white (`#F2F2F0`).

### Viewfinder HUD Overlay
- Non-obstructive 1px crosshairs at center frame (`#F2F2F0` at 40% opacity).
- Corner crop brackets defining optical boundaries.
- Live histogram rendered in a 120x32px clean wireframe with zero background fill, plotted with `#2FA896` at 80% opacity.

### Segmented Calibration Switches
- Compact toggles for Flash, Lens focal length (`28mm`, `35mm`, `50mm`), and Format (`3:2`, `1:1`).
- Container built in `#0D0E10` with a 1px titanium border (`#2A2D34`).
- Active segment is filled with `#1C1E22` with high-contrast text (`#F2F2F0`) and an embedded 1px top highlight bevel.
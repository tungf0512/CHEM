# ADR-009: Internal camera validation configuration

## Decision

Keep the optimized Release configuration and add the `CHEM_INTERNAL_VALIDATION` Swift compilation condition at archive time. A deliberate long press on the CHEM header reveals a local diagnostics panel only when that condition is enabled.

## Rationale

This keeps the Xcode project small and preserves the same AVFoundation/Metal pixel path used by a release build. Diagnostics are metadata-only, in-memory, and never sent to analytics. Fault controls are compiled into Debug/internal builds but remain unavailable to ordinary builds.

## Consequences

An internal TestFlight archive must pass `CHEM_INTERNAL_VALIDATION` in its build settings. Normal simulator/foundation builds remain free of the internal panel and fault controls. Physical validation still requires a real iPhone and explicit evidence capture.

# ADR-008: Manual internal TestFlight release

## Decision

Use a workflow-dispatch-only macOS GitHub Actions job for signed archive/export/upload. Apple-maintained actions handle certificate import, provisioning-profile download, Xcode archive/export, and TestFlight upload. Bundle ID and team identity are repository variables; signing/API material is repository secret storage only.

## Rationale

The primary developer environment is Ubuntu, so a local Mac is not a release prerequisite. Manual dispatch prevents every push from producing a signed upload, while the preflight makes missing Apple setup explicit. Internal TestFlight is sufficient for the first iPhone Air validation target and avoids public/external distribution.

## Consequences

The Apple Developer account, App Store Connect app record, signing certificate, profile, and testers must be configured before the workflow can run. The project keeps simulator CI independent of Apple credentials.

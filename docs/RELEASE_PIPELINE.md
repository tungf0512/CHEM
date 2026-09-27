# CHEM release pipeline

## Normal foundation CI

`.github/workflows/ios-foundation-ci.yml` runs on pushes, pull requests, and manual dispatch. It installs JavaScript dependencies, typechecks, runs Jest/lint/Codegen, installs frozen Ruby/CocoaPods dependencies from committed locks, validates the workspace/scheme, builds the iOS Simulator target, and runs native Swift domain tests. Any lockfile drift fails the job.

## Lockfile refresh

`.github/workflows/ios-lockfile-refresh.yml` is manual and write-enabled. It resolves the exact Node/Ruby/Bundler/CocoaPods toolchain on macOS, runs Codegen and `pod install`, verifies the change scope, and commits only `mobile/Gemfile.lock` and `mobile/ios/Podfile.lock`. It never commits `Pods/` or source changes. Run it when an intentional dependency/toolchain update is required, then rerun foundation CI.

## Internal TestFlight

`.github/workflows/testflight-internal.yml` is `workflow_dispatch` only. It requires repository variables for `CHEM_BUNDLE_ID`, `APPLE_TEAM_ID`, `APPSTORE_ISSUER_ID`, and `APPSTORE_API_KEY_ID`, plus secrets for the API private key and Apple Distribution `.p12`. It imports signing material, downloads the App Store profile, generates export options without profile UUIDs, archives the Release target with `CHEM_INTERNAL_VALIDATION`, exports an IPA, and uploads it to the internal TestFlight track. Missing configuration fails before compilation and prints names only.

The first signed build uses marketing version `0.1.0` and GitHub run number as the unique build number. Its diagnostic report includes the commit SHA and neutral preview baseline. The pipeline does not implement or enable Film Engine looks, RAW, Lab, Gallery, or public TestFlight testing.

# Implementation status and evidence

Status distinguishes source work from executable verification. A native implementation is not considered build-verified until it compiles with Xcode on macOS. No camera behavior is considered device-verified until it has been run on hardware.

Current verification labels: JavaScript is locally build-verified; native iOS is not build-verified; simulator-verified = no; device-verified = no; GitHub CI-verified = no. The workflow and native test suite are scaffolded for macOS execution but are awaiting a runner.

## Foundation milestone

| Area | Implementation status | Validation status / evidence |
|---|---|---|
| Bare React Native app and camera UI | implemented | JS build-verified locally: `npm ci`, TypeScript, Jest, ESLint, and Metro bundle pass. iOS binary is not verified. |
| React Native native boundary / Codegen | implemented | Codegen-verified locally; generated event/module/component artifacts and ObjC++ field mapping were inspected. CocoaPods and Xcode integration are not verified. |
| Swift CameraCore lifecycle, focus, EV, capture | implemented in source | Not native-build-verified; no Swift/Xcode toolchain here. Device lifecycle and camera behavior are unverified. |
| Physical camera discovery / user-facing capture modes | implemented in source | Pure catalog model has 2 authored Swift tests; actual capabilities, mode switching, and iPhone Air 1×/2× sensor identity are device-unverified. Virtual devices are not duplicated in the selector. |
| Orientation and focus mapping | implemented in source | Pure inverse geometry cases across four orientations/aspect crops are authored; Swift tests not run. Tap-to-scene correspondence is device-unverified. |
| Neutral SDR/sRGB Metal preview | implemented in source | Explicit range/matrix/color-space rules and unsupported HDR/wide-gamut failure path are documented. Metal compile and visual color are unverified. |
| Preview cadence policy | implemented in source | Pure thermal/capture/renderer policy tests are authored; no measured FPS/thermal data. |
| Source-safe capture store and recovery | implemented in source | Atomic source-first flow, write-once UUID directory, recoverable derived failures, scan/reconstruction, and debug fault injection are implemented. Swift tests are authored, not run. |
| Swift native foundation tests | implemented | 15 pure-domain tests in `mobile/ios/Tests/CameraDomainTests.swift`; not locally run because Swift is unavailable. Workflow runs `swift test --package-path ios`. |
| Xcode target, bundle identifier, scheme | scaffolded/hardened | Target source membership, iPhone-only family, provisional `com.chem.camera` ID, and dangling scheme test reference are fixed in source. Project was not opened/built in Xcode. |
| macOS iOS foundation CI | scaffolded | `.github/workflows/ios-foundation-ci.yml` added and YAML/Prettier-checked; no Git remote or `gh` CLI is available, so there is no CI run/evidence yet. |
| CocoaPods integration | scaffolded, blocked | Gemfile lock was resolved, but local bundle install cannot compile `bigdecimal` because Ruby development headers are absent; `pod install` is unavailable. No `Podfile.lock` yet. |
| Simulator behavior | not implemented as camera validation | No simulator runtime was available; the CI simulator build is intended only as an integration/compile gate. |
| Physical iPhone validation | blocked / not device-verified | No iPhone attached. iPhone Air is the first target; all checklist items remain unchecked. |
| Neutral preview copy | placeholder | Clearly signals the neutral baseline only; no film effect is present. |
| Android camera | scaffolded, deferred | Generated RN shell and unavailable-state presentation only; Android camera support is not claimed. |

## Deferred scope

Film Engine and all looks (DAY 200, SKIN 400, NIGHT 800T, grain, bloom, halation, LUT), RAW/ProRAW, calibration profiles, Lab/redevelopment, Gallery/Film Shelf, Photos workflows, manual ISO/shutter, flash, video, sharing, accounts, cloud/backend, and Android camera implementation are deferred. No such feature was implemented in this run.

## Validation log

Commands run from `mobile/` unless noted. `CI-verified` below means an actual GitHub Actions run, not merely a checked-in workflow.

| Command/check | Result |
|---|---|
| `node --version` / `npm --version` | Pass: `v20.19.6` / `11.14.1`. |
| `npm ci` | Pass: installed 864 packages; npm printed 7 moderate advisories. |
| `npm run typecheck` | Pass: exit 0. |
| `npm test -- --runInBand` | Pass: 2 suites, 7 tests, exit 0. |
| `npm run lint` | Pass: exit 0. |
| `npm run codegen:ios` | Pass: generated iOS artifacts. It warned that Pods autolinking output was not yet generated; Codegen completed. |
| `npx react-native config` | Pass: iOS podspec/autolinking metadata resolved. |
| `npx react-native bundle --entry-file index.js --platform ios --dev false --bundle-output /tmp/chem-main.jsbundle --assets-dest /tmp/chem-assets` | Pass: bundle written; CLI warned that sandbox execution of `setup_env.sh` returned EPERM, then continued. |
| `ruby --version`; `ruby -c ios/Podfile`; `ruby -c Gemfile` | Pass: Ruby `3.0.2p107`; both syntax checks report `Syntax OK`. |
| Bundler `lock` using installed Bundler 2.2.22 | Pass: wrote `mobile/Gemfile.lock`; the `bundle` executable is not on PATH. |
| Bundler `install --jobs 4 --retry 3` using Bundler 2.2.22 | Blocked: `bigdecimal` native extension build failed because Ruby headers (`ruby.h`) are missing. |
| `bundle --version` / `pod install` | Blocked: `bundle` / `pod` executables not found. |
| Workflow YAML parse and `npx prettier --check ../.github/workflows/ios-foundation-ci.yml` | Pass. `actionlint` unavailable. |
| `xmllint --noout ios/CHEM.xcodeproj/xcshareddata/xcschemes/CHEM.xcscheme` and `xmllint --noout ios/CHEM/Info.plist` | Pass. |
| `xcodebuild -list -workspace CHEM.xcworkspace` | Blocked: `xcodebuild` unavailable. |
| `xcodebuild -workspace CHEM.xcworkspace -scheme CHEM -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` | Blocked: `xcodebuild` unavailable. |
| `swift test --package-path ios` | Blocked: `swift` unavailable; the 15 tests remain unrun. |
| GitHub Actions | Not triggered/observed: no configured Git remote and no `gh` executable. Workflow awaits a runner; CI-verified = no. |
| iOS simulator / iPhone Air | Not verified: no simulator/Xcode and no physical device. Device-verified = no. |

See [foundation verification](FOUNDATION_VERIFICATION.md), [dependency policy](DEPENDENCY_POLICY.md), [color baseline](COLOR_PIPELINE_BASELINE.md), [performance baseline](PERFORMANCE_BASELINE.md), and [physical-device checklist](PHYSICAL_DEVICE_VALIDATION.md) for details.

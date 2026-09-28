# CHEM native CI verification

## Before

- Workflow: [iOS foundation](https://github.com/tungf0512/CHEM/actions/workflows/ios-foundation-ci.yml)
- Failing run: [36265627280](https://github.com/tungf0512/CHEM/actions/runs/36265627280)
- Commit: `f5ee7c10eafb7c1961c246058309301650d5f335`
- Exact failed step: `Install locked Ruby dependencies`; GitHub's check annotation reports `Process completed with exit code 5.`
- The public run/job APIs show `npm ci`, TypeScript, Jest, lint, and Codegen succeeded. CocoaPods, Xcode workspace validation, simulator build, and native tests were skipped.

The job log and artifact metadata were inspected. GitHub's workflow-run log endpoint returned HTTP 403 with `Must have admin rights to Repository.`; downloading the listed `ios-foundation-logs-36265627280` artifact returned HTTP 401. The public annotation contains only the process exit code, not Bundler's stderr. Therefore the exact failed gem/native-extension error cannot be named from run 1 without repository-admin credentials; this document does not claim otherwise.

The concrete reproducibility defect found in source is a mismatched, under-specified Ruby toolchain: workflow Ruby `3.2`, Gemfile requirement `>= 2.6.10`, and a lockfile generated under Ruby `3.0.2p107` / Bundler `2.2.22` with only the generic `ruby` platform. The exact failed gem remains unverified, but the previous setup did not guarantee the same Ruby/Bundler pair used to generate its lockfile. The new run's summary emits Bundler's actual failure tail so later errors are publicly diagnosable without guessing.

## Dependency decision

| Tool         | Selected version | Decision                                                                                                                                                                                           |
| ------------ | ---------------: | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ruby         |         `3.4.11` | Exact current patch from the maintained Ruby 3.4 line; checked into `mobile/.ruby-version`, read by `Gemfile`, and selected by `ruby/setup-ruby` from `mobile/`.                                   |
| Bundler      |          `2.7.2` | Committed in `mobile/Gemfile.lock`; normal foundation CI installs it with `BUNDLE_FROZEN=true`. The manual refresh workflow uses the same version to regenerate lock metadata on macOS. |
| CocoaPods    |         `1.15.2` | Kept at the already-resolved foundation version to avoid mixing a project-parser upgrade into the CI repair. The existing `xcodeproj` and ActiveSupport compatibility constraints remain.          |
| Node         |        `20.19.6` | Read from the existing `mobile/.nvmrc`; the Node 20 GitHub Action runtime warning is addressed by upgrading the Actions themselves, not the app's Node version.                                    |
| React Native |         `0.86.3` | Existing application version; New Architecture, Fabric, TurboModule, and Codegen remain enabled.                                                                                                   |

## Iterations

| Run ID        | Commit    | Result / last stage                                                                                                                                   | Root cause and fix                                                                                                                                                                                                                                                                                                                                             |
| ------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `36265627280` | `f5ee7c1` | Failed at locked Ruby dependency installation (exit 5). Earlier JS and Codegen stages passed; native stages did not run.                              | Exact Bundler stderr is blocked by GitHub's admin-only log/archive endpoint. Source audit found Ruby/Bundler drift; this task pins Ruby/Bundler and adds public failure-summary output.                                                                                                                                                                        |
| `36292015554` | `8b25348` | Failed at locked Ruby dependency installation; JS, TypeScript, Jest, lint, Codegen, and Ruby setup passed. CocoaPods/Xcode/native tests were skipped. | Public check annotations exposed the exact failure: Bundler `2.7.2` auto-installed and re-executed the lockfile's Bundler `2.2.22`; that version crashed under Ruby `3.4.11` at `DidYouMean::SPELL_CHECKERS`. The workflow now invokes Bundler `2.7.2` directly to regenerate lock metadata before install, then explicitly uses it for install and CocoaPods. |
| `36292468183` | `a40e77c` | Success. Every step passed through Bundler, CocoaPods, workspace/scheme validation, iOS Simulator Debug build, and Swift domain tests.                | The stale lock metadata was regenerated with Bundler `2.7.2` before installation. No Swift, Objective-C++, Fabric, TurboModule, Metal, target-membership, or Codegen source correction was required after the real simulator build.                                                                                                                            |
| `36323536247` | `954fbc7` | Success. Manual macOS lock refresh generated and committed canonical `Gemfile.lock` and `Podfile.lock` in bot commit `57c830d`. | A real CocoaPods resolution exposed a Nanaimo parser failure for unquoted `$(CHEM_BUILD_NUMBER)` and `$(CHEM_BUNDLE_ID)` settings; quoting those settings fixed the resolver. The refresh workflow restores source files after CocoaPods and commits only the two lockfiles. |
| `36324274552` | `1fe7f12` | Success. Committed-lock verification passed through the Simulator build and 16 native tests. | Foundation CI now verifies frozen committed locks instead of regenerating them; no further native compiler correction was required. |
| `36374844760` | `269e82a` | Success. The post-push foundation verification passed every required step. | The manual-only lock-refresh trigger and the documented canonical lock state were verified on the final source checkout. |

## Final evidence

Green GitHub Actions run: [36374844760](https://github.com/tungf0512/CHEM/actions/runs/36374844760), commit `269e82a1ef204b8e2fb25d647ccb3062db372493`, completed `success` on `macos-15`.

- The public Jobs API reports success for every required step: `npm ci`, TypeScript, Jest, lint, Codegen, committed Ruby lock verification, frozen Bundler install, CocoaPods, Podfile lock drift check, workspace/scheme check, iOS Simulator build, and native tests.
- Ruby `3.4.11p137` (from `.ruby-version`), Bundler `2.7.2`, CocoaPods `1.15.2`, Node `20.19.6`, and React Native `0.86.3` are the selected versions. The canonical `mobile/Gemfile.lock` and `mobile/ios/Podfile.lock` were generated by a real macOS resolution in [lock refresh run 36323536247](https://github.com/tungf0512/CHEM/actions/runs/36323536247), committed by `57c830d`, and verified by the final foundation run.
- Workspace/scheme validation succeeded with `xcodebuild -list -workspace ios/CHEM.xcworkspace`.
- Simulator compilation succeeded with `xcodebuild -workspace ios/CHEM.xcworkspace -scheme CHEM -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build`.
- Native domain tests succeeded with `swift test --package-path ios`; the final test target contains 16 XCTest methods. Public Actions logs are admin-gated, so the XCTest runner's printed summary and exact installed Xcode patch version are not available from this environment; the step itself is confirmed successful by the public Jobs API.
- The refresh exposed a Nanaimo parser failure for unquoted `$(CHEM_BUILD_NUMBER)` and `$(CHEM_BUNDLE_ID)` Xcode settings. Quoting those settings fixed the real CocoaPods resolver error. The final Simulator build covered the Swift, Objective-C++, Fabric/TurboModule, Metal, target-membership, and Codegen integration without further compiler fixes.
- Canonical lockfiles are committed; no artifact handoff remains. The refresh workflow deliberately discards CocoaPods source drift and commits only `mobile/Gemfile.lock` and `mobile/ios/Podfile.lock`.
- Device validation is not part of this CI result. iPhone Air remains the first physical target for verifying 1×/2× Main-sensor modes, orientation/focus mapping, source-safe recovery, lifecycle, and neutral preview color.

Task status: `READY_FOR_APPLE_SIGNING_SETUP`.

## Historical lockfile handoff

The first green foundation run uploaded a diagnostic lockfile artifact, but the canonical files were subsequently generated and committed by the macOS refresh workflow. Future dependency changes must use the manual refresh workflow; do not hand-edit either lockfile or commit `Pods/`.

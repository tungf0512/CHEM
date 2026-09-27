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
| Bundler      |          `2.7.2` | Explicitly selected by `ruby/setup-ruby`; CI invokes this version directly to regenerate lock metadata before dependency installation, avoiding auto-restart into the stale `2.2.22` lock version. |
| CocoaPods    |         `1.15.2` | Kept at the already-resolved foundation version to avoid mixing a project-parser upgrade into the CI repair. The existing `xcodeproj` and ActiveSupport compatibility constraints remain.          |
| Node         |        `20.19.6` | Read from the existing `mobile/.nvmrc`; the Node 20 GitHub Action runtime warning is addressed by upgrading the Actions themselves, not the app's Node version.                                    |
| React Native |         `0.86.3` | Existing application version; New Architecture, Fabric, TurboModule, and Codegen remain enabled.                                                                                                   |

## Iterations

| Run ID        | Commit    | Result / last stage                                                                                                                                   | Root cause and fix                                                                                                                                                                                                                                                                                                                                             |
| ------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `36265627280` | `f5ee7c1` | Failed at locked Ruby dependency installation (exit 5). Earlier JS and Codegen stages passed; native stages did not run.                              | Exact Bundler stderr is blocked by GitHub's admin-only log/archive endpoint. Source audit found Ruby/Bundler drift; this task pins Ruby/Bundler and adds public failure-summary output.                                                                                                                                                                        |
| `36292015554` | `8b25348` | Failed at locked Ruby dependency installation; JS, TypeScript, Jest, lint, Codegen, and Ruby setup passed. CocoaPods/Xcode/native tests were skipped. | Public check annotations exposed the exact failure: Bundler `2.7.2` auto-installed and re-executed the lockfile's Bundler `2.2.22`; that version crashed under Ruby `3.4.11` at `DidYouMean::SPELL_CHECKERS`. The workflow now invokes Bundler `2.7.2` directly to regenerate lock metadata before install, then explicitly uses it for install and CocoaPods. |
| `36292468183` | `a40e77c` | Success. Every step passed through Bundler, CocoaPods, workspace/scheme validation, iOS Simulator Debug build, and Swift domain tests.                | The stale lock metadata was regenerated with Bundler `2.7.2` before installation. No Swift, Objective-C++, Fabric, TurboModule, Metal, target-membership, or Codegen source correction was required after the real simulator build.                                                                                                                            |

## Final evidence

Green GitHub Actions run: [36292468183](https://github.com/tungf0512/CHEM/actions/runs/36292468183), commit `a40e77ca87e314a9dd658ac6f002bac3cbfdfe20`, completed `success` on `macos-15`.

- The public Jobs API reports success for every required step: `npm ci`, TypeScript, Jest, lint, Codegen, lock refresh, Bundler install, CocoaPods, Podfile lock check, workspace/scheme check, iOS Simulator build, and native tests.
- Ruby `3.4.11` (from `.ruby-version`), Bundler `2.7.2`, CocoaPods `1.15.2`, Node `20.19.6`, and React Native `0.86.3` are the selected versions. The runner's generated `Gemfile.lock` records Bundler `2.7.2`; CocoaPods resolved successfully and produced `Podfile.lock`.
- Workspace/scheme validation succeeded with `xcodebuild -list -workspace ios/CHEM.xcworkspace`.
- Simulator compilation succeeded with `xcodebuild -workspace ios/CHEM.xcworkspace -scheme CHEM -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build`.
- Native domain tests succeeded with `swift test --package-path ios`. The test target declares 15 XCTest methods. Public Actions logs are admin-gated, so the XCTest runner's printed summary and exact installed Xcode patch version are not available from this environment; the step itself is confirmed successful by the public Jobs API.
- No native compiler fixes were necessary. The actual Xcode build covered the existing Swift, Objective-C++, Fabric/TurboModule, and Metal integration.
- The lockfile artifact `ios-foundation-lockfiles-36292468183` is present (7,933 bytes), but its archive endpoint returned HTTP 401 here. The runner-generated `mobile/Gemfile.lock` and `mobile/ios/Podfile.lock` are therefore not committed from this environment; use the exact artifact handoff below.
- Device validation is not part of this CI result. iPhone Air remains the first physical target for verifying 1×/2× Main-sensor modes, orientation/focus mapping, source-safe recovery, lifecycle, and neutral preview color.

Task status: `READY_FOR_DEVICE_VALIDATION`.

## Lockfile handoff

Each run uploads `ios-foundation-lockfiles-<run-id>` with the runner-generated `mobile/Gemfile.lock` and `mobile/ios/Podfile.lock`. This environment can read public run metadata but cannot download GitHub's private-to-admin log/artifact archives. With authenticated GitHub CLI access, retrieve the resolution using:

```sh
gh run download 36292468183 \
  --repo tungf0512/CHEM \
  --name ios-foundation-lockfiles-36292468183 \
  --dir /tmp/chem-ios-lockfiles
```

The artifact's common path root is `mobile/`, so the downloaded files are `Gemfile.lock` and `ios/Podfile.lock` inside `/tmp/chem-ios-lockfiles`. Copy them to `mobile/Gemfile.lock` and `mobile/ios/Podfile.lock`, respectively, then commit the generated files. Do not commit `Pods/`.

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

| Tool         | Selected version | Decision                                                                                                                                                                                  |
| ------------ | ---------------: | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Ruby         |         `3.4.11` | Exact current patch from the maintained Ruby 3.4 line; checked into `mobile/.ruby-version`, read by `Gemfile`, and selected by `ruby/setup-ruby` from `mobile/`.                          |
| Bundler      |          `2.7.2` | Explicitly selected by `ruby/setup-ruby`; CI invokes this version directly to regenerate lock metadata before dependency installation, avoiding auto-restart into the stale `2.2.22` lock version. |
| CocoaPods    |         `1.15.2` | Kept at the already-resolved foundation version to avoid mixing a project-parser upgrade into the CI repair. The existing `xcodeproj` and ActiveSupport compatibility constraints remain. |
| Node         |        `20.19.6` | Read from the existing `mobile/.nvmrc`; the Node 20 GitHub Action runtime warning is addressed by upgrading the Actions themselves, not the app's Node version.                           |
| React Native |         `0.86.3` | Existing application version; New Architecture, Fabric, TurboModule, and Codegen remain enabled.                                                                                          |

## Iterations

| Run ID        | Commit    | Result / last stage                                                                                                                                   | Root cause and fix                                                                                                                                                                                                                                                                                                                                             |
| ------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `36265627280` | `f5ee7c1` | Failed at locked Ruby dependency installation (exit 5). Earlier JS and Codegen stages passed; native stages did not run.                              | Exact Bundler stderr is blocked by GitHub's admin-only log/archive endpoint. Source audit found Ruby/Bundler drift; this task pins Ruby/Bundler and adds public failure-summary output.                                                                                                                                                                        |
| `36292015554` | `8b25348` | Failed at locked Ruby dependency installation; JS, TypeScript, Jest, lint, Codegen, and Ruby setup passed. CocoaPods/Xcode/native tests were skipped. | Public check annotations exposed the exact failure: Bundler `2.7.2` auto-installed and re-executed the lockfile's Bundler `2.2.22`; that version crashed under Ruby `3.4.11` at `DidYouMean::SPELL_CHECKERS`. The workflow now invokes Bundler `2.7.2` directly to regenerate lock metadata before install, then explicitly uses it for install and CocoaPods. |
| Pending       | Pending   | Pending macOS runner evidence.                                                                                                                        | Follow the actual Actions run through CocoaPods, workspace/scheme validation, simulator compilation, and Swift tests. Do not infer success from source or local Linux checks.                                                                                                                                                                                  |

## Final evidence

Pending a full green macOS Actions run. Required evidence to record here:

- GitHub Actions run URL, ID, commit, and conclusion.
- `bundle install` / CocoaPods versions and result.
- Workspace/scheme list result.
- iOS Simulator Debug `xcodebuild` result.
- Native Swift domain-test count/result.
- Whether generated `Gemfile.lock` and `Podfile.lock` were committed or remain in the authenticated lockfile artifact.

## Lockfile handoff

Each run uploads `ios-foundation-lockfiles-<run-id>` with the runner-generated `mobile/Gemfile.lock` and `mobile/ios/Podfile.lock`. This environment can read public run metadata but cannot download GitHub's private-to-admin log/artifact archives. With authenticated GitHub CLI access, retrieve the resolution using:

```sh
gh run download <GREEN_RUN_ID> \
  --repo tungf0512/CHEM \
  --name ios-foundation-lockfiles-<GREEN_RUN_ID> \
  --dir /tmp/chem-ios-lockfiles
```

The artifact's common path root is `mobile/`, so the downloaded files are `Gemfile.lock` and `ios/Podfile.lock` inside `/tmp/chem-ios-lockfiles`. Copy them to `mobile/Gemfile.lock` and `mobile/ios/Podfile.lock`, respectively, then commit the generated files. Do not commit `Pods/`.

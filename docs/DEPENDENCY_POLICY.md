# Dependency and generated-artifact policy

- `mobile/package-lock.json` is committed and `npm ci` is the JavaScript install path.
- `mobile/Gemfile` and `mobile/Gemfile.lock` are committed; CocoaPods is installed through Bundler. CI runs `bundle install` before `bundle exec pod install`.
- `mobile/ios/Pods/` is generated and ignored; never commit it.
- React Native Codegen artifacts under `mobile/build/generated/` are generated during CI/build and are not committed.
- `mobile/ios/Podfile.lock` is the intended checked-in CocoaPods resolution lock. It is not present yet: this Linux environment lacks the Ruby development headers needed to install the locked CocoaPods bundle and has no macOS/Xcode toolchain. The first successful macOS `pod install` must produce the lock and it must be committed before claiming dependency-resolution reproducibility. Until then, the workflow can validate CocoaPods integration but its pod resolution is not pinned by a repository lock.

The npm lockfile and Bundler lockfile are present; CocoaPods lockfile generation remains a macOS CI/bootstrap follow-up rather than an asserted success. The policy intentionally keeps dependencies and generated build products separate from source-controlled app code.

# CHEM internal TestFlight setup

The signed release path is intentionally manual and internal-only. It is implemented by `.github/workflows/testflight-internal.yml` and never runs on push.

## Apple prerequisites

1. Maintain an active Apple Developer Program membership.
2. Register the Bundle ID that will be used for `CHEM_BUNDLE_ID`.
3. Create the matching App Store Connect app record before the first upload.
4. Create an App Store Connect API key with sufficient access for internal TestFlight uploads. Keep the `.p8` private key private.
5. Export an Apple Distribution certificate as a password-protected `.p12` file.
6. Create an App Store distribution provisioning profile for the registered Bundle ID.
7. Add the intended internal tester/App Store Connect user.
8. Install TestFlight on the validation iPhone Air and sign in as an internal tester.

## GitHub configuration

In the repository, open **Settings → Secrets and variables → Actions**.

Add these **repository variables**:

```text
CHEM_BUNDLE_ID
APPLE_TEAM_ID
APPSTORE_ISSUER_ID
APPSTORE_API_KEY_ID
```

Add these **repository secrets**:

```text
APPSTORE_API_PRIVATE_KEY
APPSTORE_CERTIFICATES_FILE_BASE64
APPSTORE_CERTIFICATES_PASSWORD
```

`APPSTORE_CERTIFICATES_FILE_BASE64` is the base64 representation of the `.p12` file. The `.p8`, `.p12`, passwords, provisioning profiles, and any private key material must never be committed or pasted into source/chat.

The workflow preflight checks only whether these names have values. It prints missing names, never secret contents. The bundle ID and team ID are passed to the archive, provisioning-profile selection, and export options; no final bundle ID is assumed by the project.

## Running the release

Open **Actions → TestFlight internal release → Run workflow**. The job runs JavaScript checks, Codegen, frozen Bundler/CocoaPods resolution, certificate/profile installation, a Release archive with `CHEM_INTERNAL_VALIDATION`, IPA export, and Apple TestFlight upload. The first build is internal TestFlight only; no public or external testing track is configured.

The workflow uses Apple-maintained actions at pinned major versions (`import-codesign-certs@v7`, `download-provisioning-profiles@v6`, `xcodebuild@v1`, and `upload-testflight-build@v5`). It verifies the runner's selected Xcode and iPhoneOS SDK before signing. Build number is the GitHub run number; marketing version is `0.1.0`.

CHEM has no custom encryption implementation. The export declares non-exempt encryption as false, which must be revisited if a future dependency or feature changes that audit.

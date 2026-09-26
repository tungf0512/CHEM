# ADR-002: React Native New Architecture and Codegen

- Status: accepted
- Context: The camera view needs a typed native host and permission/storage APIs without falling back to an untyped legacy device-event bridge.
- Decision: Use the bare RN New Architecture with a Codegen Fabric component (`CHEMCameraPreview`) and TurboModule (`CHEMCameraModule`), with minimal handwritten ObjC++ adapters to Swift.
- Consequences: Codegen naming/configuration and CocoaPods/Xcode integration are part of validation. Generated files are build output, not handwritten source. Native execution remains unverified until an iOS toolchain is available.

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "CHEMNativeDomain",
  platforms: [.iOS(.v15), .macOS(.v12)],
  products: [
    .library(name: "CHEMNativeDomain", targets: ["CHEMNativeDomain"]),
  ],
  targets: [
    .target(
      name: "CHEMNativeDomain",
      path: "CHEM",
      sources: [
        "CameraCore/CameraTypes.swift",
        "CameraCore/CameraLogger.swift",
        "CameraCore/CameraGeometry.swift",
        "CameraCore/CameraLensCatalog.swift",
        "Imaging/Preview/PreviewFrameRatePolicy.swift",
        "Storage/CaptureStore.swift",
      ]
    ),
    .testTarget(
      name: "CHEMNativeDomainTests",
      dependencies: ["CHEMNativeDomain"],
      path: "Tests"
    ),
  ]
)

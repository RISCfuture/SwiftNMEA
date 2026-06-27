// swift-tools-version: 6.3

import CompilerPluginSupport
import PackageDescription

let approachableConcurrency: [SwiftSetting] = [
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  .enableUpcomingFeature("InferIsolatedConformances")
]

let package = Package(
  name: "SwiftNMEA",
  defaultLocalization: "en",
  platforms: [.iOS(.v18), .macOS(.v15), .tvOS(.v18), .visionOS(.v2), .watchOS(.v11)],
  products: [
    .library(
      name: "SwiftNMEA",
      targets: ["SwiftNMEA"]
    ),
    .library(
      name: "SwiftDSE",
      targets: ["SwiftDSE"]
    ),
    .library(
      name: "NMEAUnits",
      targets: ["NMEAUnits"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
    .package(url: "https://github.com/Quick/Nimble.git", from: "14.0.0"),
    .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "603.0.0"),
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
    .package(url: "https://github.com/stackotter/swift-macro-toolkit.git", from: "0.9.0"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0")
  ],
  targets: [
    .macro(
      name: "SwiftNMEA_Macros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "MacroToolkit", package: "swift-macro-toolkit")
      ],
      swiftSettings: approachableConcurrency
    ),
    .target(name: "NMEACommon", swiftSettings: approachableConcurrency),
    .target(name: "NMEAUnits", swiftSettings: approachableConcurrency),
    .target(name: "SwiftDSE", dependencies: ["NMEACommon"], swiftSettings: approachableConcurrency),
    .target(
      name: "SwiftNMEA",
      dependencies: [
        .product(name: "Algorithms", package: "swift-algorithms"),
        .product(name: "Collections", package: "swift-collections"),
        "NMEACommon",
        "NMEAUnits",
        "SwiftDSE",
        "SwiftNMEA_Macros"
      ],
      swiftSettings: approachableConcurrency
    ),
    .testTarget(
      name: "SwiftNMEATests",
      dependencies: [
        "SwiftNMEA",
        "SwiftDSE",
        "Quick",
        "Nimble",
        .product(name: "Algorithms", package: "swift-algorithms")
      ],
      swiftSettings: approachableConcurrency
    )
  ],
  swiftLanguageModes: [.v5, .v6]
)

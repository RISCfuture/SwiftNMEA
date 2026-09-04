// swift-tools-version: 6.3

import CompilerPluginSupport
import PackageDescription

let upcomingFeatures: [SwiftSetting] = [
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  .enableUpcomingFeature("InferIsolatedConformances"),
  .enableUpcomingFeature("ImmutableWeakCaptures"),
  .enableUpcomingFeature("MemberImportVisibility"),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("InternalImportsByDefault")
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
    .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.1"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "603.0.2"),
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.6.0"),
    .package(url: "https://github.com/stackotter/swift-macro-toolkit.git", from: "0.9.0"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.5.0")
  ],
  targets: [
    .macro(
      name: "SwiftNMEA_Macros",
      dependencies: [
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "MacroToolkit", package: "swift-macro-toolkit")
      ],
      swiftSettings: upcomingFeatures
    ),
    .target(name: "NMEACommon", swiftSettings: upcomingFeatures),
    .target(name: "NMEAUnits", swiftSettings: upcomingFeatures),
    .target(name: "SwiftDSE", dependencies: ["NMEACommon"], swiftSettings: upcomingFeatures),
    .target(
      name: "SwiftNMEA",
      dependencies: [
        .product(name: "Algorithms", package: "swift-algorithms"),
        .product(name: "BitCollections", package: "swift-collections"),
        .product(name: "Collections", package: "swift-collections"),
        "NMEACommon",
        "NMEAUnits",
        "SwiftDSE",
        "SwiftNMEA_Macros"
      ],
      swiftSettings: upcomingFeatures
    ),
    .testTarget(
      name: "SwiftNMEATests",
      dependencies: [
        "SwiftNMEA",
        "SwiftDSE",
        .product(name: "Algorithms", package: "swift-algorithms")
      ],
      swiftSettings: upcomingFeatures
    )
  ],
  swiftLanguageModes: [.v5, .v6]
)

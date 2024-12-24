// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "SwiftNMEA",
    defaultLocalization: "en",
    platforms: [.iOS(.v12), .macOS(.v13), .tvOS(.v12), .visionOS(.v1), .watchOS(.v4)],
    products: [
        .library(
            name: "SwiftNMEA",
            targets: ["SwiftNMEA"]),
        .library(
            name: "SwiftDSE",
            targets: ["SwiftDSE"]),
        .library(
            name: "NMEAUnits",
            targets: ["NMEAUnits"])
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.2.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.1"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.4"),
        .package(url: "https://github.com/stackotter/swift-macro-toolkit.git", from: "0.6.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0")
    ],
    targets: [
        .macro(
            name: "SwiftNMEA_Macros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "MacroToolkit", package: "swift-macro-toolkit")]),
        .target(name: "NMEACommon"),
        .target(name: "NMEAUnits"),
        .target(name: "SwiftDSE", dependencies: ["NMEACommon"]),
        .target(
            name: "SwiftNMEA",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "Collections", package: "swift-collections"),
                "NMEACommon",
                "NMEAUnits",
                "SwiftDSE",
                "SwiftNMEA_Macros"]),
        .testTarget(
            name: "SwiftNMEATests",
            dependencies: [
                "SwiftNMEA",
                "Quick",
                "Nimble",
                .product(name: "Algorithms", package: "swift-algorithms")])
    ],
    swiftLanguageModes: [.v5, .v6]
)

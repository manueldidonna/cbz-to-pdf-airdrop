// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "comics-converter",
    platforms: [
        .macOS(.v10_12),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0")),
    ],
    targets: [
        .executableTarget(
            name: "comics-converter",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .byName(name: "ZIPFoundation"),
            ]),
        .testTarget(
            name: "comics-converterTests",
            dependencies: ["comics-converter"]),
    ])

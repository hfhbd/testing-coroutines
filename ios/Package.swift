// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ios",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "ios",
            targets: ["ios"]),
    ],
    dependencies: [
        .package(name: "shared", path: "../clients/build/XCFrameworks/debug")
    ],
    targets: [
        .target(
            name: "ios",
            dependencies: ["shared"]),
        .testTarget(
            name: "iosTests",
            dependencies: ["ios"]),
    ]
)

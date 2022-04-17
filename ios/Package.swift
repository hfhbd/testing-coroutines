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
        .package(name: "testing_coroutines", path: "../build/XCFrameworks/debug")
    ],
    targets: [
        .target(
            name: "ios",
            dependencies: [
              .product(name: "testing_coroutines", package: "testing_coroutines"),
            ]),
        .testTarget(
            name: "iosTests",
            dependencies: ["ios"]),
    ]
)

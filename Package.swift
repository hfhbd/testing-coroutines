// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "app",
    platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(
            name: "app",
            targets: ["app"]),
    ],
    dependencies: [
        .package(name: "testing_coroutines", path: "build/XCFrameworks/release"),
        .package(name: "testCounter", path: "testCounter/build/XCFrameworks/debug")
    ],
    targets: [
        .target(
            name: "app",
            dependencies: [
              .product(name: "testing_coroutines", package: "testing_coroutines"),
            ]),
        .testTarget(
            name: "appTests",
            dependencies: [
                "app",
                .product(name: "testCounter", package: "testCounter")
            ]),
    ]
)

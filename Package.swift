// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SayToIt",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SayToIt", targets: ["SayToIt"]),
        .library(name: "SayToItCore", targets: ["SayToItCore"])
    ],
    targets: [
        .target(
            name: "SayToItCore",
            dependencies: [],
            path: "Sources/SayToItCore"
        ),
        .executableTarget(
            name: "SayToIt",
            dependencies: ["SayToItCore"],
            path: "Sources/SayToIt"
        ),
        .testTarget(
            name: "SayToItCoreTests",
            dependencies: ["SayToItCore"],
            path: "Tests/SayToItCoreTests"
        ),
        .testTarget(
            name: "SayToItTests",
            dependencies: ["SayToIt", "SayToItCore"],
            path: "Tests/SayToItTests"
        )
    ]
)

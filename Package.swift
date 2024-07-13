// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StatusIcon",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "StatusIcon", targets: ["StatusIcon"]),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "StatusIcon",
            dependencies: [],
            exclude: ["README.md"]
        )
    ]
)
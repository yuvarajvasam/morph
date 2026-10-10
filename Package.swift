// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "morph",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "morph", targets: ["morph"]),
        .library(name: "MorphKit", targets: ["MorphKit"])
    ],
    targets: [
        .target(
            name: "MorphKit",
            dependencies: [],
            path: "Sources/MorphKit"
        ),
        .executableTarget(
            name: "morph",
            dependencies: ["MorphKit"],
            path: "Sources/morph"
        ),
        .executableTarget(
            name: "morph-test-runner",
            dependencies: ["MorphKit"],
            path: "Sources/MorphTestRunner"
        )
    ]
)


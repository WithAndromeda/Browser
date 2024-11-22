// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Andromeda",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Andromeda",
            dependencies: []),
        .testTarget(
            name: "AndromedaTests",
            dependencies: ["Andromeda"]),
    ]
)

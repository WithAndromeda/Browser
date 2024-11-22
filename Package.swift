// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Andromeda",
    platforms: [
        .macOS(.v11)
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

// swift-tools-version:5.5
//
//  Package.swift
//  Andromeda
//
//  Created by WithAndromeda on 10/20/24.
//

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
            dependencies: [],
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "AndromedaTests",
            dependencies: ["Andromeda"]),
    ]
)

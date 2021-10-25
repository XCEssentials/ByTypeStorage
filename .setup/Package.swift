// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "ByTypeStorageSetup",
    platforms: [
        .macOS(.v10_11),
    ],
    products: [
        .executable(
            name: "ByTypeStorageSetup",
            targets: ["ByTypeStorageSetup"])
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit", from: "1.0.0"),
        .package(url: "https://github.com/XCEssentials/RepoConfigurator", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "ByTypeStorageSetup",
            dependencies: ["XCERepoConfigurator", "PathKit"],
            path: "Sources",
            sources: ["main.swift"]
        )
    ]
)

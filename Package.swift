// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "XCEByTypeStorage",
    products: [
        .library(
            name: "XCEByTypeStorage",
            targets: [
                "XCEByTypeStorage"
            ]
        )
    ],
    targets: [
        .target(
            name: "XCEByTypeStorage",
            path: "Sources/Core"
        ),
        .testTarget(
            name: "XCEByTypeStorageAllTests",
            dependencies: [
                "XCEByTypeStorage"
            ],
            path: "Tests/AllTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
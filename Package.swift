// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "XCEByTypeStorage",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v15)
    ],
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
    ]
)

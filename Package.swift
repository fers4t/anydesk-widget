// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AnyDeskWidget",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "AnyDeskWidget",
            path: "Sources/AnyDeskWidget"
        ),
        .testTarget(
            name: "AnyDeskWidgetTests",
            dependencies: ["AnyDeskWidget"]
        )
    ]
)

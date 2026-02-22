// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Punch",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Punch",
            path: "Sources/Punch"
        )
    ]
)

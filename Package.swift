// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Converta",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "Converta",
            path: "Sources/Converta"
        )
    ]
)

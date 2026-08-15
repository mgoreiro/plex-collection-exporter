// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlexCollectionExporter",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "PlexCollectionExporter",
            path: "Sources/PlexCollectionExporter"
        )
    ]
)

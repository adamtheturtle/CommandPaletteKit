// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommandPaletteKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "CommandPaletteKit", targets: ["CommandPaletteKit"])
    ],
    targets: [
        .target(name: "CommandPaletteKit"),
        .testTarget(
            name: "CommandPaletteKitTests",
            dependencies: ["CommandPaletteKit"]
        )
    ]
)

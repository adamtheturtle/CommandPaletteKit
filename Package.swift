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
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        .target(name: "CommandPaletteKit"),
        .testTarget(
            name: "CommandPaletteKitTests",
            dependencies: ["CommandPaletteKit"]
        )
    ]
)

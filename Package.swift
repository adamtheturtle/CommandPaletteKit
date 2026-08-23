// swift-tools-version: 6.0
import Foundation
import PackageDescription

let package = Package(
    name: "CommandPaletteKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17)
    ],
    products: [
        .library(name: "CommandPaletteKit", targets: ["CommandPaletteKit"]),
        .executable(name: "CommandPaletteKitDemo", targets: ["CommandPaletteKitDemo"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CommandPaletteKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "CommandPaletteKitTests",
            dependencies: ["CommandPaletteKit"]
        ),
        .executableTarget(
            name: "CommandPaletteKitDemo",
            dependencies: ["CommandPaletteKit"],
            path: "DemoApp"
        )
    ]
)

// Resolve the DocC plugin only when generating documentation so app consumers do not
// download it as a transitive dependency of every Package.resolved refresh.
//
// `SWIFT_PACKAGE_ENABLE_DOCC` covers local and CI docs builds. `SPI_BUILDER` is set by
// Swift Package Index: SPI greps Package.swift for the plugin URL and skips injecting its
// own copy when the string is present, so we must enable the dependency under that env too.
let environment = ProcessInfo.processInfo.environment
if environment["SWIFT_PACKAGE_ENABLE_DOCC"] == "1"
    || environment["SPI_BUILDER"] != nil
{
    package.dependencies.append(
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    )
}

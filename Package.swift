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
        .library(name: "CommandPaletteKit", targets: ["CommandPaletteKit"])
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
        )
    ]
)

// Resolve the DocC plugin only when generating documentation so app consumers do not
// download it as a transitive dependency of every Package.resolved refresh.
if ProcessInfo.processInfo.environment["SWIFT_PACKAGE_ENABLE_DOCC"] == "1" {
    package.dependencies.append(
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    )
}

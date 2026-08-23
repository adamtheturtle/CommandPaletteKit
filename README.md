# CommandPaletteKit

A dependency-free SwiftUI command palette for macOS, iPad, and Apple TV.

[Documentation](https://swiftpackageindex.com/adamtheturtle/CommandPaletteKit/documentation/commandpalettekit) |
[Swift Package Index](https://swiftpackageindex.com/adamtheturtle/CommandPaletteKit)

## Installation

```swift
.package(url: "https://github.com/adamtheturtle/CommandPaletteKit.git", from: "0.1.0")
```

Add the `CommandPaletteKit` product to your target dependencies.

## Usage

Present the palette as a sheet and supply candidates:

```swift
import CommandPaletteKit
import SwiftUI

struct ContentView: View {
    @State private var showingPalette = false

    var body: some View {
        Button("Jump to…") { showingPalette = true }
            .keyboardShortcut("k", modifiers: .command)
            .sheet(isPresented: $showingPalette) {
                CommandPaletteView {
                    [
                        PaletteResult(
                            id: "command.new",
                            title: "New Document",
                            subtitle: "Create a document",
                            category: "Command",
                            systemImage: "plus.square"
                        ) { /* create document */ },
                        PaletteResult(
                            id: "nav.settings",
                            title: "Settings",
                            category: "Navigate",
                            systemImage: "gearshape"
                        ) { /* open settings */ }
                    ]
                }
            }
    }
}
```

See the [Getting started](https://swiftpackageindex.com/adamtheturtle/CommandPaletteKit/documentation/commandpalettekit/gettingstarted)
article for async providers, custom rows, and styling.

## Local development against a checkout

To try an unpublished branch from an app that already depends on the package, point the
dependency at your local clone:

```swift
.package(path: "../CommandPaletteKit")
```

Or override a remote dependency temporarily with Xcode's local package replacement, or with
SwiftPM's `--replace-scm-with-registry` / path-based `Package.swift` edits in a private fork.
Keep the package's platforms and Swift tools version aligned with the host app, then run
`swift test` in the checkout before integrating.

## Product

- `CommandPaletteKit`: Searchable command palette UI with fuzzy matching, keyboard
  navigation, and action-backed results.

## Requirements

- Swift 6.0+
- macOS 14+, iOS 17+, or tvOS 17+

## License

MIT. See [LICENSE](LICENSE).

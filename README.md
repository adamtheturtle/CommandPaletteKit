# CommandPaletteKit

[![CI](https://github.com/adamtheturtle/CommandPaletteKit/actions/workflows/ci.yml/badge.svg)](https://github.com/adamtheturtle/CommandPaletteKit/actions/workflows/ci.yml)
[![Swift Package Index versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fadamtheturtle%2FCommandPaletteKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/adamtheturtle/CommandPaletteKit)
[![Swift Package Index platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fadamtheturtle%2FCommandPaletteKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/adamtheturtle/CommandPaletteKit)

A dependency-free, Combine-free SwiftUI command palette (⌘K) for macOS and iPad - the
"jump to anything" overlay you get in VS Code, Raycast, or GitHub's `cmd-k`. It's an
*action* palette: each result carries a `@MainActor` action it runs when activated.

Pure SwiftUI (plus a little AppKit for one macOS keyboard fix), with built-in fuzzy
matching, hardware-keyboard navigation on macOS and iPad, and sensible defaults so the
zero-config call site stays short.

## Installation

Swift Package Manager:

```swift
.package(url: "https://github.com/adamtheturtle/CommandPaletteKit", from: "0.1.0")
```

Then add `"CommandPaletteKit"` to your target's dependencies.

## Quick start

```swift
import CommandPaletteKit

.sheet(isPresented: $showingPalette) {
    CommandPaletteView {
        [
            PaletteResult(
                id: "command.new",
                title: "New Document",
                subtitle: "Create a document",
                category: "Command",
                systemImage: "plus.square",
                searchText: "New Document create"
            ) { createDocument() },

            PaletteResult(
                id: "nav.settings",
                title: "Settings",
                category: "Navigate",
                systemImage: "gearshape"
            ) { openSettings() }
        ]
    }
}
```

Trigger it with the conventional ⌘K:

```swift
.keyboardShortcut("k", modifiers: .command)
```

## Documentation

Full documentation - getting started, customization (custom rows, async candidates,
styling, scoring), and keyboard navigation - is published with DocC:

**[Swift Package Index documentation](https://swiftpackageindex.com/adamtheturtle/CommandPaletteKit/documentation/commandpalettekit)**

To browse it locally:

```sh
swift package --disable-sandbox preview-documentation --target CommandPaletteKit
```

## License

MIT. See [LICENSE](LICENSE).

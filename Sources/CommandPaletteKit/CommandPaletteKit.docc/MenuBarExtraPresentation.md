# Menu bar extra presentation

Present the palette from a menu bar extra on macOS.

## Overview

Menu bar apps often expose a compact command surface through a ``MenuBarExtra``. Pair it
with ``CommandPaletteView`` so users can fuzzy-search actions that are not worth listing
individually in the menu.

### Present from a menu bar extra

```swift
import CommandPaletteKit
import SwiftUI

@main
struct MenuBarPaletteApp: App {
    @State private var showingPalette = false

    var body: some Scene {
        MenuBarExtra("Commands", systemImage: "command") {
            Button("Jump to…") { showingPalette = true }
                .keyboardShortcut("k", modifiers: .command)
        }
        .menuBarExtraStyle(.window)

        Window("Command Palette", id: "palette") {
            CommandPaletteView {
                buildMenuBarCommands()
            }
        }
        .defaultSize(width: 620, height: 460)
        .windowResizability(.contentSize)
    }
}
```

### Tips

- Use a dedicated ``Window`` scene for the palette so it can grow with results while the
  menu bar icon stays compact.
- Prefer a sheet presentation from a regular document window when the palette is modal.
- Async candidate providers work well here when commands depend on remote state.

## See also

- <doc:GettingStarted>
- ``CommandPaletteView``

# Getting started

Present the palette, supply candidates, and wire up a shortcut.

## Overview

``CommandPaletteView`` is a self-contained surface: a search field above a scrolling,
keyboard-navigable result list. Present it however you like - a sheet is typical - and
hand it a closure that builds the candidate list.

### Present the palette

```swift
import CommandPaletteKit

struct ContentView: View {
    @State private var showingPalette = false

    var body: some View {
        MyMainContent()
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
    }
}
```

### Trigger it with a shortcut

Bind the presentation to the conventional ⌘K:

```swift
.keyboardShortcut("k", modifiers: .command)
```

### Build candidates

Each ``PaletteResult`` is a row plus a `@MainActor` action. A few fields shape how it is
found and shown:

- ``PaletteResult/searchText`` is what the query scores against first - fold in synonyms so a
  row is found by more than its title (e.g. find "Reload" by typing "refresh"). The default
  ranking also considers ``PaletteResult/title``, ``PaletteResult/subtitle``, and
  ``PaletteResult/category``.
- ``PaletteResult/showsOnlyWhenSearching`` hides a row until the user types, so a large
  category doesn't flood the empty-query list yet stays reachable by searching.
- ``PaletteResult/category`` is an optional trailing tag - free text, so the palette stays
  domain-agnostic.

### Curate the empty-query list

With an empty search field the palette shows every candidate that does not set
``PaletteResult/showsOnlyWhenSearching`` to `true`. Mark infrequent commands with that flag
to keep the default list short while still finding them once the user types:

```swift
PaletteResult(
    id: "debug.reset",
    title: "Reset Debug State",
    systemImage: "arrow.counterclockwise",
    showsOnlyWhenSearching: true
) { resetDebugState() }
```

Pair this with a small set of always-visible "pinned" commands (no flag) to curate what
appears before the user searches.

### Route activation

By default the palette dismisses and calls the result's `action`. Pass `onActivate:` to
route activation yourself instead - useful when a single handler should dispatch every
result:

```swift
CommandPaletteView(onActivate: { result in router.handle(result.id) }) {
    buildCandidates()
}
```

See <doc:Customization> for the full set of knobs, and <doc:KeyboardNavigation> for how the
palette is driven from the keyboard.

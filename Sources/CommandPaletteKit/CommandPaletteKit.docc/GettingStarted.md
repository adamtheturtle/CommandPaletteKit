# Getting started

Present the palette, supply candidates, and wire up a shortcut.

## Overview

``CommandPaletteView`` combines a search field with a scrolling list that supports keyboard navigation.
Present it however you like - a sheet is typical - and hand it a closure that builds the candidate list.

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

Each ``PaletteResult`` is a row plus a `@MainActor` action.
These fields affect search and display:

- ``PaletteResult/searchText`` is what the query scores against first - fold in synonyms so a row is found by more than its title (e.g. find "Reload" by typing "refresh").
  The default ranking also considers ``PaletteResult/title``, ``PaletteResult/subtitle``, and ``PaletteResult/category``.
- ``PaletteResult/showsOnlyWhenSearching``displays a row only while the user is searching.
  Use it for categories with many results.
- ``PaletteResult/category`` adds an optional free-text tag at the end of a row.

### Curate the empty-query list

With an empty search field the palette shows every candidate that does not set ``PaletteResult/showsOnlyWhenSearching`` to `true`.
Set this flag on infrequent commands to show them only in search results:

```swift
PaletteResult(
    id: "debug.reset",
    title: "Reset Debug State",
    systemImage: "arrow.counterclockwise",
    showsOnlyWhenSearching: true
) { resetDebugState() }
```

Pair this with a small set of always-visible "pinned" commands (no flag) to curate what appears before the user searches.

### Route activation

By default the palette dismisses and calls the result's `action`.
Pass `onActivate:` to dispatch results through one handler:

```swift
CommandPaletteView(onActivate: { result in router.handle(result.id) }) {
    buildCandidates()
}
```

See <doc:Customization> for the full set of knobs, and <doc:KeyboardNavigation> for how the palette is driven from the keyboard.

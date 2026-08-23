# Split view inspector presentation

Present the palette beside a detail pane in a navigation split view.

## Overview

On iPad and macOS, a command palette can sit in the trailing column of a
``NavigationSplitView`` instead of a sheet. The search field keeps keyboard focus while
the leading column shows your document list and the detail column shows the selected item.

### Basic layout

```swift
import CommandPaletteKit
import SwiftUI

struct InspectorPaletteApp: View {
    @State private var selection: String?
    @State private var query = ""

    var body: some View {
        NavigationSplitView {
            List(documents, id: \.id, selection: $selection) { doc in
                Text(doc.title)
            }
        } detail: {
            if let selection {
                DocumentDetail(id: selection)
            } else {
                CommandPaletteView {
                    buildCommands()
                }
                .frame(maxWidth: 620, maxHeight: 460)
            }
        }
    }
}
```

### Tips

- Keep the palette width near the default 620 points so rows stay readable in the inspector.
- Use ``PaletteResult/showsOnlyWhenSearching`` for large command catalogs so the empty
  query list stays short.
- Apply ``SwiftUICore/View/commandPaletteStyle(_:)`` on the detail column to match your app
  chrome without affecting the sidebar.

## See also

- <doc:GettingStarted>
- ``CommandPaletteView``

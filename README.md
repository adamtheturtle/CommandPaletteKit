# CommandPaletteKit

[![CI](https://github.com/adamtheturtle/CommandPaletteKit/actions/workflows/ci.yml/badge.svg)](https://github.com/adamtheturtle/CommandPaletteKit/actions/workflows/ci.yml)

A dependency-free, Combine-free SwiftUI command palette (⌘K) for macOS and iPad - the
"jump to anything" overlay you get in VS Code, Raycast, or GitHub's `cmd-k`.

- **No dependencies, no Combine.** Pure SwiftUI + a tiny bit of AppKit for one macOS
  keyboard fix. Drops into modern Swift-concurrency projects cleanly.
- **An action palette, not a search box.** Each result carries a `@MainActor` action it
  runs when activated - navigate, run a command, switch context.
- **Built-in fuzzy matching.** A self-contained scorer (exact → prefix → word-boundary
  substring → consecutive-run subsequence) with no index to build. Bring your own scorer
  to add weighting, recency, or pinning.
- **macOS-robust.** Handles the papercuts an iOS-first port misses: AppKit's field editor
  swallowing the arrow keys, highlight/scroll drift as results re-sort, unified
  hover-and-keyboard selection, and a VoiceOver `.isSelected` trait.

## Installation

Swift Package Manager:

```swift
.package(url: "https://github.com/adamtheturtle/CommandPaletteKit", from: "0.1.0")
```

Then add `"CommandPaletteKit"` to your target's dependencies.

## Usage

Present `CommandPaletteView` however you like (a sheet is typical) and hand it a closure
that builds the candidate list:

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

Trigger it with a keyboard shortcut:

```swift
.keyboardShortcut("k", modifiers: .command)
```

## Customization

Everything below has a default that reproduces the shipped look, so the zero-config call
site stays short. Override only what you need.

| Knob | Where | Default |
|---|---|---|
| Candidate list | `candidates:` closure | required |
| Trailing category tag | `PaletteResult.category` | `nil` (hidden) |
| Icon | `PaletteResult.icon` (any `Image`) or `systemImage:` | required |
| Hide until searching | `PaletteResult.showsOnlyWhenSearching` | `false` |
| Match/scoring | `scorer:` | `paletteFuzzyScore` |
| Result cap | `resultLimit:` | `40` |
| Placeholder / empty / no-match copy | `placeholder:` / `emptyMessage:` / `noMatchesMessage:` | English defaults |
| Surface size | `width:` / `height:` | `620 × 460` |
| Activation routing | `onActivate:` | runs `result.action` |
| Colours & metrics | `.commandPaletteStyle(_:)` | accent fill, white-on-accent |

```swift
CommandPaletteView(
    placeholder: "Jump to…",
    resultLimit: 20,
    scorer: myWeightedScorer
) { buildCandidates() }
.commandPaletteStyle(
    CommandPaletteStyle(selectionColor: .blue, rowCornerRadius: 10)
)
```

## Roadmap

Tracked in the originating issue; not yet in this first cut:

- iPad hardware-keyboard navigation (the macOS arrow-key path is already factored out).
- A custom row `@ViewBuilder` for hosts that want a different cell.
- Opt-in `Ctrl-N`/`Ctrl-P` and Page Up/Down navigation.

## License

MIT. See [LICENSE](LICENSE).

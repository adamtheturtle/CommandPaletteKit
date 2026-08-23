//
//  CommandPaletteFooter.swift
//  CommandPaletteKit
//

import SwiftUI

private struct CommandPaletteShowsKeyBindingFooterKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// When `true`, ``CommandPaletteView`` shows a footer describing keyboard shortcuts.
    public var commandPaletteShowsKeyBindingFooter: Bool {
        get { self[CommandPaletteShowsKeyBindingFooterKey.self] }
        set { self[CommandPaletteShowsKeyBindingFooterKey.self] = newValue }
    }
}

extension View {
    /// Shows or hides the palette's built-in key-binding footer.
    public func commandPaletteShowsKeyBindingFooter(_ showsFooter: Bool = true) -> some View {
        environment(\.commandPaletteShowsKeyBindingFooter, showsFooter)
    }
}

struct CommandPaletteKeyBindingFooter: View {
    var body: some View {
        HStack(spacing: 16) {
            footerHint(keys: "↑↓", action: "Navigate")
            footerHint(keys: "Return", action: "Activate")
            #if os(macOS) || os(iOS)
            footerHint(keys: "Esc", action: "Dismiss")
            #endif
            Spacer(minLength: 0)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func footerHint(keys: String, action: String) -> some View {
        HStack(spacing: 4) {
            Text(keys)
                .fontWeight(.semibold)
            Text(action)
        }
    }
}

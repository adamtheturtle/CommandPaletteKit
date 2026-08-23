//
//  PaletteRow.swift
//  CommandPaletteKit
//
//  A single palette row: leading glyph, title and optional subtitle, and a trailing
//  category tag. Highlights when it's the current selection, using the environment's
//  ``CommandPaletteStyle``.
//

import SwiftUI

/// The palette's built-in row: leading glyph, title and optional subtitle, and a trailing
/// category tag, highlighting when selected. This is the default cell ``CommandPaletteView``
/// renders, and is public so a custom `row` builder can reuse or wrap it.
public struct PaletteRow: View {
    let result: PaletteResult
    let isSelected: Bool

    @Environment(\.commandPaletteStyle) private var style
    @Environment(\.commandPaletteQuery) private var query
    @Environment(\.colorScheme) private var colorScheme

    /// Creates a row for `result`, drawing it as selected when `isSelected` is `true`.
    public init(result: PaletteResult, isSelected: Bool) {
        self.result = result
        self.isSelected = isSelected
    }

    public var body: some View {
        HStack(spacing: 12) {
            result.icon
                .frame(width: 22)
                .foregroundStyle(isSelected ? selectedForeground : Color.secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                titleText
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? selectedForeground : Color.primary)
                if let subtitle = result.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? selectedForeground.opacity(0.8) : Color.secondary)
                } else if let shortcut = result.keyboardShortcut, !shortcut.isEmpty {
                    Text(shortcut)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? selectedForeground.opacity(0.8) : Color.secondary)
                }
            }
            Spacer(minLength: 8)
            if let category = result.category, !category.isEmpty {
                Text(category)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? selectedForeground.opacity(0.85) : Color.secondary)
            }
        }
        .padding(.horizontal, style.rowHorizontalPadding)
        .padding(.vertical, style.rowVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: style.rowCornerRadius, style: .continuous)
                .fill(isSelected ? style.selectionColor : Color.clear)
        )
        .accessibilityLabel(Text(result.title))
    }

    @ViewBuilder
    private var titleText: some View {
        if paletteQueryIsSearching(query) {
            paletteHighlightedTitle(result.title, query: query)
        } else {
            Text(result.title)
        }
    }

    private var selectedForeground: Color {
        style.resolvedSelectedForeground(for: colorScheme)
    }
}

//
//  CommandPaletteStyle.swift
//  CommandPaletteKit
//
//  Visual customization for the palette and its rows. Every value defaults to the look
//  the palette ships with, so callers get a sensible appearance with zero configuration
//  and override only what they care about via `.commandPaletteStyle(_:)`.
//

import SwiftUI

/// Colours and metrics for the palette surface and its rows. Apply with
/// ``SwiftUICore/View/commandPaletteStyle(_:)``; unset values fall back to the defaults.
public struct CommandPaletteStyle: Sendable {
    /// Fill behind the selected row.
    public var selectionColor: Color
    /// Foreground colour for text and the icon in the selected row.
    public var selectedForeground: Color
    /// Optional material behind the palette surface. When `nil`, the host background shows through.
    public var backgroundMaterial: Material?
    /// Corner radius of the selected-row highlight.
    public var rowCornerRadius: CGFloat
    /// Horizontal padding inside each row.
    public var rowHorizontalPadding: CGFloat
    /// Vertical padding inside each row.
    public var rowVerticalPadding: CGFloat

    public init(
        selectionColor: Color = .accentColor,
        selectedForeground: Color = .white,
        backgroundMaterial: Material? = nil,
        rowCornerRadius: CGFloat = 7,
        rowHorizontalPadding: CGFloat = 10,
        rowVerticalPadding: CGFloat = 7
    ) {
        self.selectionColor = selectionColor
        self.selectedForeground = selectedForeground
        self.backgroundMaterial = backgroundMaterial
        self.rowCornerRadius = rowCornerRadius
        self.rowHorizontalPadding = rowHorizontalPadding
        self.rowVerticalPadding = rowVerticalPadding
    }

    /// The shipped appearance.
    public static let `default` = CommandPaletteStyle()

    /// Foreground for selected rows that keeps contrast with ``selectionColor`` in light and dark mode.
    func resolvedSelectedForeground(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark, selectionColor == Color.accentColor {
            return .white
        }
        return selectedForeground
    }
}

private struct CommandPaletteStyleKey: EnvironmentKey {
    static let defaultValue = CommandPaletteStyle.default
}

extension EnvironmentValues {
    /// The active palette style. Read by ``CommandPaletteView`` and its rows.
    public var commandPaletteStyle: CommandPaletteStyle {
        get { self[CommandPaletteStyleKey.self] }
        set { self[CommandPaletteStyleKey.self] = newValue }
    }
}

extension View {
    /// Overrides the palette's colours and metrics for this view and its descendants.
    public func commandPaletteStyle(_ style: CommandPaletteStyle) -> some View {
        environment(\.commandPaletteStyle, style)
    }
}

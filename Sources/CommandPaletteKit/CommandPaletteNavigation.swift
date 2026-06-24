//
//  CommandPaletteNavigation.swift
//  CommandPaletteKit
//
//  Opt-in extra keyboard navigation for the palette. Off by default so the palette never
//  intercepts keys a host might want; enable it per view with
//  ``SwiftUI/View/commandPaletteExtendedKeyboardNavigation(_:)``.
//

import SwiftUI

private struct ExtendedKeyNavigationKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// Whether the palette honours the extra power-user navigation keys (`Ctrl-N`/`Ctrl-P`
    /// to move down/up and Page Up/Down to jump a viewport). Read by ``CommandPaletteView``.
    /// Defaults to `false`.
    public var commandPaletteExtendedKeyboardNavigation: Bool {
        get { self[ExtendedKeyNavigationKey.self] }
        set { self[ExtendedKeyNavigationKey.self] = newValue }
    }
}

extension View {
    /// Enables (or disables) the palette's extra keyboard navigation for this view and its
    /// descendants: Emacs-style `Ctrl-N`/`Ctrl-P` to move down/up, and Page Up/Down to move
    /// by a viewport-sized step. Off by default to avoid surprising key interception.
    public func commandPaletteExtendedKeyboardNavigation(_ enabled: Bool = true) -> some View {
        environment(\.commandPaletteExtendedKeyboardNavigation, enabled)
    }
}

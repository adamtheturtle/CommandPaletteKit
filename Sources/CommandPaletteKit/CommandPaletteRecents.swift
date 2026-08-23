//
//  CommandPaletteRecents.swift
//  CommandPaletteKit
//

import SwiftUI

private struct CommandPaletteRecentIDsKey: EnvironmentKey {
    static let defaultValue: [String] = []
}

extension EnvironmentValues {
    /// Recently activated result IDs, newest first.
    public var commandPaletteRecentIDs: [String] {
        get { self[CommandPaletteRecentIDsKey.self] }
        set { self[CommandPaletteRecentIDsKey.self] = newValue }
    }
}

extension View {
    /// Supplies recent command IDs that boost empty-query ranking.
    public func commandPaletteRecentIDs(_ recentIDs: [String]) -> some View {
        environment(\.commandPaletteRecentIDs, recentIDs)
    }

    /// Supplies recent IDs from a ``PaletteRecentCommandStore``.
    public func commandPaletteRecentIDs(_ store: PaletteRecentCommandStore) -> some View {
        environment(\.commandPaletteRecentIDs, store.recentIDs)
    }
}

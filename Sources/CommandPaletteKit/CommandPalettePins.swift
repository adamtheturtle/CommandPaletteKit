//
//  CommandPalettePins.swift
//  CommandPaletteKit
//

import SwiftUI

private struct CommandPalettePinnedIDsKey: EnvironmentKey {
    static let defaultValue: [String] = []
}

extension EnvironmentValues {
    /// Pinned result IDs lifted to the top of rankings. Earlier entries sort first.
    public var commandPalettePinnedIDs: [String] {
        get { self[CommandPalettePinnedIDsKey.self] }
        set { self[CommandPalettePinnedIDsKey.self] = newValue }
    }
}

extension View {
    /// Pins the given result IDs to the top of the palette ranking.
    public func commandPalettePinnedIDs(_ pinnedIDs: [String]) -> some View {
        environment(\.commandPalettePinnedIDs, pinnedIDs)
    }

    /// Pins IDs from a ``PalettePinStore``.
    public func commandPalettePinnedIDs(_ store: PalettePinStore) -> some View {
        environment(\.commandPalettePinnedIDs, store.pinnedIDs)
    }
}

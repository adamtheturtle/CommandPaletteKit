//
//  CommandPaletteQueryEnvironment.swift
//  CommandPaletteKit
//

import SwiftUI

private struct CommandPaletteQueryKey: EnvironmentKey {
    static let defaultValue = ""
}

extension EnvironmentValues {
    /// The active palette search query. Built-in rows read this to highlight fuzzy matches.
    public var commandPaletteQuery: String {
        get { self[CommandPaletteQueryKey.self] }
        set { self[CommandPaletteQueryKey.self] = newValue }
    }
}

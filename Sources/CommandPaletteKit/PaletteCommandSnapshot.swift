//
//  PaletteCommandSnapshot.swift
//  CommandPaletteKit
//

import Foundation

/// A codable, action-free description of a ``PaletteResult`` for persistence, previews,
/// or syncing static command catalogs between processes.
public struct PaletteCommandSnapshot: Codable, Sendable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let category: String?
    public let keyboardShortcut: String?
    public let searchText: String
    public let showsOnlyWhenSearching: Bool

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        category: String? = nil,
        keyboardShortcut: String? = nil,
        searchText: String? = nil,
        showsOnlyWhenSearching: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.keyboardShortcut = keyboardShortcut
        self.searchText = searchText ?? title
        self.showsOnlyWhenSearching = showsOnlyWhenSearching
    }

    /// Captures the display and search fields from a live ``PaletteResult``.
    public init(result: PaletteResult) {
        self.init(
            id: result.id,
            title: result.title,
            subtitle: result.subtitle,
            category: result.category,
            keyboardShortcut: result.keyboardShortcut,
            searchText: result.searchText,
            showsOnlyWhenSearching: result.showsOnlyWhenSearching
        )
    }

    /// Rehydrates a ``PaletteResult`` with a caller-supplied icon and action.
    public func makeResult(
        systemImage: String,
        action: @escaping @MainActor () -> Void
    ) -> PaletteResult {
        PaletteResult(
            id: id,
            title: title,
            subtitle: subtitle,
            category: category,
            systemImage: systemImage,
            keyboardShortcut: keyboardShortcut,
            searchText: searchText,
            showsOnlyWhenSearching: showsOnlyWhenSearching,
            action: action
        )
    }
}

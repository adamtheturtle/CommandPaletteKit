//
//  PalettePinStore.swift
//  CommandPaletteKit
//
//  Pin/favorite IDs that rank above other matches in ``topPaletteResults``.
//

import Foundation

/// Tracks pinned (favorite) palette result IDs.
public struct PalettePinStore: Sendable, Equatable {
    /// Pinned IDs in pin order (earlier pins sort first among pinned matches).
    public private(set) var pinnedIDs: [String]

    public init(pinnedIDs: [String] = []) {
        var seen = Set<String>()
        self.pinnedIDs = pinnedIDs.filter { seen.insert($0).inserted }
    }

    public var pinnedIDSet: Set<String> { Set(pinnedIDs) }

    public mutating func pin(_ id: String) {
        guard !pinnedIDs.contains(id) else { return }

        pinnedIDs.append(id)
    }

    public mutating func unpin(_ id: String) {
        pinnedIDs.removeAll { $0 == id }
    }

    public mutating func toggle(_ id: String) {
        if pinnedIDs.contains(id) {
            unpin(id)
        } else {
            pin(id)
        }
    }

    public func isPinned(_ id: String) -> Bool {
        pinnedIDs.contains(id)
    }
}

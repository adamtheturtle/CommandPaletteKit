//
//  PaletteRecentCommands.swift
//  CommandPaletteKit
//
//  Most-recently-activated command IDs for empty-query ranking boosts.
//

import Foundation

/// Records recently activated palette commands, newest first.
public struct PaletteRecentCommandStore: Sendable, Equatable {
    /// Recent IDs, newest first, capped at ``limit``.
    public private(set) var recentIDs: [String]
    /// Maximum IDs retained.
    public let limit: Int

    public init(limit: Int = 20, recentIDs: [String] = []) {
        self.limit = max(1, limit)
        var seen = Set<String>()
        var ordered: [String] = []
        for id in recentIDs where seen.insert(id).inserted {
            ordered.append(id)
            if ordered.count == self.limit { break }
        }
        self.recentIDs = ordered
    }

    /// Records an activation, moving `id` to the front and dropping overflow.
    public mutating func record(_ id: String) {
        recentIDs.removeAll { $0 == id }
        recentIDs.insert(id, at: 0)
        if recentIDs.count > limit {
            recentIDs.removeLast(recentIDs.count - limit)
        }
    }

    public var recentIDSet: Set<String> { Set(recentIDs) }

    /// Recency rank for scoring: `limit` for newest, down to `1`. Missing IDs return `0`.
    public func recencyScore(for id: String) -> Int {
        guard let index = recentIDs.firstIndex(of: id) else { return 0 }

        return limit - index
    }
}

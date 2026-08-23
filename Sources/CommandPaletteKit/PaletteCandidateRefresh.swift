//
//  PaletteCandidateRefresh.swift
//  CommandPaletteKit
//
//  Incremental updates to an in-memory candidate list without replacing the whole catalog.
//

import Foundation

/// Applies incremental changes to a palette candidate array.
///
/// Use with a `@State` / `Binding` catalog that you pass into ``CommandPaletteView``, or to
/// prepare a list before a sync provider returns it.
public enum PaletteCandidateRefresh {
    /// Returns a new candidate list after removing IDs and upserting results.
    ///
    /// Removals run first. Each upsert replaces the first existing entry with the same `id`,
    /// or appends when the ID is new. Caller order of remaining rows is otherwise preserved.
    public static func applying(
        upserts: [PaletteResult] = [],
        removingIDs: Set<String> = [],
        to candidates: [PaletteResult]
    ) -> [PaletteResult] {
        var next = candidates
        if !removingIDs.isEmpty {
            next.removeAll { removingIDs.contains($0.id) }
        }
        for upsert in upserts {
            if let index = next.firstIndex(where: { $0.id == upsert.id }) {
                next[index] = upsert
            } else {
                next.append(upsert)
            }
        }
        return next
    }
}

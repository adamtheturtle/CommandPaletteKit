//
//  PaletteRecentCommandStoreTests.swift
//  CommandPaletteKit
//

import SwiftUI
import Testing
@testable import CommandPaletteKit

@Suite("Recent commands history")
struct PaletteRecentCommandStoreTests {
    @Test("Recording moves an ID to the front and respects the limit")
    func recording() {
        var store = PaletteRecentCommandStore(limit: 2)
        store.record("a")
        store.record("b")
        store.record("c")
        #expect(store.recentIDs == ["c", "b"])
        store.record("b")
        #expect(store.recentIDs == ["b", "c"])
        #expect(store.recencyScore(for: "b") == 2)
        #expect(store.recencyScore(for: "missing") == 0)
    }

    @Test("Empty-query ranking promotes recent IDs")
    func emptyQueryPromotion() {
        let candidates = [
            PaletteResult(id: "a", title: "Alpha", systemImage: "a.circle") {},
            PaletteResult(id: "b", title: "Beta", systemImage: "b.circle") {},
            PaletteResult(id: "c", title: "Gamma", systemImage: "c.circle") {}
        ]
        let ranked = topPaletteResults(
            candidates: candidates,
            query: "",
            limit: 10,
            scorer: paletteFuzzyScore,
            recentIDs: ["c", "a"]
        )
        #expect(ranked.map(\.id).prefix(2) == ["c", "a"])
    }
}

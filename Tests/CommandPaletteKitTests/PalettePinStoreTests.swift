//
//  PalettePinStoreTests.swift
//  CommandPaletteKit
//

import SwiftUI
import Testing
@testable import CommandPaletteKit

@Suite("Pin and favorite results")
struct PalettePinStoreTests {
    @Test("Pin store toggles and deduplicates")
    func pinStore() {
        var store = PalettePinStore()
        store.pin("a")
        store.pin("b")
        store.pin("a")
        #expect(store.pinnedIDs == ["a", "b"])
        store.toggle("a")
        #expect(store.pinnedIDs == ["b"])
        store.toggle("a")
        #expect(store.pinnedIDs == ["b", "a"])
        #expect(store.isPinned("a"))
    }

    @Test("Pinned IDs rise above higher-scoring unpinned matches")
    func pinnedRiseToTop() {
        let candidates = [
            PaletteResult(id: "low", title: "Alpha", systemImage: "a.circle") {},
            PaletteResult(id: "high", title: "Alpha Extra", systemImage: "b.circle") {},
            PaletteResult(id: "pin", title: "Zed", systemImage: "c.circle") {}
        ]
        let unpinned = topPaletteResults(
            candidates: candidates,
            query: "a",
            limit: 10,
            scorer: paletteFuzzyScore
        )
        #expect(unpinned.first?.id == "low" || unpinned.first?.id == "high")

        let pinned = topPaletteResults(
            candidates: candidates,
            query: "",
            limit: 10,
            scorer: paletteFuzzyScore,
            pinnedIDs: ["pin", "high"]
        )
        #expect(pinned.map(\.id).prefix(2) == ["pin", "high"])
    }
}

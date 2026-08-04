//
//  PaletteTopResultsTests.swift
//  CommandPaletteKit
//

import SwiftUI
import Testing

@testable import CommandPaletteKit

@Suite("Bounded palette results")
struct PaletteTopResultsTests {
    @Test("Large catalogs retain only the visible result limit")
    func largeCatalogUsesBoundedStorage() {
        let limit = 25
        var heap = BoundedPaletteResultHeap(limit: limit)

        for index in 0 ..< 50_000 {
            heap.insert(
                ScoredPaletteResult(
                    result: PaletteResult(
                        id: String(index),
                        title: String(index),
                        icon: Image(systemName: "circle")
                    ) {},
                    score: index,
                    sourceIndex: index
                )
            )
        }

        #expect(heap.retainedCount == limit)
        #expect(heap.sortedResults().map(\.id) == (49_975 ..< 50_000).reversed().map(String.init))
    }

    @Test("Equal scores preserve caller order")
    func tiesAreStable() {
        let candidates = (0 ..< 10).map { index in
            PaletteResult(
                id: String(index),
                title: String(index),
                icon: Image(systemName: "circle")
            ) {}
        }

        let results = topPaletteResults(candidates: candidates, query: "", limit: 4) { _, _ in 1 }

        #expect(results.map(\.id) == ["0", "1", "2", "3"])
    }

    @Test("A zero limit does not score the catalog")
    func zeroLimitSkipsScoring() {
        let candidate = PaletteResult(id: "one", title: "One", icon: Image(systemName: "circle")) {}

        let results = topPaletteResults(candidates: [candidate], query: "", limit: 0) { _, _ in
            Issue.record("The scorer should not run when no results can be displayed")
            return 1
        }

        #expect(results.isEmpty)
    }
}

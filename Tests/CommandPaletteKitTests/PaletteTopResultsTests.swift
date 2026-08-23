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

    @Test("Ten thousand candidates rank within a practical bound")
    func tenThousandCandidates() {
        let candidates = (0 ..< 10_000).map { index in
            PaletteResult(
                id: String(index),
                title: "Item \(index)",
                systemImage: "circle",
                searchText: "Item \(index)"
            ) {}
        }

        let clock = ContinuousClock()
        let start = clock.now
        let results = topPaletteResults(
            candidates: candidates,
            query: "Item",
            limit: 40,
            scorer: paletteFuzzyScore
        )
        let elapsed = clock.now - start

        #expect(results.count == 40)
        #expect(elapsed < .seconds(2))
    }

    @Test("Subtitle and category text contribute to ranking")
    func scoresSubtitleAndCategory() {
        let bySubtitle = PaletteResult(
            id: "sub",
            title: "Alpha",
            subtitle: "Open preferences",
            systemImage: "gear",
            searchText: "Alpha"
        ) {}
        let byCategory = PaletteResult(
            id: "cat",
            title: "Beta",
            category: "Navigate",
            systemImage: "arrow.right",
            searchText: "Beta"
        ) {}
        let unrelated = PaletteResult(
            id: "other",
            title: "Gamma",
            systemImage: "circle",
            searchText: "Gamma"
        ) {}

        let subtitleHits = topPaletteResults(
            candidates: [bySubtitle, unrelated],
            query: "preferences",
            limit: 10,
            scorer: paletteFuzzyScore
        )
        #expect(subtitleHits.map(\.id) == ["sub"])

        let categoryHits = topPaletteResults(
            candidates: [byCategory, unrelated],
            query: "navigate",
            limit: 10,
            scorer: paletteFuzzyScore
        )
        #expect(categoryHits.map(\.id) == ["cat"])
    }

    @Test("Fold-empty queries do not surface showsOnlyWhenSearching rows")
    func foldEmptyDoesNotCountAsSearching() {
        let hidden = PaletteResult(
            id: "hidden",
            title: "Hidden",
            systemImage: "eye.slash",
            showsOnlyWhenSearching: true
        ) {}
        let visible = PaletteResult(
            id: "visible",
            title: "Visible",
            systemImage: "eye"
        ) {}

        let results = topPaletteResults(
            candidates: [hidden, visible],
            query: "\u{0301}",
            limit: 10,
            scorer: paletteFuzzyScore
        )
        #expect(results.map(\.id) == ["visible"])
    }

    @Test("A scorer nil on every field excludes the candidate")
    func nilOnAllFieldsExcludes() {
        let hidden = PaletteResult(
            id: "hidden",
            title: "Hidden",
            subtitle: "secret",
            systemImage: "eye.slash",
            searchText: "Hidden"
        ) {}
        let visible = PaletteResult(
            id: "visible",
            title: "Visible",
            systemImage: "eye",
            searchText: "Visible"
        ) {}

        let results = topPaletteResults(
            candidates: [hidden, visible],
            query: "v",
            limit: 10
        ) { _, text in
            text.localizedCaseInsensitiveContains("hidden") || text == "secret" ? nil : 1
        }

        #expect(results.map(\.id) == ["visible"])
    }

    @Test("Nil on searchText alone does not block a subtitle match")
    func nilSearchTextAllowsSubtitleMatch() {
        let candidate = PaletteResult(
            id: "sub",
            title: "Alpha",
            subtitle: "Open preferences",
            systemImage: "gear",
            searchText: "Alpha"
        ) {}

        let results = topPaletteResults(
            candidates: [candidate],
            query: "preferences",
            limit: 10
        ) { query, text in
            // Simulate a searchText-only miss while subtitle still matches.
            text == "Alpha" ? nil : paletteFuzzyScore(query, text)
        }

        #expect(results.map(\.id) == ["sub"])
    }
}

private final class ChangingScorer: @unchecked Sendable {
    private var invocation = 0
    private let lock = NSLock()

    func score(_: String, _ text: String) -> Int? {
        lock.lock()
        defer { lock.unlock() }

        let rankingPass = invocation / 2
        invocation += 1
        return rankingPass.isMultiple(of: 2) == (text == "Alpha") ? 10 : 1
    }

    var invocationCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return invocation
    }
}

@Suite("Materialized palette result snapshot")
struct PaletteResultSnapshotTests {
    @Test("Display and activation share one stateful-scorer ranking")
    func statefulScorerIsEvaluatedOncePerSnapshot() {
        let candidates = [
            PaletteResult(id: "alpha", title: "Alpha", systemImage: "a.circle") {},
            PaletteResult(id: "beta", title: "Beta", systemImage: "b.circle") {}
        ]
        let scorer = ChangingScorer()
        var snapshot = PaletteResultSnapshot()

        snapshot.refresh(candidates: candidates, query: "", limit: 2, scorer: scorer.score)
        let displayedID = snapshot.results.first?.id
        let activatedID = snapshot.result(at: 0)?.id

        #expect(displayedID == "alpha")
        #expect(activatedID == displayedID)
        #expect(scorer.invocationCount == candidates.count)
    }
}

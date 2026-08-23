//
//  PaletteTopResults.swift
//  CommandPaletteKit
//

import Foundation

struct ScoredPaletteResult {
    let result: PaletteResult
    let score: Int
    let sourceIndex: Int
}

/// Retains only the best `limit` results while candidates are scored.
///
/// The root is the worst retained entry, so a better candidate replaces it in O(log N).
/// Final sorting touches at most `limit` entries instead of the complete candidate catalog.
struct BoundedPaletteResultHeap {
    let limit: Int
    private(set) var entries: [ScoredPaletteResult] = []

    var retainedCount: Int { entries.count }

    mutating func insert(_ entry: ScoredPaletteResult) {
        guard limit > 0 else { return }

        if entries.count < limit {
            entries.append(entry)
            siftUp(from: entries.count - 1)
        } else if let worst = entries.first, isBetter(entry, than: worst) {
            entries[0] = entry
            siftDown(from: 0)
        }
    }

    func sortedResults() -> [PaletteResult] {
        entries.sorted(by: isBetter).map(\.result)
    }

    private mutating func siftUp(from start: Int) {
        var child = start
        while child > 0 {
            let parent = (child - 1) / 2
            guard isWorse(entries[child], than: entries[parent]) else { return }

            entries.swapAt(child, parent)
            child = parent
        }
    }

    private mutating func siftDown(from start: Int) {
        var parent = start
        while true {
            let left = parent * 2 + 1
            guard left < entries.count else { return }

            let right = left + 1
            let worseChild = right < entries.count && isWorse(entries[right], than: entries[left])
                ? right
                : left
            guard isWorse(entries[worseChild], than: entries[parent]) else { return }

            entries.swapAt(parent, worseChild)
            parent = worseChild
        }
    }

    private func isBetter(_ lhs: ScoredPaletteResult, than rhs: ScoredPaletteResult) -> Bool {
        lhs.score != rhs.score ? lhs.score > rhs.score : lhs.sourceIndex < rhs.sourceIndex
    }

    private func isWorse(_ lhs: ScoredPaletteResult, than rhs: ScoredPaletteResult) -> Bool {
        isBetter(rhs, than: lhs)
    }
}

/// Returns the top-scoring palette results for a query, applying deduplication and
/// ``PaletteResult/showsOnlyWhenSearching`` filtering.
///
/// When `pinnedIDs` is non-empty, matching pinned results are lifted to the front of the
/// ranking in pin order while unpinned matches keep their score order afterward.
public func topPaletteResults(
    candidates: [PaletteResult],
    query: String,
    limit: Int,
    scorer: PaletteScorer,
    pinnedIDs: [String] = []
) -> [PaletteResult] {
    guard limit > 0 else { return [] }

    let searching = paletteQueryIsSearching(query)
    var heap = BoundedPaletteResultHeap(limit: limit)
    for (sourceIndex, result) in deduplicatedPaletteResults(candidates).enumerated() {
        guard searching || !result.showsOnlyWhenSearching else { continue }
        guard let score = scorePaletteResult(result, query: query, scorer: scorer) else { continue }

        heap.insert(ScoredPaletteResult(result: result, score: score, sourceIndex: sourceIndex))
    }
    return promotePinnedResults(heap.sortedResults(), pinnedIDs: pinnedIDs)
}

/// Lifts pinned results to the front of an already-ranked list, preserving pin order and
/// the relative order of unpinned rows.
public func promotePinnedResults(
    _ results: [PaletteResult],
    pinnedIDs: [String]
) -> [PaletteResult] {
    guard !pinnedIDs.isEmpty else { return results }

    var pinOrder: [String: Int] = [:]
    for (index, id) in pinnedIDs.enumerated() where pinOrder[id] == nil {
        pinOrder[id] = index
    }
    let pinned = results
        .filter { pinOrder[$0.id] != nil }
        .sorted { (pinOrder[$0.id] ?? .max) < (pinOrder[$1.id] ?? .max) }
    let rest = results.filter { pinOrder[$0.id] == nil }
    return pinned + rest
}

/// Scores a candidate against the query using ``PaletteResult/searchText``, falling back to
/// the best match among title, subtitle, and category so hosts need not fold those fields
/// into `searchText` manually.
///
/// A `nil` from the scorer means “no match for this field”. The candidate is excluded only
/// when every scored field returns `nil`. To drop a candidate unconditionally, filter it
/// from the provider’s list (the scorer no longer treats a single-field `nil` as exclusion).
func scorePaletteResult(
    _ result: PaletteResult,
    query: String,
    scorer: PaletteScorer
) -> Int? {
    var best: Int?
    var seen = Set<String>()
    var fields = [result.searchText, result.title]
    if let subtitle = result.subtitle, !subtitle.isEmpty { fields.append(subtitle) }
    if let category = result.category, !category.isEmpty { fields.append(category) }

    for field in fields where seen.insert(field).inserted {
        guard let score = scorer(query, field) else { continue }

        if let current = best {
            best = max(current, score)
        } else {
            best = score
        }
    }
    return best
}

/// One materialized ranking shared by rendering, navigation, scrolling, and activation.
///
/// Host tests can build a snapshot directly to assert ranking behaviour without presenting
/// ``CommandPaletteView``.
public struct PaletteResultSnapshot {
    public private(set) var results: [PaletteResult] = []

    public init() {}

    public mutating func refresh(
        candidates: [PaletteResult],
        query: String,
        limit: Int,
        scorer: PaletteScorer,
        pinnedIDs: [String] = []
    ) {
        results = topPaletteResults(
            candidates: candidates,
            query: query,
            limit: limit,
            scorer: scorer,
            pinnedIDs: pinnedIDs
        )
    }

    public func result(at index: Int) -> PaletteResult? {
        results.indices.contains(index) ? results[index] : nil
    }
}

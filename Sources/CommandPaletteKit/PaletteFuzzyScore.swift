//
//  PaletteFuzzyScore.swift
//  CommandPaletteKit
//
//  A self-contained fuzzy scorer - no dependency, no index. Higher is better; `nil`
//  means no match. An empty query matches everything at a neutral score so the full
//  candidate list shows. Exact and prefix matches rank highest, then substring (with a
//  word-boundary bonus), then a fuzzy subsequence match that rewards consecutive runs.
//

import Foundation

/// Scores how well `query` matches `text`. Returns `nil` when there is no match, `0` for
/// an empty query (so an unfiltered list shows), and a positive score otherwise where a
/// larger value is a better match.
///
/// Matching folds case and diacritics, and compares Unicode-normalized (NFC) forms so
/// composed and decomposed characters score the same.
///
/// This is the default scorer used by ``CommandPaletteView``; pass your own
/// ``PaletteScorer`` to the view to add weighting, recency, or pinning.
public func paletteFuzzyScore(_ query: String, _ text: String) -> Int? {
    let trimmed = normalizedPaletteQuery(query)
    guard !trimmed.isEmpty else { return 0 }

    let haystack = foldForPaletteSearch(text)
    let needle = foldForPaletteSearch(trimmed)
    // Folding can erase a query that was only combining marks (or other ignorable
    // characters). Treat that like an empty query so we don't prefix-match everything
    // and surface ``PaletteResult/showsOnlyWhenSearching`` rows.
    guard paletteQueryIsSearching(trimmed) else { return 0 }

    if haystack == needle { return 1000 }
    if haystack.hasPrefix(needle) { return 850 }

    if let range = haystack.range(of: needle) {
        let start = range.lowerBound
        let atWordStart = start == haystack.startIndex
            || !haystack[haystack.index(before: start)].isLetter
            && !haystack[haystack.index(before: start)].isNumber
        let offset = haystack.distance(from: haystack.startIndex, to: start)
        return (atWordStart ? 650 : 450) - min(offset, 100)
    }

    // Subsequence match: every character of the needle appears in order. Consecutive
    // matches score progressively higher so "npd" prefers "NewPaD" over scattered hits.
    var score = 0
    var consecutive = 0
    var index = haystack.startIndex
    for character in needle {
        var matched = false
        while index < haystack.endIndex {
            let current = haystack[index]
            index = haystack.index(after: index)
            if current == character {
                matched = true
                consecutive += 1
                score += 8 + consecutive
                break
            }
            consecutive = 0
        }
        if !matched { return nil }
    }
    return score
}

func normalizedPaletteQuery(_ query: String) -> String {
    query.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Whether the query should count as an active search after trim and diacritic folding.
///
/// Combining-mark-only queries trim to non-empty text but fold to empty; treat those as
/// not searching so ``PaletteResult/showsOnlyWhenSearching`` rows stay hidden.
func paletteQueryIsSearching(_ query: String) -> Bool {
    !paletteQueryFoldedText(normalizedPaletteQuery(query)).isEmpty
}

/// NFC-normalizes and folds case and diacritics for palette search comparisons.
func foldForPaletteSearch(_ string: String) -> String {
    let nfc = string.precomposedStringWithCanonicalMapping
    return nfc.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
}

/// Folds a query and strips orphan combining marks so accent-only input counts as empty.
///
/// Used only for ``paletteQueryIsSearching(_:)``; general haystack/needle folding keeps
/// script marks such as Japanese dakuten and Indic matras intact.
func paletteQueryFoldedText(_ query: String) -> String {
    let folded = foldForPaletteSearch(query)
    let mutable = NSMutableString(string: folded)
    CFStringTransform(mutable, nil, kCFStringTransformStripCombiningMarks, false)
    return mutable as String
}

/// A function that scores a `query` against one candidate text field (search text, title,
/// subtitle, or category). Return `nil` when that field does not match; the palette keeps
/// the best non-`nil` score among fields and excludes the candidate when every field
/// returns `nil`.
///
/// To hide a candidate regardless of the query, filter it out of the provider’s list rather
/// than returning `nil` from a single field — a miss on ``PaletteResult/searchText`` no
/// longer excludes a row that still matches on subtitle or category.
///
/// Prefer a pure function: the palette may invoke the scorer many times per keystroke and
/// materializes one ranking snapshot per query/candidate refresh. Side effects or
/// non-deterministic scores can change ordering between refreshes; see the Customization
/// article for guardrails when a scorer must carry recency or pinning state.
public typealias PaletteScorer = @Sendable (_ query: String, _ text: String) -> Int?

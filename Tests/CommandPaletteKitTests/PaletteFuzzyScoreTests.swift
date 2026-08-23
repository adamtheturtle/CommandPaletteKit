//
//  PaletteFuzzyScoreTests.swift
//  CommandPaletteKit
//

import Testing
@testable import CommandPaletteKit

@Suite("paletteFuzzyScore")
struct PaletteFuzzyScoreTests {
    @Test("Empty query matches everything at a neutral score")
    func emptyQueryMatchesAll() {
        #expect(paletteFuzzyScore("", "Anything") == 0)
        #expect(paletteFuzzyScore("   ", "Anything") == 0)
        #expect(paletteFuzzyScore("\r\n", "Anything") == 0)
        #expect(paletteFuzzyScore(" \n\t\r ", "Anything") == 0)
        #expect(normalizedPaletteQuery("\r\n").isEmpty)
        #expect(normalizedPaletteQuery(" \ncommand\r ") == "command")
    }

    @Test("A query that folds to empty is treated as an empty search")
    func foldEmptyQueryIsNeutral() {
        // Combining acute accent alone trims to non-empty but folds away.
        let combiningOnly = "\u{0301}"
        #expect(!normalizedPaletteQuery(combiningOnly).isEmpty)
        #expect(paletteQueryFoldedText(combiningOnly).isEmpty)
        #expect(!paletteQueryIsSearching(combiningOnly))
        #expect(paletteFuzzyScore(combiningOnly, "Anything") == 0)
        #expect(paletteFuzzyScore(combiningOnly, "Café") == 0)
    }

    @Test("No common subsequence is no match")
    func noMatch() {
        #expect(paletteFuzzyScore("xyz", "New Pad") == nil)
    }

    @Test("Exact match outranks prefix outranks substring")
    func rankingOrder() throws {
        let exact = try #require(paletteFuzzyScore("new pad", "New Pad"))
        let prefix = try #require(paletteFuzzyScore("new", "New Pad"))
        let substring = try #require(paletteFuzzyScore("pad", "New Pad"))
        #expect(exact > prefix)
        #expect(prefix > substring)
    }

    @Test("Word-boundary substring beats a mid-word substring")
    func wordBoundaryBonus() throws {
        let boundary = try #require(paletteFuzzyScore("pad", "New Pad"))
        let midWord = try #require(paletteFuzzyScore("ewp", "Newpad Thing"))
        #expect(boundary > midWord)
    }

    @Test("Consecutive subsequence runs outscore scattered ones")
    func consecutiveRunsWin() throws {
        // "comm" matches four adjacent characters in "command" but is broken up in
        // "chromium", so the consecutive-run bonus should rank "command" higher.
        let consecutive = try #require(paletteFuzzyScore("comm", "command"))
        let scattered = try #require(paletteFuzzyScore("comm", "chromium"))
        #expect(consecutive > scattered)
    }

    @Test("Matching is case-insensitive")
    func caseInsensitive() {
        #expect(paletteFuzzyScore("NEW", "new pad") != nil)
    }

    @Test("Matching ignores diacritics")
    func diacriticInsensitive() {
        #expect(paletteFuzzyScore("cafe", "Café") != nil)
        #expect(paletteFuzzyScore("naive", "naïve") != nil)
        #expect(paletteFuzzyScore("Árpád", "arpad") != nil)
    }

    @Test("Folding preserves meaningful script marks outside Latin diacritics")
    func scriptMarksPreserved() {
        // Dakuten/handakuten must not collapse to their base kana.
        #expect(foldForPaletteSearch("が") != foldForPaletteSearch("か"))
        #expect(foldForPaletteSearch("パ") != foldForPaletteSearch("ハ"))
        #expect(paletteFuzzyScore("が", "か") == nil)
        #expect(paletteFuzzyScore("パ", "ハ") == nil)
    }

    @Test("NFC and NFD forms of the same text score equally")
    func unicodeNormalization() throws {
        let composed = "é"
        let decomposed = "e\u{0301}"
        let composedScore = try #require(paletteFuzzyScore(composed, "Café"))
        let decomposedScore = try #require(paletteFuzzyScore(decomposed, "Cafe\u{0301}"))
        #expect(composedScore == decomposedScore)
        #expect(foldForPaletteSearch(composed) == foldForPaletteSearch(decomposed))
    }
}

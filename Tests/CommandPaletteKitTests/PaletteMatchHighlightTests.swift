//
//  PaletteMatchHighlightTests.swift
//  CommandPaletteKit
//

import Testing
@testable import CommandPaletteKit

@Suite("Fuzzy match highlighting")
struct PaletteMatchHighlightTests {
    @Test("Empty query highlights nothing")
    func emptyQuery() {
        #expect(paletteFuzzyMatchCharacterOffsets(query: "", in: "New Pad").isEmpty)
        #expect(paletteFuzzyMatchCharacterOffsets(query: "   ", in: "New Pad").isEmpty)
    }

    @Test("Exact and subsequence queries mark the matched characters")
    func marksMatches() {
        let exact = paletteFuzzyMatchCharacterOffsets(query: "pad", in: "New Pad")
        #expect(exact.contains(4))
        #expect(exact.contains(5))
        #expect(exact.contains(6))
        #expect(!exact.contains(0))

        let fuzzy = paletteFuzzyMatchCharacterOffsets(query: "npd", in: "New Pad")
        #expect(fuzzy.contains(0))
        #expect(fuzzy.contains(4))
        #expect(fuzzy.contains(6))
    }

    @Test("Non-matching query highlights nothing")
    func noMatch() {
        #expect(paletteFuzzyMatchCharacterOffsets(query: "xyz", in: "New Pad").isEmpty)
    }

    @Test("Matching is case and diacritic insensitive")
    func folding() {
        let offsets = paletteFuzzyMatchCharacterOffsets(query: "cafe", in: "Café")
        #expect(!offsets.isEmpty)
        #expect(offsets.count == 4)
    }
}

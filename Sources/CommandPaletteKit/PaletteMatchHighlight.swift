//
//  PaletteMatchHighlight.swift
//  CommandPaletteKit
//
//  Maps a fuzzy query onto title characters so row titles can bold the matched glyphs.
//

import Foundation
import SwiftUI

/// Character offsets into `text` that participate in a fuzzy match of `query`.
///
/// Offsets index `text`'s `String.Index` positions via `Array(text)`. An empty or
/// non-matching query yields an empty set.
public func paletteFuzzyMatchCharacterOffsets(query: String, in text: String) -> IndexSet {
    let trimmed = normalizedPaletteQuery(query)
    guard !trimmed.isEmpty else { return [] }

    let needle = Array(foldForPaletteSearch(trimmed))
    guard !needle.isEmpty else { return [] }

    let characters = Array(text)
    var foldedHaystack: [Character] = []
    var foldedToOriginal: [Int] = []
    for (originalIndex, character) in characters.enumerated() {
        for folded in foldForPaletteSearch(String(character)) {
            foldedHaystack.append(folded)
            foldedToOriginal.append(originalIndex)
        }
    }

    guard !foldedHaystack.isEmpty else { return [] }

    var matchedOriginal = IndexSet()
    var searchStart = 0
    for needleCharacter in needle {
        var matched = false
        var index = searchStart
        while index < foldedHaystack.count {
            if foldedHaystack[index] == needleCharacter {
                matchedOriginal.insert(foldedToOriginal[index])
                searchStart = index + 1
                matched = true
                break
            }
            index += 1
        }
        if !matched { return [] }
    }
    return matchedOriginal
}

/// Builds a title `Text` with fuzzy-matched characters emphasized.
public func paletteHighlightedTitle(
    _ title: String,
    query: String
) -> Text {
    let offsets = paletteFuzzyMatchCharacterOffsets(query: query, in: title)
    guard !offsets.isEmpty else { return Text(title) }

    var combined = Text("")
    for (index, character) in Array(title).enumerated() {
        let piece = Text(String(character))
        // Text concatenates with `+`; `+=` is not available for `Text`.
        // swiftlint:disable:next shorthand_operator
        combined = combined + (offsets.contains(index) ? piece.bold() : piece)
    }
    return combined
}

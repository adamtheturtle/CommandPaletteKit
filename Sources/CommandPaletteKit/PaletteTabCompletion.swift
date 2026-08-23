//
//  PaletteTabCompletion.swift
//  CommandPaletteKit
//
//  Tab-completes the search query from visible result titles.
//

import Foundation

/// Returns a completed query string for Tab in the search field.
///
/// Prefers the selected result's title when it still matches the query; otherwise the
/// longest shared prefix of all visible titles that fuzzy-match. Returns `nil` when
/// completion would not change the query.
public func paletteTabCompletion(
    query: String,
    visibleTitles: [String],
    selectedTitle: String?
) -> String? {
    let trimmed = normalizedPaletteQuery(query)
    let titles = visibleTitles.filter { !$0.isEmpty }
    guard !titles.isEmpty else { return nil }

    if let selectedTitle,
       !selectedTitle.isEmpty,
       paletteFuzzyScore(trimmed, selectedTitle) != nil {
        return completionIfChanged(from: trimmed, to: selectedTitle)
    }

    let matching = titles.filter { paletteFuzzyScore(trimmed, $0) != nil }
    guard !matching.isEmpty else { return nil }

    let shared = sharedPrefix(of: matching)
    return completionIfChanged(from: trimmed, to: shared)
}

private func completionIfChanged(from query: String, to candidate: String) -> String? {
    let completed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !completed.isEmpty, foldForPaletteSearch(completed) != foldForPaletteSearch(query) else {
        return nil
    }
    return completed
}

private func sharedPrefix(of strings: [String]) -> String {
    guard var prefix = strings.first.map(Array.init) else { return "" }

    for string in strings.dropFirst() {
        let characters = Array(string)
        var index = 0
        while index < prefix.count,
              index < characters.count,
              foldForPaletteSearch(String(prefix[index]))
              == foldForPaletteSearch(String(characters[index])) {
            index += 1
        }
        prefix = Array(prefix.prefix(index))
        if prefix.isEmpty { return "" }
    }
    return String(prefix)
}

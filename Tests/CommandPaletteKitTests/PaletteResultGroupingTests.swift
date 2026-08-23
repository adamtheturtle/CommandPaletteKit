//
//  PaletteResultGroupingTests.swift
//  CommandPaletteKit
//

import SwiftUI
import Testing
@testable import CommandPaletteKit

@Suite("Group results by category")
struct PaletteResultGroupingTests {
    @Test("Groups preserve first-seen category order and within-group ranking")
    func groupingOrder() {
        let results = [
            PaletteResult(id: "1", title: "A", category: "Nav", systemImage: "1.circle") {},
            PaletteResult(id: "2", title: "B", category: "Edit", systemImage: "2.circle") {},
            PaletteResult(id: "3", title: "C", category: "Nav", systemImage: "3.circle") {},
            PaletteResult(id: "4", title: "D", systemImage: "4.circle") {}
        ]
        let groups = groupedPaletteResults(results)
        #expect(groups.map(\.category) == ["Nav", "Edit", nil])
        #expect(groups[0].results.map(\.id) == ["1", "3"])
        #expect(groups[1].results.map(\.id) == ["2"])
        #expect(groups[2].results.map(\.id) == ["4"])
    }

    @Test("Empty input yields no groups")
    func empty() {
        #expect(groupedPaletteResults([]).isEmpty)
    }
}

//
//  SelectionScrollIntegrationTests.swift
//  CommandPaletteKit
//
//  Integration coverage for selection movement and scroll-target identity without a
//  full UI host: ranking, clamping, and scroll ids must stay aligned.
//

import SwiftUI
import Testing
@testable import CommandPaletteKit

@Suite("Selection and scroll integration")
struct SelectionScrollIntegrationTests {
    private func candidates() -> [PaletteResult] {
        (0 ..< 12).map { index in
            PaletteResult(
                id: "item-\(index)",
                title: "Item \(index)",
                systemImage: "circle"
            ) {}
        }
    }

    @Test("Moving selection tracks stable result ids used as scroll targets")
    func selectionTracksScrollIdentity() {
        var snapshot = PaletteResultSnapshot()
        snapshot.refresh(
            candidates: candidates(),
            query: "",
            limit: 40,
            scorer: paletteFuzzyScore
        )
        let results = snapshot.results
        #expect(results.count == 12)

        var selectedIndex = 0
        selectedIndex = clampedSelectionIndex(current: selectedIndex, delta: 1, count: results.count)
        #expect(results[selectedIndex].id == "item-1")

        selectedIndex = clampedSelectionIndex(current: selectedIndex, delta: 3, count: results.count)
        #expect(results[selectedIndex].id == "item-4")

        // Scroll targets in CommandPaletteView use result.id, not the positional index.
        let scrollTarget = results[selectedIndex].id
        #expect(scrollTarget == "item-4")
        #expect(results.firstIndex(where: { $0.id == scrollTarget }) == selectedIndex)
    }

    @Test("Query refresh keeps selection index within the new result window")
    func queryRefreshClampsSelection() {
        var snapshot = PaletteResultSnapshot()
        snapshot.refresh(
            candidates: candidates(),
            query: "",
            limit: 40,
            scorer: paletteFuzzyScore
        )
        var selectedIndex = 8
        #expect(snapshot.result(at: selectedIndex)?.id == "item-8")

        snapshot.refresh(
            candidates: candidates(),
            query: "Item 1",
            limit: 40,
            scorer: paletteFuzzyScore
        )
        selectedIndex = min(selectedIndex, max(snapshot.results.count - 1, 0))
        #expect(snapshot.results.indices.contains(selectedIndex))
        #expect(snapshot.result(at: selectedIndex) != nil)
    }

    @Test("Page navigation step aligns with measured row heights for scrolling")
    func pageStepUsesMeasuredHeights() {
        let step = pageNavigationStep(for: 460, rowHeight: 36)
        #expect(step >= 1)

        let tallStep = pageNavigationStep(for: 460, rowHeight: 72)
        #expect(tallStep >= 1)
        #expect(tallStep <= step)
    }
}

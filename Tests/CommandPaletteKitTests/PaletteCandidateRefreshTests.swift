//
//  PaletteCandidateRefreshTests.swift
//  CommandPaletteKit
//

import SwiftUI
import Testing
@testable import CommandPaletteKit

@Suite("Incremental candidate refresh")
struct PaletteCandidateRefreshTests {
    private func result(id: String, title: String) -> PaletteResult {
        PaletteResult(id: id, title: title, systemImage: "circle") {}
    }

    @Test("Upserts replace matching IDs and append new ones")
    func upserts() {
        let initial = [result(id: "a", title: "Alpha"), result(id: "b", title: "Beta")]
        let refreshed = PaletteCandidateRefresh.applying(
            upserts: [result(id: "b", title: "Beta 2"), result(id: "c", title: "Gamma")],
            to: initial
        )
        #expect(refreshed.map(\.id) == ["a", "b", "c"])
        #expect(refreshed.map(\.title) == ["Alpha", "Beta 2", "Gamma"])
    }

    @Test("Removals drop matching IDs before upserts apply")
    func removalsThenUpserts() {
        let initial = [
            result(id: "a", title: "Alpha"),
            result(id: "b", title: "Beta"),
            result(id: "c", title: "Gamma")
        ]
        let refreshed = PaletteCandidateRefresh.applying(
            upserts: [result(id: "b", title: "Beta again")],
            removingIDs: ["a", "c"],
            to: initial
        )
        #expect(refreshed.map(\.id) == ["b"])
        #expect(refreshed.map(\.title) == ["Beta again"])
    }

    @Test("Empty refresh leaves the catalog unchanged")
    func emptyRefresh() {
        let initial = [result(id: "a", title: "Alpha")]
        let refreshed = PaletteCandidateRefresh.applying(to: initial)
        #expect(refreshed.map(\.id) == ["a"])
    }

    @Test("Binding-backed initializers resolve")
    @MainActor
    func bindingInitializers() {
        let binding = Binding.constant([result(id: "a", title: "Alpha")])
        _ = CommandPaletteView(candidates: binding)
        _ = CommandPaletteView(
            candidates: binding,
            row: { result, isSelected in Text(result.title).bold(isSelected) }
        )
    }
}

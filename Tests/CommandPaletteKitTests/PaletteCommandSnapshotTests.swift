//
//  PaletteCommandSnapshotTests.swift
//  CommandPaletteKit
//

import Foundation
import Testing

@testable import CommandPaletteKit

@Suite("PaletteCommandSnapshot")
struct PaletteCommandSnapshotTests {
    @Test("Round-trips through JSON")
    func jsonRoundTrip() throws {
        let snapshot = PaletteCommandSnapshot(
            id: "command.new",
            title: "New Document",
            subtitle: "Create a document",
            category: "Command",
            keyboardShortcut: "⌘N",
            searchText: "new create",
            showsOnlyWhenSearching: true
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(PaletteCommandSnapshot.self, from: data)
        #expect(decoded == snapshot)
    }

    @Test("Captures fields from a PaletteResult")
    func fromResult() {
        let result = PaletteResult(
            id: "nav.settings",
            title: "Settings",
            category: "Navigate",
            systemImage: "gearshape",
            searchText: "preferences"
        ) {}
        let snapshot = PaletteCommandSnapshot(result: result)
        #expect(snapshot.id == "nav.settings")
        #expect(snapshot.title == "Settings")
        #expect(snapshot.category == "Navigate")
        #expect(snapshot.searchText == "preferences")
    }

    @Test("Rehydrates a PaletteResult with a supplied action")
    @MainActor
    func makeResult() {
        let snapshot = PaletteCommandSnapshot(id: "demo", title: "Demo", category: "Sample")
        var activated = false
        let result = snapshot.makeResult(systemImage: "star") { activated = true }
        #expect(result.id == "demo")
        result.action()
        #expect(activated)
    }
}

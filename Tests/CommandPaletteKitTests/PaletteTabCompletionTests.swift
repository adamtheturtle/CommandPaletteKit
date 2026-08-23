//
//  PaletteTabCompletionTests.swift
//  CommandPaletteKit
//

import Testing
@testable import CommandPaletteKit

@Suite("Tab completion")
struct PaletteTabCompletionTests {
    @Test("Selected title wins when it still matches")
    func selectedTitle() {
        let completed = paletteTabCompletion(
            query: "ne",
            visibleTitles: ["New Document", "New Folder", "Settings"],
            selectedTitle: "New Document"
        )
        #expect(completed == "New Document")
    }

    @Test("Shared prefix is used when no selected title is preferred")
    func sharedPrefix() {
        let completed = paletteTabCompletion(
            query: "ne",
            visibleTitles: ["New Document", "New Folder"],
            selectedTitle: nil
        )
        #expect(completed == "New")
    }

    @Test("Nil when completion would not change the query")
    func noChange() {
        #expect(
            paletteTabCompletion(
                query: "New Document",
                visibleTitles: ["New Document"],
                selectedTitle: "New Document"
            ) == nil
        )
    }

    @Test("Nil when nothing matches")
    func noMatch() {
        #expect(
            paletteTabCompletion(
                query: "zzz",
                visibleTitles: ["New Document"],
                selectedTitle: nil
            ) == nil
        )
    }
}

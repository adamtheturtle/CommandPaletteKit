//
//  PaletteCandidateQueryReloadTests.swift
//  CommandPaletteKit
//

import SwiftUI
import Testing
@testable import CommandPaletteKit

@Suite("Debounced async candidate query reload")
struct PaletteCandidateQueryReloadTests {
    @Test("Default debounce is 150 milliseconds")
    func defaultDebounce() {
        #expect(PaletteCandidateQueryReload.defaultDebounceNanoseconds == 150_000_000)
    }

    @Test("Zero debounce loads immediately; positive values delay")
    func delayDecision() {
        #expect(
            PaletteCandidateQueryReload.shouldDelay(beforeReloadDebounceNanoseconds: 0) == false
        )
        #expect(
            PaletteCandidateQueryReload.shouldDelay(beforeReloadDebounceNanoseconds: 1)
        )
        #expect(
            PaletteCandidateQueryReload.shouldDelay(
                beforeReloadDebounceNanoseconds: PaletteCandidateQueryReload.defaultDebounceNanoseconds
            )
        )
    }

    @Test("Query-aware async initializers resolve with the built-in and custom rows")
    @MainActor
    func queryAwareInitializers() {
        _ = CommandPaletteView(
            queryDebounceNanoseconds: 0,
            candidates: { (_: String) async in
                [PaletteResult(id: "a", title: "Alpha", systemImage: "a.circle") {}]
            }
        )
        _ = CommandPaletteView(
            queryDebounceNanoseconds: 0,
            candidates: { (_: String) async in
                [PaletteResult(id: "a", title: "Alpha", systemImage: "a.circle") {}]
            },
            row: { result, isSelected in Text(result.title).bold(isSelected) }
        )
    }
}

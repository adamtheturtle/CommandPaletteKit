//
//  PaletteScorerRegistryTests.swift
//  CommandPaletteKit
//

import Testing
@testable import CommandPaletteKit

@Suite("Plugin registry for custom scorers")
struct PaletteScorerRegistryTests {
    @Test("Default registry exposes the fuzzy scorer")
    func defaultFuzzy() throws {
        let registry = PaletteScorerRegistry()
        let scorer = try #require(registry.scorer(named: PaletteScorerRegistry.fuzzyName))
        #expect(scorer("pad", "New Pad") != nil)
        #expect(registry.registeredNames.contains(PaletteScorerRegistry.fuzzyName))
    }

    @Test("Custom scorers can be registered, looked up, and removed")
    func customRegistration() {
        let registry = PaletteScorerRegistry(registeringDefaults: false)
        #expect(registry.registeredNames.isEmpty)

        let always: PaletteScorer = { _, _ in 42 }
        registry.register("always", scorer: always)
        #expect(registry.scorer(named: "always")?("q", "t") == 42)

        registry.unregister("always")
        #expect(registry.scorer(named: "always") == nil)
    }

    @Test("Shared registry starts with fuzzy registered")
    func sharedDefaults() {
        #expect(
            PaletteScorerRegistry.shared.scorer(named: PaletteScorerRegistry.fuzzyName) != nil
        )
    }
}

//
//  CandidateLoadGenerationTests.swift
//  CommandPaletteKit
//

import Foundation
import Testing

@testable import CommandPaletteKit

@Suite("Async candidate load generation")
struct CandidateLoadGenerationTests {
    @Test("A newer provider supersedes an older provider")
    func outOfOrderProviders() {
        var generation = CandidateLoadGeneration()

        let older = generation.begin()
        let newer = generation.begin()

        #expect(!generation.accepts(older))
        #expect(generation.accepts(newer))
    }

    @Test("A provider that ignores task cancellation is rejected")
    func ignoredCancellation() {
        var generation = CandidateLoadGeneration()
        let token = generation.begin()

        #expect(!generation.accepts(token, isCancelled: true))
    }

    @Test("Disappearance invalidates the in-flight provider")
    func disappearance() {
        var generation = CandidateLoadGeneration()
        let token = generation.begin()
        generation.invalidate()

        #expect(!generation.accepts(token))
    }

    @Test("Rapid re-entry is rate-limited")
    func rateLimitedReentry() {
        var generation = CandidateLoadGeneration()
        let start = Date(timeIntervalSince1970: 0)
        generation.markLoadStarted(at: start)
        #expect(generation.shouldStartLoad(at: start.addingTimeInterval(0.01)) == false)
        #expect(generation.shouldStartLoad(at: start.addingTimeInterval(0.06)))
    }

    @Test("Invalidation preserves the rate-limit window")
    func invalidateKeepsRateLimit() {
        var generation = CandidateLoadGeneration()
        let start = Date(timeIntervalSince1970: 0)
        let token = generation.begin()
        generation.markLoadStarted(at: start)
        generation.invalidate()

        #expect(!generation.accepts(token))
        #expect(generation.shouldStartLoad(at: start.addingTimeInterval(0.01)) == false)
        #expect(generation.shouldStartLoad(at: start.addingTimeInterval(0.06)))
    }
}

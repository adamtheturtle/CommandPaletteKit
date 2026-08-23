//
//  CommandPaletteView+CandidateLoading.swift
//  CommandPaletteKit
//

import SwiftUI

extension CommandPaletteView {
    func beginCandidateLoad() -> UInt64 {
        var generation = candidateLoadGeneration
        let token = generation.begin()
        candidateLoadGeneration = generation
        candidateLoadGeneration.markLoadStarted()
        return token
    }

    func shouldBeginCandidateLoad() -> Bool {
        candidateLoadGeneration.shouldStartLoad()
    }

    func invalidateCandidateLoads() {
        var generation = candidateLoadGeneration
        generation.invalidate()
        candidateLoadGeneration = generation
    }

    func loadAsyncCandidates(
        _ provider: @MainActor () async -> [PaletteResult]
    ) async {
        guard shouldBeginCandidateLoad() else {
            // Rate-limited re-entry: keep showing any retained results without a
            // stuck loading spinner.
            isLoading = false
            return
        }

        let generation = beginCandidateLoad()
        isLoading = true
        let loadedCandidates = await provider()
        guard candidateLoadGeneration.accepts(
            generation,
            isCancelled: Task.isCancelled
        ) else { return }

        candidates = loadedCandidates
        refreshResultSnapshot(candidates: loadedCandidates)
        isLoading = false
    }

    func loadAsyncQueryCandidates(
        debounceNanoseconds: UInt64,
        provider: @MainActor (String) async -> [PaletteResult]
    ) async {
        if PaletteCandidateQueryReload.shouldDelay(
            beforeReloadDebounceNanoseconds: debounceNanoseconds
        ) {
            do {
                try await Task.sleep(nanoseconds: debounceNanoseconds)
            } catch {
                return
            }
        }

        guard !Task.isCancelled else { return }

        // Query-driven reloads bypass the appear rate-limit so each settled query can
        // fetch; generation tokens still drop superseded in-flight results.
        let generation = beginCandidateLoad()
        isLoading = true
        let loadedCandidates = await provider(query)
        guard candidateLoadGeneration.accepts(
            generation,
            isCancelled: Task.isCancelled
        ) else { return }

        candidates = loadedCandidates
        refreshResultSnapshot(candidates: loadedCandidates)
        isLoading = false
    }
}

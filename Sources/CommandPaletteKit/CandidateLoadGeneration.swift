//
//  CandidateLoadGeneration.swift
//  CommandPaletteKit
//

import Foundation

/// Identifies the one async candidate request that may update a palette's state.
struct CandidateLoadGeneration {
    private var generation: UInt64 = 0
    private var lastLoadStartTime: Date = .distantPast

    /// Minimum spacing between provider invocations so rapid re-presentations do not start
    /// overlapping loads.
    static let minimumLoadInterval: TimeInterval = 0.05

    mutating func begin() -> UInt64 {
        generation &+= 1
        return generation
    }

    mutating func invalidate() {
        generation &+= 1
        // Keep `lastLoadStartTime` so a disappear/re-appear inside the minimum interval
        // still rate-limits a new provider. The generation bump alone rejects stale results.
    }

    mutating func markLoadStarted(at time: Date = Date()) {
        lastLoadStartTime = time
    }

    func shouldStartLoad(at time: Date = Date()) -> Bool {
        time.timeIntervalSince(lastLoadStartTime) >= Self.minimumLoadInterval
    }

    /// Seconds to wait before another provider may start after the last load began.
    func delayUntilNextLoadAllowed(at time: Date = Date()) -> TimeInterval {
        max(0, Self.minimumLoadInterval - time.timeIntervalSince(lastLoadStartTime))
    }

    func accepts(_ token: UInt64, isCancelled: Bool = false) -> Bool {
        !isCancelled && token == generation
    }
}

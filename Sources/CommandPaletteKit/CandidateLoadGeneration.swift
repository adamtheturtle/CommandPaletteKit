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
        lastLoadStartTime = .distantPast
    }

    mutating func markLoadStarted(at time: Date = Date()) {
        lastLoadStartTime = time
    }

    func shouldStartLoad(at time: Date = Date()) -> Bool {
        time.timeIntervalSince(lastLoadStartTime) >= Self.minimumLoadInterval
    }

    func accepts(_ token: UInt64, isCancelled: Bool = false) -> Bool {
        !isCancelled && token == generation
    }
}

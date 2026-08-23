//
//  PaletteScorerRegistry.swift
//  CommandPaletteKit
//
//  Named registry for plugging custom ``PaletteScorer`` implementations into hosts.
//

import Foundation

/// A process-wide registry of named ``PaletteScorer`` values.
///
/// The default ``paletteFuzzyScore(_:_:)`` is registered as ``PaletteScorerRegistry/fuzzyName``.
public final class PaletteScorerRegistry: @unchecked Sendable {
    /// Well-known name for the built-in fuzzy scorer.
    public static let fuzzyName = "fuzzy"

    /// Shared registry used by hosts that look scorers up by name.
    public static let shared = PaletteScorerRegistry()

    private let lock = NSLock()
    private var scorers: [String: PaletteScorer]

    public init(registeringDefaults: Bool = true) {
        scorers = [:]
        if registeringDefaults {
            scorers[Self.fuzzyName] = paletteFuzzyScore
        }
    }

    /// Registers or replaces the scorer stored under `name`.
    public func register(_ name: String, scorer: @escaping PaletteScorer) {
        lock.lock()
        defer { lock.unlock() }
        scorers[name] = scorer
    }

    /// Removes a previously registered scorer.
    public func unregister(_ name: String) {
        lock.lock()
        defer { lock.unlock() }
        scorers.removeValue(forKey: name)
    }

    /// Returns the scorer registered under `name`, if any.
    public func scorer(named name: String) -> PaletteScorer? {
        lock.lock()
        defer { lock.unlock() }
        return scorers[name]
    }

    /// Sorted names of registered scorers.
    public var registeredNames: [String] {
        lock.lock()
        defer { lock.unlock() }
        return scorers.keys.sorted()
    }
}

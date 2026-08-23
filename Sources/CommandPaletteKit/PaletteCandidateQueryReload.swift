//
//  PaletteCandidateQueryReload.swift
//  CommandPaletteKit
//
//  Debounce settings for reloading async candidates when the search query changes.
//

import Foundation

/// Timing for async candidate providers that reload on each query change.
public enum PaletteCandidateQueryReload: Sendable {
    /// Default pause after the last keystroke before the provider runs again (150 ms).
    public static let defaultDebounceNanoseconds: UInt64 = 150_000_000

    /// Clamps a caller-supplied debounce to a non-negative value.
    public static func normalizedDebounceNanoseconds(_ nanoseconds: UInt64) -> UInt64 {
        nanoseconds
    }

    /// Whether a scheduled reload should wait before invoking the provider.
    ///
    /// A zero debounce loads immediately (useful in tests); any positive value sleeps first.
    public static func shouldDelay(beforeReloadDebounceNanoseconds nanoseconds: UInt64) -> Bool {
        nanoseconds > 0
    }
}

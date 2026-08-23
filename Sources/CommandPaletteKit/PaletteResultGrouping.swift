//
//  PaletteResultGrouping.swift
//  CommandPaletteKit
//
//  Groups ranked results by ``PaletteResult/category`` for sectioned lists.
//

import Foundation
import SwiftUI

/// A category section in a grouped palette result list.
public struct PaletteResultGroup: Identifiable, Sendable {
    /// Stable identity for the section. Uses the category string, or a sentinel for uncategorized rows.
    public var id: String { category ?? "" }

    /// The shared ``PaletteResult/category`` for rows in this section, or `nil` when uncategorized.
    public let category: String?

    /// Ranked results that belong to this category, in score order.
    public let results: [PaletteResult]

    public init(category: String?, results: [PaletteResult]) {
        self.category = category
        self.results = results
    }
}

/// Groups already-ranked results by category, preserving first-seen category order and
/// within-group ranking order.
public func groupedPaletteResults(_ results: [PaletteResult]) -> [PaletteResultGroup] {
    var order: [String?] = []
    var buckets: [String?: [PaletteResult]] = [:]
    for result in results {
        let key = result.category
        if buckets[key] == nil {
            order.append(key)
            buckets[key] = []
        }
        buckets[key, default: []].append(result)
    }
    return order.map { PaletteResultGroup(category: $0, results: buckets[$0] ?? []) }
}

private struct CommandPaletteGroupsByCategoryKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// When `true`, ``CommandPaletteView`` renders category section headers above each group.
    public var commandPaletteGroupsResultsByCategory: Bool {
        get { self[CommandPaletteGroupsByCategoryKey.self] }
        set { self[CommandPaletteGroupsByCategoryKey.self] = newValue }
    }
}

extension View {
    /// Groups palette results under category headers. Off by default.
    public func commandPaletteGroupsResultsByCategory(_ enabled: Bool = true) -> some View {
        environment(\.commandPaletteGroupsResultsByCategory, enabled)
    }
}

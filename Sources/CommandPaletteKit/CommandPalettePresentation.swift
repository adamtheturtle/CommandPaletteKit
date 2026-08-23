//
//  CommandPalettePresentation.swift
//  CommandPaletteKit
//

import SwiftUI

extension View {
    /// Presents ``CommandPaletteView`` in a sheet bound to `isPresented`.
    ///
    /// Mirrors the conventional ⌘K presentation pattern from the Getting Started article
    /// without requiring each host to wire its own `.sheet`.
    public func commandPalettePresentation(
        isPresented: Binding<Bool>,
        placeholder: LocalizedStringKey = "Search…",
        emptyMessage: LocalizedStringKey = "Start typing to search.",
        noMatchesMessage: LocalizedStringKey = "No matches.",
        resultLimit: Int = 40,
        scorer: @escaping PaletteScorer = paletteFuzzyScore,
        width: CGFloat = 620,
        height: CGFloat = 460,
        onActivate: (@MainActor (PaletteResult) -> Void)? = nil,
        candidates: @escaping @MainActor () -> [PaletteResult]
    ) -> some View {
        sheet(isPresented: isPresented) {
            CommandPaletteView(
                placeholder: placeholder,
                emptyMessage: emptyMessage,
                noMatchesMessage: noMatchesMessage,
                resultLimit: resultLimit,
                scorer: scorer,
                width: width,
                height: height,
                onActivate: onActivate,
                candidates: candidates
            )
        }
    }

    /// Presents ``CommandPaletteView`` with an async candidate provider in a sheet.
    public func commandPalettePresentation(
        isPresented: Binding<Bool>,
        placeholder: LocalizedStringKey = "Search…",
        emptyMessage: LocalizedStringKey = "Start typing to search.",
        noMatchesMessage: LocalizedStringKey = "No matches.",
        loadingMessage: LocalizedStringKey = "Loading…",
        resultLimit: Int = 40,
        scorer: @escaping PaletteScorer = paletteFuzzyScore,
        width: CGFloat = 620,
        height: CGFloat = 460,
        onActivate: (@MainActor (PaletteResult) -> Void)? = nil,
        candidates: @escaping @MainActor () async -> [PaletteResult]
    ) -> some View {
        sheet(isPresented: isPresented) {
            CommandPaletteView(
                placeholder: placeholder,
                emptyMessage: emptyMessage,
                noMatchesMessage: noMatchesMessage,
                loadingMessage: loadingMessage,
                resultLimit: resultLimit,
                scorer: scorer,
                width: width,
                height: height,
                onActivate: onActivate,
                candidates: candidates
            )
        }
    }
}

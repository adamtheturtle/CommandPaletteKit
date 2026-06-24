//
//  CommandPaletteView.swift
//  CommandPaletteKit
//
//  A dependency-free, Combine-free "jump to anything" palette (⌘K): type to fuzzy-search
//  a caller-supplied list of ``PaletteResult`` and activate one by keyboard or click.
//  Present it however you like - typically as a sheet over your main window.
//
//  Everything that was hardcoded in the original app extraction is a parameter here, with
//  a default that reproduces the shipped look and feel, so the zero-configuration call
//  site stays short.
//

#if os(macOS)
    import AppKit
#endif
import SwiftUI

/// The command palette surface: a search field above a scrolling, keyboard-navigable
/// result list. Owns the query and the selection; the candidate list is built on appear
/// from the supplied provider and re-scored on every keystroke.
public struct CommandPaletteView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var candidates: [PaletteResult] = []
    @State private var selectedIndex = 0
    @FocusState private var queryFocused: Bool
    #if os(macOS)
        // Local key-event monitor for the up/down arrows. The search field is focused so
        // the user can type, but AppKit's field editor then swallows the arrow keys for
        // caret movement before SwiftUI's `.onKeyPress` ever sees them - so we watch for
        // them at the event level and drive the selection ourselves.
        @State private var arrowKeyMonitor: Any?
    #endif

    private let provider: @MainActor () -> [PaletteResult]
    private let placeholder: LocalizedStringKey
    private let emptyMessage: LocalizedStringKey
    private let noMatchesMessage: LocalizedStringKey
    private let resultLimit: Int
    private let scorer: PaletteScorer
    private let width: CGFloat
    private let height: CGFloat
    private let onActivate: (@MainActor (PaletteResult) -> Void)?

    /// Creates a palette.
    ///
    /// - Parameters:
    ///   - placeholder: Prompt shown in the empty search field.
    ///   - emptyMessage: Shown when the query is empty and nothing is listed yet.
    ///   - noMatchesMessage: Shown when a non-empty query matches nothing.
    ///   - resultLimit: Maximum rows rendered; the highest-scoring win. Pass `.max` for no limit.
    ///   - scorer: Match/scoring function. Defaults to ``paletteFuzzyScore(_:_:)``.
    ///   - width: Surface width.
    ///   - height: Surface height.
    ///   - onActivate: Called instead of `result.action` when a row is activated, if
    ///     provided - lets the host route activation itself. When `nil`, the palette
    ///     dismisses and calls `result.action`.
    ///   - candidates: Builds the candidate list. Evaluated on appear (and on the main actor).
    public init(
        placeholder: LocalizedStringKey = "Search…",
        emptyMessage: LocalizedStringKey = "Start typing to search.",
        noMatchesMessage: LocalizedStringKey = "No matches.",
        resultLimit: Int = 40,
        scorer: @escaping PaletteScorer = paletteFuzzyScore,
        width: CGFloat = 620,
        height: CGFloat = 460,
        onActivate: (@MainActor (PaletteResult) -> Void)? = nil,
        candidates: @escaping @MainActor () -> [PaletteResult]
    ) {
        self.placeholder = placeholder
        self.emptyMessage = emptyMessage
        self.noMatchesMessage = noMatchesMessage
        self.resultLimit = resultLimit
        self.scorer = scorer
        self.width = width
        self.height = height
        self.onActivate = onActivate
        self.provider = candidates
    }

    private var results: [PaletteResult] {
        let searching = !query.trimmingCharacters(in: .whitespaces).isEmpty
        let scored = candidates.compactMap { result -> (PaletteResult, Int)? in
            guard searching || !result.showsOnlyWhenSearching else { return nil }
            guard let score = scorer(query, result.searchText) else { return nil }

            return (result, score)
        }
        // Stable order: by score, then keep the original (caller-grouped) order for ties so
        // an empty query reads top-to-bottom in the order the candidates were supplied.
        return scored
            .enumerated()
            .sorted { lhs, rhs in
                lhs.element.1 != rhs.element.1 ? lhs.element.1 > rhs.element.1 : lhs.offset < rhs.offset
            }
            .prefix(resultLimit)
            .map(\.element.0)
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            resultsList
        }
        .frame(width: width, height: height)
        .onAppear {
            candidates = provider()
            queryFocused = true
            #if os(macOS)
                installArrowKeyMonitor()
            #endif
        }
        #if os(macOS)
        .onDisappear(perform: removeArrowKeyMonitor)
        #endif
    }

    #if os(macOS)
        // Watches key-down events while the palette is open and moves the selection on the
        // up/down arrows, consuming them so the focused field doesn't also move its caret.
        // `keyCode` 125 is the down arrow, 126 the up arrow.
        private func installArrowKeyMonitor() {
            guard arrowKeyMonitor == nil else { return }

            arrowKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                switch event.keyCode {
                case 125: move(by: 1); return nil
                case 126: move(by: -1); return nil
                default: return event
                }
            }
        }

        private func removeArrowKeyMonitor() {
            if let monitor = arrowKeyMonitor {
                NSEvent.removeMonitor(monitor)
                arrowKeyMonitor = nil
            }
        }
    #endif

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.title3)
                .accessibilityHidden(true)
            TextField(placeholder, text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($queryFocused)
                .onSubmit(activateSelection)
                .onChange(of: query) { _, _ in selectedIndex = 0 }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        // Escape-to-dismiss is a macOS hardware-key affordance; on iOS the sheet dismisses
        // via its own swipe-down / background tap.
        #if os(macOS)
        .onExitCommand { dismiss() }
        #endif
    }

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                resultsContent
                    .padding(8)
            }
            .onChange(of: selectedIndex) { _, new in
                scrollSelection(new, proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private var resultsContent: some View {
        LazyVStack(spacing: 2) {
            if results.isEmpty {
                emptyResultsMessage
            } else {
                resultRows
            }
        }
    }

    private var emptyResultsMessage: some View {
        Text(query.trimmingCharacters(in: .whitespaces).isEmpty ? emptyMessage : noMatchesMessage)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
    }

    private var resultRows: some View {
        ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
            resultRow(result, index: index)
        }
    }

    private func resultRow(_ result: PaletteResult, index: Int) -> some View {
        PaletteRow(result: result, isSelected: index == selectedIndex)
            // Identify the row by the result's stable id (matching the ForEach identity),
            // not its position: a bare `.id(index)` keeps ids 0,1,2… fixed while a search
            // re-orders the content under them, so the highlight and scroll target drift.
            .id(result.id)
            .contentShape(Rectangle())
            .onTapGesture { activate(result) }
            // Hovering a row makes it the selection, so the mouse and keyboard share one
            // highlight and a click always activates the row under the cursor. The hovered
            // row is by definition visible, so the scroll handler can't lurch the list.
            .onHover { hovering in
                if hovering { selectedIndex = index }
            }
            // One combined element per row so VoiceOver reads it as a single button, and
            // the selected one announces (and exposes for tests) the `.isSelected` trait.
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
    }

    private func scrollSelection(_ new: Int, proxy: ScrollViewProxy) {
        // Scroll by the selected result's stable id, and only enough to keep it visible
        // (no forced centering, which lurches a short filtered list).
        guard results.indices.contains(new) else { return }

        let id = results[new].id
        withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(id) }
    }

    private func move(by delta: Int) {
        let count = results.count
        guard count > 0 else { return }

        selectedIndex = min(max(selectedIndex + delta, 0), count - 1)
    }

    private func activateSelection() {
        let current = results
        guard current.indices.contains(selectedIndex) else { return }

        activate(current[selectedIndex])
    }

    private func activate(_ result: PaletteResult) {
        dismiss()
        if let onActivate {
            onActivate(result)
        } else {
            result.action()
        }
    }
}

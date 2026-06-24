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
public struct CommandPaletteView<RowContent: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.commandPaletteExtendedKeyboardNavigation) private var extendedNavigation

    @State private var query = ""
    @State private var candidates: [PaletteResult] = []
    @State private var selectedIndex = 0
    @State private var isLoading = false
    @FocusState private var queryFocused: Bool
    #if os(macOS)
        // Local key-event monitor for the up/down arrows. The search field is focused so
        // the user can type, but AppKit's field editor then swallows the arrow keys for
        // caret movement before SwiftUI's `.onKeyPress` ever sees them - so we watch for
        // them at the event level and drive the selection ourselves.
        @State private var arrowKeyMonitor: Any?
    #endif

    // Where the candidate list comes from: built synchronously on appear, or awaited from
    // an async provider (showing a loading affordance until it resolves). Internal so the
    // public initializers in CommandPaletteView+Initializers.swift can construct it.
    enum CandidateSource {
        case sync(@MainActor () -> [PaletteResult])
        case async(@MainActor () async -> [PaletteResult])
    }

    private let source: CandidateSource
    private let placeholder: LocalizedStringKey
    private let emptyMessage: LocalizedStringKey
    private let noMatchesMessage: LocalizedStringKey
    private let loadingMessage: LocalizedStringKey
    private let resultLimit: Int
    private let scorer: PaletteScorer
    private let width: CGFloat
    private let height: CGFloat
    private let onActivate: (@MainActor (PaletteResult) -> Void)?
    private let row: (PaletteResult, Bool) -> RowContent

    // The fully-specified initializer all public initializers funnel into. Kept internal
    // (not private) so the public initializers in CommandPaletteView+Initializers.swift can
    // reach it; the public surface is the initializers in that file.
    init(
        source: CandidateSource,
        placeholder: LocalizedStringKey,
        emptyMessage: LocalizedStringKey,
        noMatchesMessage: LocalizedStringKey,
        loadingMessage: LocalizedStringKey,
        resultLimit: Int,
        scorer: @escaping PaletteScorer,
        width: CGFloat,
        height: CGFloat,
        onActivate: (@MainActor (PaletteResult) -> Void)?,
        row: @escaping (PaletteResult, Bool) -> RowContent
    ) {
        self.source = source
        self.placeholder = placeholder
        self.emptyMessage = emptyMessage
        self.noMatchesMessage = noMatchesMessage
        self.loadingMessage = loadingMessage
        self.resultLimit = resultLimit
        self.scorer = scorer
        self.width = width
        self.height = height
        self.onActivate = onActivate
        self.row = row
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
            // Build a synchronous list up front so the zero-config case shows instantly
            // with no loading flash. The async source is loaded in `.task` below.
            if case .sync(let provider) = source {
                candidates = provider()
            }
            queryFocused = true
            #if os(macOS)
                installArrowKeyMonitor()
            #endif
        }
        .task {
            guard case .async(let provider) = source else { return }

            isLoading = true
            candidates = await provider()
            isLoading = false
        }
        #if os(macOS)
        .onDisappear(perform: removeArrowKeyMonitor)
        #endif
        #if os(iOS)
        // iPad hardware-keyboard navigation. The search field is the focused descendant, so
        // these ancestor handlers see its key events first and consume the arrows (returning
        // `.handled`) before the field would move its caret - the macOS equivalent of the
        // NSEvent monitor above. Return is already handled by the field's `onSubmit`.
        .onKeyPress(.upArrow) { move(by: -1); return .handled }
        .onKeyPress(.downArrow) { move(by: 1); return .handled }
        .onKeyPress(.escape) { dismiss(); return .handled }
        // Opt-in power-user keys. The handlers are always attached but no-op (returning
        // `.ignored`, so the key falls through to the field) unless the host has enabled
        // them, keeping default behaviour unchanged when off. Ctrl-N/Ctrl-P share the "n"/"p"
        // characters with normal typing, so they only act with the Control modifier held.
        .onKeyPress(characters: CharacterSet(charactersIn: "np"), phases: [.down, .repeat]) { keyPress in
            guard extendedNavigation, keyPress.modifiers.contains(.control) else { return .ignored }

            move(by: keyPress.characters == "n" ? 1 : -1)
            return .handled
        }
        .onKeyPress(.pageUp) {
            guard extendedNavigation else { return .ignored }

            move(by: -pageStep)
            return .handled
        }
        .onKeyPress(.pageDown) {
            guard extendedNavigation else { return .ignored }

            move(by: pageStep)
            return .handled
        }
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
                default: return extendedNavigation ? handleExtendedKey(event) : event
                }
            }
        }

        // The opt-in power-user keys on macOS, consumed only when enabled: Ctrl-N/Ctrl-P to
        // move down/up and Page Up/Down (keyCodes 116/121) to jump a viewport. Returns `nil`
        // to consume a handled event, or the original event to let it through. The text
        // field's own Ctrl-N/Ctrl-P (line motion) and page scrolling are pre-empted here.
        private func handleExtendedKey(_ event: NSEvent) -> NSEvent? {
            if event.modifierFlags.contains(.control) {
                switch event.charactersIgnoringModifiers {
                case "n": move(by: 1); return nil
                case "p": move(by: -1); return nil
                default: break
                }
            }
            switch event.keyCode {
            case 116: move(by: -pageStep); return nil
            case 121: move(by: pageStep); return nil
            default: return event
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
            if isLoading && results.isEmpty {
                loadingMessageView
            } else if results.isEmpty {
                emptyResultsMessage
            } else {
                resultRows
            }
        }
    }

    private var loadingMessageView: some View {
        ProgressView {
            Text(loadingMessage)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 40)
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
        row(result, index == selectedIndex)
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

    // How many rows Page Up/Down jumps: roughly a viewport of rows, keeping one row of
    // overlap for context. Estimated from the surface height and a nominal row height
    // (the list isn't measured), and never less than one row. Internal for testing.
    var pageStep: Int {
        let approximateRowHeight: CGFloat = 36
        let searchFieldHeight: CGFloat = 56
        let listHeight = max(height - searchFieldHeight, approximateRowHeight)
        let rowsPerPage = Int((listHeight / approximateRowHeight).rounded(.down))
        return max(rowsPerPage - 1, 1)
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

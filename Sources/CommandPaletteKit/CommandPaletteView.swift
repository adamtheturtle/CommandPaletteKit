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

let maximumPaletteDimension: CGFloat = 10_000

/// Returns geometry that is safe to pass to SwiftUI's fixed-size frame API.
func normalizedPaletteDimension(_ dimension: CGFloat, fallback: CGFloat) -> CGFloat {
    guard dimension.isFinite, dimension > 0 else { return fallback }

    return min(dimension, maximumPaletteDimension)
}

/// Keeps result identity unambiguous for SwiftUI rows and scroll targets.
///
/// The first candidate supplied for an ID wins. Doing this before filtering and scoring
/// makes the result deterministic across queries and prevents a duplicate from silently
/// replacing the action associated with an existing row.
func deduplicatedPaletteResults(_ results: [PaletteResult]) -> [PaletteResult] {
    var seenIDs = Set<String>()
    return results.filter { seenIDs.insert($0.id).inserted }
}

/// The command palette surface: a search field above a scrolling, keyboard-navigable
/// result list. Owns the query and the selection; the candidate list is built on appear
/// from the supplied provider and re-scored on every keystroke.
public struct CommandPaletteView<RowContent: View>: View {
    // Internal (not private): search/results chrome lives in
    // CommandPaletteView+Content.swift, and `private` is file-scoped.
    @Environment(\.dismiss) var dismiss
    @Environment(\.commandPaletteExtendedKeyboardNavigation) var extendedNavigation
    @Environment(\.commandPaletteStyle) var style
    @Environment(\.commandPaletteShowsKeyBindingFooter) var showsKeyBindingFooter
    @Environment(\.commandPaletteGroupsResultsByCategory) var groupsByCategory
    @Environment(\.commandPalettePinnedIDs) var pinnedIDs

    @State var query = ""
    @State var candidates: [PaletteResult] = []
    @State var selectedIndex = 0
    @State var isLoading = false
    /// Set while a row is being activated so lifecycle-only dismissals never run actions.
    @State var isActivatingSelection = false
    @State var candidateLoadGeneration = CandidateLoadGeneration()
    @State var measuredRowHeights: [String: CGFloat] = [:]
    @State var resultSnapshot = PaletteResultSnapshot()
    @FocusState var queryFocused: Bool
    // Keeps a scroll-induced hover from stealing the selection back from the keyboard.
    // `@State`, not a local: the hover handler and `move(by:)` are different callbacks and
    // must share one gate.
    @State var hoverGate = HoverSelectionGate()
    // A snapshot of `extendedNavigation`, refreshed from `body` (below) whenever the
    // environment value changes. `@Environment` is only meaningful while the view is
    // installed, so the escaping key-monitor closure - which runs long after body
    // evaluation - reads this instead; reading the environment property there yields the
    // default (`false`) and quietly disables the opt-in keys altogether.
    @State var extendedNavigationEnabled = false
    #if os(tvOS)
        // Focus identity for the highlighted row so the Siri Remote's focus engine and the
        // palette's selection stay aligned.
        @FocusState var focusedResultID: String?
    #endif
    #if os(macOS)
        // Local key-event monitor for the up/down arrows. The search field is focused so
        // the user can type, but AppKit's field editor then swallows the arrow keys for
        // caret movement before SwiftUI's `.onKeyPress` ever sees them - so we watch for
        // them at the event level and drive the selection ourselves.
        // Internal, not private: the monitor itself lives in
        // CommandPaletteView+KeyMonitor.swift, and `private` is file-scoped.
        @State var arrowKeyMonitor: Any?
        // The window the palette is presented in, so the monitor can tell the palette's own
        // key events from those of every other window in the application.
        @State var paletteWindow: NSWindow?
    #endif

    // Where the candidate list comes from: built synchronously on appear, or awaited from
    // an async provider (showing a loading affordance until it resolves). Internal so the
    // public initializers in CommandPaletteView+Initializers.swift can construct it.
    enum CandidateSource {
        case sync(@MainActor () -> [PaletteResult])
        case async(@MainActor () async -> [PaletteResult])
        /// Host-owned catalog that the palette mirrors. Apply
        /// ``PaletteCandidateRefresh/applying(upserts:removingIDs:to:)`` to the binding's
        /// wrapped value to refresh incrementally without rebuilding the view.
        case binding(Binding<[PaletteResult]>)
        /// Reloads whenever the query changes, waiting `debounceNanoseconds` after the last
        /// change so keystrokes do not stampede the provider.
        case asyncQuery(
            debounceNanoseconds: UInt64,
            @MainActor (String) async -> [PaletteResult]
        )
    }

    let source: CandidateSource
    let placeholder: LocalizedStringKey
    let emptyMessage: LocalizedStringKey
    let noMatchesMessage: LocalizedStringKey
    let loadingMessage: LocalizedStringKey
    let resultLimit: Int
    let scorer: PaletteScorer
    let width: CGFloat
    let height: CGFloat
    let onActivate: (@MainActor (PaletteResult) -> Void)?
    let row: (PaletteResult, Bool) -> RowContent

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
        self.resultLimit = normalizedResultLimit(resultLimit)
        self.scorer = scorer
        self.width = normalizedPaletteDimension(width, fallback: 620)
        self.height = normalizedPaletteDimension(height, fallback: 460)
        self.onActivate = onActivate
        self.row = row
    }

    var results: [PaletteResult] {
        resultSnapshot.results
    }

    /// Identity fingerprint for bound catalogs so SwiftUI can observe incremental edits.
    var bindingCandidateFingerprint: String {
        guard case .binding(let binding) = source else { return "" }

        return binding.wrappedValue.map {
            "\($0.id)\u{1E}\($0.title)\u{1E}\($0.subtitle ?? "")\u{1E}\($0.category ?? "")\u{1E}\($0.searchText)"
        }.joined(separator: "\u{1F}")
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            resultsList
            if showsKeyBindingFooter {
                Divider()
                CommandPaletteKeyBindingFooter()
            }
        }
        .frame(width: width, height: height)
        .environment(\.commandPaletteQuery, query)
        .background {
            if let material = style.backgroundMaterial {
                Rectangle().fill(material)
            }
        }
        // Read the environment value here, during body evaluation, where it is actually
        // installed - and mirror it into `@State` for the escaping monitor closure to use.
        // `initial: true` seeds it on the first evaluation, so the two never disagree.
        .onChange(of: extendedNavigation, initial: true) { _, enabled in
            extendedNavigationEnabled = enabled
        }
        .onChange(of: pinnedIDs) { _, _ in
            refreshResultSnapshot()
            selectedIndex = min(selectedIndex, max(results.count - 1, 0))
        }
        #if os(macOS)
        .background(WindowReader { paletteWindow = $0 })
        #endif
        .onAppear {
            resetPresentationState()
            // Build a synchronous list up front so the zero-config case shows instantly
            // with no loading flash. The async source is loaded in `.task` below.
            if case .sync(let provider) = source {
                invalidateCandidateLoads()
                let loadedCandidates = provider()
                candidates = loadedCandidates
                refreshResultSnapshot(candidates: loadedCandidates)
                isLoading = false
            } else if case .binding(let binding) = source {
                invalidateCandidateLoads()
                let loadedCandidates = binding.wrappedValue
                candidates = loadedCandidates
                refreshResultSnapshot(candidates: loadedCandidates)
                isLoading = false
            } else if case .async = source {
                // Mark loading immediately so retained results show the partial indicator
                // (or the empty list shows the full spinner) before `.task` resumes.
                isLoading = true
            } else if case .asyncQuery = source {
                isLoading = true
            }
            queryFocused = true
            #if os(macOS)
                installArrowKeyMonitor()
            #endif
        }
        .onChange(of: bindingCandidateFingerprint) { _, _ in
            guard case .binding(let binding) = source else { return }

            let loadedCandidates = binding.wrappedValue
            candidates = loadedCandidates
            refreshResultSnapshot(candidates: loadedCandidates)
            selectedIndex = min(selectedIndex, max(results.count - 1, 0))
        }
        .task {
            guard case .async(let provider) = source else { return }

            while !Task.isCancelled {
                let delay = candidateLoadGeneration.delayUntilNextLoadAllowed()
                if delay > 0 {
                    // Rate-limited re-entry: keep showing any retained results without a
                    // stuck loading spinner, then retry once the window elapses.
                    isLoading = false
                    try? await Task.sleep(for: .seconds(delay))
                    continue
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
                return
            }
        }
        // Cancels the previous sleep/load when the query changes, so only the settled
        // query invokes the provider after the debounce window.
        .task(id: query) {
            guard case .asyncQuery(let debounceNanoseconds, let provider) = source else {
                return
            }
            await loadAsyncQueryCandidates(
                debounceNanoseconds: debounceNanoseconds,
                provider: provider
            )
        }
        .onDisappear {
            invalidateCandidateLoads()
            isLoading = false
            isActivatingSelection = false
            #if os(macOS)
                removeArrowKeyMonitor()
            #endif
        }
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
        .onKeyPress(.home) {
            guard extendedNavigation else { return .ignored }

            move(by: -Int.max)
            return .handled
        }
        .onKeyPress(.end) {
            guard extendedNavigation else { return .ignored }

            move(by: Int.max)
            return .handled
        }
        #endif
        #if os(tvOS)
        // Siri Remote / game-controller navigation. Rows are focusable (see resultRow) so
        // focus and `selectedIndex` stay aligned; move commands also nudge the selection
        // when focus sits on the search field.
        .onMoveCommand { direction in
            // Only nudge selection from the search field. When a result row already has
            // focus, the focus engine moves between rows and `onChange(of: focusedResultID)`
            // updates `selectedIndex`; calling `move(by:)` here would double-step.
            guard focusedResultID == nil else { return }

            switch direction {
            case .up: move(by: -1)
            case .down: move(by: 1)
            default: break
            }
        }
        .onPlayPauseCommand { activateSelection() }
        .onExitCommand { dismiss() }
        .onChange(of: focusedResultID) { _, newID in
            guard let newID,
                  let index = results.firstIndex(where: { $0.id == newID })
            else { return }

            selectedIndex = index
        }
        #endif
    }
}

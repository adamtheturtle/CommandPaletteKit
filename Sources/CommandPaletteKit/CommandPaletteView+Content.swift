//
//  CommandPaletteView+Content.swift
//  CommandPaletteKit
//
//  Search field, results list, and activation helpers extracted from
//  ``CommandPaletteView`` so the primary type body stays within SwiftLint's
//  type_body_length limit.
//

import SwiftUI

extension CommandPaletteView {
    var searchField: some View {
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
                .onChange(of: query) { _, _ in
                    selectedIndex = 0
                    refreshResultSnapshot()
                }
                .accessibilityHint(Text(
                    "Type to filter commands. Use the arrow keys to move the selection, then press Return to activate."
                ))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        // Escape-to-dismiss is a macOS hardware-key affordance; on iOS the sheet dismisses
        // via its own swipe-down / background tap.
        #if os(macOS)
        .onExitCommand { dismiss() }
        #endif
    }

    var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                resultsContent
                    .padding(8)
            }
            .onChange(of: selectedIndex) { _, new in
                scrollSelection(new, proxy: proxy)
                announceSelectionChange(at: new)
            }
            .onPreferenceChange(PaletteRowHeightPreferenceKey.self) { heights in
                if measuredRowHeights != heights { measuredRowHeights = heights }
            }
        }
    }

    @ViewBuilder
    var resultsContent: some View {
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

    var loadingMessageView: some View {
        ProgressView {
            Text(loadingMessage)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 40)
    }

    var emptyResultsMessage: some View {
        Text(normalizedPaletteQuery(query).isEmpty ? emptyMessage : noMatchesMessage)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
    }

    var resultRows: some View {
        ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
            resultRow(result, index: index)
        }
    }

    func resultRow(_ result: PaletteResult, index: Int) -> some View {
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
            //
            // The reverse coupling does need guarding: a keyboard move scrolls the list,
            // which slides rows under a stationary cursor, which SwiftUI reports as a hover
            // that would write the selection straight back. ``HoverSelectionGate`` ignores
            // hovers for a moment after a keyboard move so navigation can't be stalled by a
            // mouse that is simply sitting there.
            #if !os(tvOS)
                .onHover { hovering in
                    guard hovering, hoverGate.allowsHoverSelection() else { return }

                    selectedIndex = index
                }
            #endif
            // One combined element per row so VoiceOver reads it as a single button, and
            // the selected one announces (and exposes for tests) the `.isSelected` trait.
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: PaletteRowHeightPreferenceKey.self,
                        value: [result.id: geometry.size.height]
                    )
                }
            }
    }

    func scrollSelection(_ new: Int, proxy: ScrollViewProxy) {
        // Scroll by the selected result's stable id, and only enough to keep it visible
        // (no forced centering, which lurches a short filtered list).
        guard results.indices.contains(new) else { return }

        let id = results[new].id
        withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(id) }
    }

    func announceSelectionChange(at index: Int) {
        guard let result = resultSnapshot.result(at: index) else { return }

        var announcement = result.title
        if let subtitle = result.subtitle, !subtitle.isEmpty {
            announcement += ", \(subtitle)"
        }
        AccessibilityNotification.Announcement(announcement).post()
    }

    // Internal so the macOS key monitor in CommandPaletteView+KeyMonitor.swift can
    // drive it; `private` is file-scoped.
    func move(by delta: Int) {
        let count = results.count
        guard count > 0 else { return }

        let new = clampedSelectionIndex(current: selectedIndex, delta: delta, count: count)
        guard new != selectedIndex else { return }

        // Hold hover off for a beat: this selection change is about to scroll the list, and
        // the rows sliding under the cursor would otherwise hover the selection back.
        hoverGate.keyboardDidMove()
        selectedIndex = new
    }

    // How many rows Page Up/Down jumps: roughly a viewport of the currently realized custom
    // rows, keeping one row of overlap for context. Internal for testing.
    var pageStep: Int {
        pageNavigationStep(
            for: height,
            rowHeight: representativePaletteRowHeight(Array(measuredRowHeights.values))
        )
    }

    func activateSelection() {
        guard let selectedResult = resultSnapshot.result(at: selectedIndex) else { return }

        activate(selectedResult)
    }

    func activate(_ result: PaletteResult) {
        dismiss()
        if let onActivate {
            onActivate(result)
        } else {
            result.action()
        }
    }
}

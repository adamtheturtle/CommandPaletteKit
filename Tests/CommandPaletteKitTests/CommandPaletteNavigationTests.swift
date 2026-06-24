//
//  CommandPaletteNavigationTests.swift
//  CommandPaletteKit
//
//  Covers the viewport-sized Page Up/Down step. The key interception itself is exercised
//  on a device; here we lock down the page-size math derived from the surface height.
//

import SwiftUI
import Testing

@testable import CommandPaletteKit

@MainActor
@Suite("Page navigation step")
struct CommandPaletteNavigationTests {
    private func palette(height: CGFloat) -> CommandPaletteView<PaletteRow> {
        CommandPaletteView(height: height) { [] }
    }

    @Test("A taller surface pages by more rows")
    func tallerPagesFurther() {
        #expect(palette(height: 800).pageStep > palette(height: 300).pageStep)
    }

    @Test("The page step is always at least one row")
    func neverLessThanOne() {
        #expect(palette(height: 1).pageStep >= 1)
        #expect(palette(height: 0).pageStep >= 1)
    }

    @Test("A default-height surface pages by several rows")
    func defaultHeightPagesAPage() {
        // The default 460pt surface should jump well more than a single row but stay within
        // a sane bound, so Page Up/Down feels like a page rather than a nudge or a full jump.
        let step = palette(height: 460).pageStep
        #expect(step >= 5)
        #expect(step <= 20)
    }
}

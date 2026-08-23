//
//  PalettePointerHoverTests.swift
//  CommandPaletteKit
//

import Testing
@testable import CommandPaletteKit

@Suite("iPad pointer hover parity")
struct PalettePointerHoverTests {
    @Test("Hover selection is enabled off tvOS")
    func hoverSelectionAvailability() {
        #if os(tvOS)
            #expect(PalettePointerHover.supportsHoverSelection == false)
        #else
            #expect(PalettePointerHover.supportsHoverSelection)
        #endif
    }

    @Test("Pointer hover effect is iOS-only")
    func pointerHoverEffect() {
        #if os(iOS)
            #expect(PalettePointerHover.appliesPointerHoverEffect)
        #else
            #expect(PalettePointerHover.appliesPointerHoverEffect == false)
        #endif
    }
}

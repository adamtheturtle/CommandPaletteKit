//
//  WindowReaderSchedulingTests.swift
//  CommandPaletteKit
//

import Foundation
import Testing

/// Mirrors the deferral used in ``WindowReportingView/viewDidMoveToWindow()`` so regressions
/// are caught without needing an AppKit host window.
enum PaletteWindowReaderDeferral {
    static func deferStateUpdate(_ update: @escaping @Sendable () -> Void) {
        DispatchQueue.main.async(execute: update)
    }
}

@Suite("WindowReader scheduling")
struct WindowReaderSchedulingTests {
    @Test("Window resolution is deferred off the view update")
    func defersStateUpdate() async throws {
        final class Flag: @unchecked Sendable {
            var value = false
        }
        let flag = Flag()
        PaletteWindowReaderDeferral.deferStateUpdate {
            flag.value = true
        }
        #expect(flag.value == false)
        try await Task.sleep(for: .milliseconds(5))
        #expect(flag.value == true)
    }
}

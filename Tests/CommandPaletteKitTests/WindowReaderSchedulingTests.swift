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
    func defersStateUpdate() async {
        final class Flag: @unchecked Sendable {
            private let lock = NSLock()
            private var _value = false

            var value: Bool {
                get {
                    lock.lock()
                    defer { lock.unlock() }
                    return _value
                }
                set {
                    lock.lock()
                    defer { lock.unlock() }
                    _value = newValue
                }
            }
        }

        let flag = Flag()
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        PaletteWindowReaderDeferral.deferStateUpdate {
            flag.value = true
            continuation.yield(())
            continuation.finish()
        }
        // `DispatchQueue.main.async` must not run inline on this call stack.
        #expect(flag.value == false)
        var iterator = stream.makeAsyncIterator()
        await iterator.next()
        #expect(flag.value == true)
    }
}

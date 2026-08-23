//
//  PalettePointerHover.swift
//  CommandPaletteKit
//
//  Documents iPad pointer hover parity with macOS row highlighting.
//

import Foundation

/// Marker namespace for pointer-hover behaviour shared by macOS and iPadOS.
///
/// ``CommandPaletteView`` selects a row on hover on every platform except tvOS. On iOS /
/// iPadOS it also applies SwiftUI's ``SwiftUICore/View/hoverEffect`` so a connected pointer
/// shows the same highlight affordance as a trackpad on Mac.
public enum PalettePointerHover: Sendable {
    /// Platforms that participate in pointer-driven row selection.
    public static var supportsHoverSelection: Bool {
        #if os(tvOS)
            false
        #else
            true
        #endif
    }

    /// Platforms that apply an additional pointer hover effect chrome.
    public static var appliesPointerHoverEffect: Bool {
        #if os(iOS)
            true
        #else
            false
        #endif
    }
}

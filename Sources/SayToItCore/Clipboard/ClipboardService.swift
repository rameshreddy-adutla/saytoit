import AppKit
import Foundation

/// Protocol for clipboard operations.
public protocol ClipboardServiceProtocol: Sendable {
    /// Copy text to the system clipboard.
    func copyToClipboard(_ text: String)
    /// Paste from clipboard to frontmost app (simulates ⌘V).
    func pasteToFrontmostApp()
}

/// Clipboard operations using NSPasteboard.
public final class ClipboardService: ClipboardServiceProtocol, Sendable {
    public init() {}

    public func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    public func pasteToFrontmostApp() {
        // Simulate ⌘V keypress
        let source = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V key
        keyDown?.flags = .maskCommand

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

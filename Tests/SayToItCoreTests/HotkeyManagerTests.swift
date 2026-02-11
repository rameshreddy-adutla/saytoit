import XCTest
@testable import SayToItCore

final class HotkeyManagerTests: XCTestCase {
    func testDefaultShortcut() {
        let shortcut = HotkeyManager.Shortcut.default
        XCTAssertEqual(shortcut.keyCode, 1) // kVK_ANSI_S = 1
        XCTAssertEqual(shortcut.modifiers, UInt32(cmdKey | shiftKey))
    }

    func testShortcutEquality() {
        let a = HotkeyManager.Shortcut(keyCode: 1, modifiers: 256)
        let b = HotkeyManager.Shortcut(keyCode: 1, modifiers: 256)
        XCTAssertEqual(a, b)
    }

    func testShortcutInequality() {
        let a = HotkeyManager.Shortcut(keyCode: 1, modifiers: 256)
        let b = HotkeyManager.Shortcut(keyCode: 2, modifiers: 256)
        XCTAssertNotEqual(a, b)
    }

    func testManagerInit() {
        let manager = HotkeyManager()
        // Should init without crashing
        XCTAssertNotNil(manager)
    }

    func testHandlerRegistration() {
        let manager = HotkeyManager()
        var called = false
        manager.onHotkeyPressed {
            called = true
        }
        // Handler registered but not triggered in test (no event loop)
        XCTAssertFalse(called)
    }
}

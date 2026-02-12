import XCTest
import Carbon
@testable import SayToItCore

final class HotkeyManagerTests: XCTestCase {
    func testDefaultShortcut() {
        let shortcut = HotkeyManager.Shortcut.default
        XCTAssertEqual(shortcut.keyCode, UInt32(kVK_ANSI_S))
        XCTAssertEqual(shortcut.modifiers, UInt32(Carbon.cmdKey | Carbon.shiftKey))
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
        XCTAssertNotNil(manager)
    }

    func testHandlerRegistration() {
        let manager = HotkeyManager()
        let expectation = XCTestExpectation(description: "handler set")
        expectation.fulfill() // Just verify no crash on registration
        manager.onHotkeyPressed { }
        wait(for: [expectation], timeout: 1)
    }
}

import XCTest
@testable import SayToItCore

final class ClipboardServiceTests: XCTestCase {
    func testCopyToClipboard() {
        let service = ClipboardService()
        let testText = "SayToIt test clipboard \(UUID().uuidString)"
        service.copyToClipboard(testText)

        let pasteboard = NSPasteboard.general
        let result = pasteboard.string(forType: .string)
        XCTAssertEqual(result, testText)
    }

    func testCopyEmptyString() {
        let service = ClipboardService()
        service.copyToClipboard("")

        let pasteboard = NSPasteboard.general
        let result = pasteboard.string(forType: .string)
        XCTAssertEqual(result, "")
    }

    func testCopyOverwritesPrevious() {
        let service = ClipboardService()
        service.copyToClipboard("first")
        service.copyToClipboard("second")

        let pasteboard = NSPasteboard.general
        let result = pasteboard.string(forType: .string)
        XCTAssertEqual(result, "second")
    }
}

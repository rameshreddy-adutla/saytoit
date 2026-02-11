import XCTest
@testable import SayToItCore

final class TranscriptionResultTests: XCTestCase {
    func testInitWithAllFields() {
        let result = TranscriptionResult(
            text: "hello world",
            isFinal: true,
            confidence: 0.95,
            duration: 1.5
        )
        XCTAssertEqual(result.text, "hello world")
        XCTAssertTrue(result.isFinal)
        XCTAssertEqual(result.confidence, 0.95)
        XCTAssertEqual(result.duration, 1.5)
    }

    func testInitWithMinimalFields() {
        let result = TranscriptionResult(text: "test", isFinal: false)
        XCTAssertEqual(result.text, "test")
        XCTAssertFalse(result.isFinal)
        XCTAssertNil(result.confidence)
        XCTAssertNil(result.duration)
    }

    func testEquality() {
        let a = TranscriptionResult(text: "hi", isFinal: true, confidence: 0.9)
        let b = TranscriptionResult(text: "hi", isFinal: true, confidence: 0.9)
        XCTAssertEqual(a, b)
    }

    func testInequality() {
        let a = TranscriptionResult(text: "hi", isFinal: true)
        let b = TranscriptionResult(text: "hello", isFinal: true)
        XCTAssertNotEqual(a, b)
    }
}

final class TranscriptionErrorTests: XCTestCase {
    func testNoAPIKeyDescription() {
        let error = TranscriptionError.noAPIKey
        XCTAssertTrue(error.localizedDescription.contains("API key"))
    }

    func testConnectionFailedDescription() {
        let error = TranscriptionError.connectionFailed("timeout")
        XCTAssertTrue(error.localizedDescription.contains("timeout"))
    }

    func testAudioErrorDescription() {
        let error = TranscriptionError.audioError("no mic")
        XCTAssertTrue(error.localizedDescription.contains("no mic"))
    }
}

import XCTest
@testable import SayToItCore

final class DeepgramClientTests: XCTestCase {
    func testClientInitCreatesResultStream() {
        let config = DeepgramClient.Configuration(apiKey: "test-key")
        let client = DeepgramClient(configuration: config)
        // Should have a valid results stream
        XCTAssertNotNil(client.results)
    }

    func testStartWithEmptyAPIKeyThrows() async {
        let config = DeepgramClient.Configuration(apiKey: "")
        let client = DeepgramClient(configuration: config)

        do {
            try await client.startTranscription()
            XCTFail("Expected TranscriptionError.noAPIKey")
        } catch let error as TranscriptionError {
            if case .noAPIKey = error {
                // Expected
            } else {
                XCTFail("Expected noAPIKey, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testConfigurationDefaults() {
        let config = DeepgramClient.Configuration(apiKey: "key")
        XCTAssertEqual(config.model, "nova-2")
        XCTAssertEqual(config.language, "en")
        XCTAssertEqual(config.sampleRate, 16000)
        XCTAssertEqual(config.channels, 1)
        XCTAssertEqual(config.encoding, "linear16")
        XCTAssertTrue(config.punctuate)
        XCTAssertTrue(config.interimResults)
        XCTAssertEqual(config.endpointing, 300)
    }

    func testConfigurationCustomValues() {
        let config = DeepgramClient.Configuration(
            apiKey: "key",
            model: "nova-3",
            language: "es",
            sampleRate: 48000,
            channels: 2,
            encoding: "opus",
            punctuate: false,
            interimResults: false,
            endpointing: 500
        )
        XCTAssertEqual(config.model, "nova-3")
        XCTAssertEqual(config.language, "es")
        XCTAssertEqual(config.sampleRate, 48000)
        XCTAssertEqual(config.channels, 2)
        XCTAssertEqual(config.encoding, "opus")
        XCTAssertFalse(config.punctuate)
        XCTAssertFalse(config.interimResults)
        XCTAssertEqual(config.endpointing, 500)
    }

    func testStopWithoutStartDoesNotCrash() async {
        let config = DeepgramClient.Configuration(apiKey: "key")
        let client = DeepgramClient(configuration: config)
        await client.stopTranscription() // Should not throw or crash
    }
}

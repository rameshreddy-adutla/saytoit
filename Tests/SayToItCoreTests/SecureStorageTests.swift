import XCTest
@testable import SayToItCore

final class SecureStorageTests: XCTestCase {
    private let storage = SecureStorage(service: "com.saytoit.test")
    private let testKey = "test_api_key"

    override func tearDown() {
        try? storage.delete(key: testKey)
        super.tearDown()
    }

    func testStoreAndRetrieve() throws {
        try storage.store(key: testKey, value: "sk-test-123")
        let retrieved = try storage.retrieve(key: testKey)
        XCTAssertEqual(retrieved, "sk-test-123")
    }

    func testRetrieveNonExistentReturnsNil() throws {
        let result = try storage.retrieve(key: "nonexistent_key_\(UUID().uuidString)")
        XCTAssertNil(result)
    }

    func testOverwriteExistingValue() throws {
        try storage.store(key: testKey, value: "first-value")
        try storage.store(key: testKey, value: "second-value")
        let retrieved = try storage.retrieve(key: testKey)
        XCTAssertEqual(retrieved, "second-value")
    }

    func testDelete() throws {
        try storage.store(key: testKey, value: "to-delete")
        try storage.delete(key: testKey)
        let result = try storage.retrieve(key: testKey)
        XCTAssertNil(result)
    }

    func testDeleteNonExistentDoesNotThrow() {
        XCTAssertNoThrow(try storage.delete(key: "nonexistent_\(UUID().uuidString)"))
    }

    func testDeepgramKeyName() {
        XCTAssertEqual(SecureStorage.deepgramAPIKeyName, "deepgram_api_key")
    }
}

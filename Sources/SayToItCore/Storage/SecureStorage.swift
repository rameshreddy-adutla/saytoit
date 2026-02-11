import Foundation
import Security

/// Protocol for secure storage operations.
public protocol SecureStorageProtocol: Sendable {
    func store(key: String, value: String) throws
    func retrieve(key: String) throws -> String?
    func delete(key: String) throws
}

/// Keychain-backed secure storage for API keys and secrets.
public final class SecureStorage: SecureStorageProtocol, Sendable {
    private let service: String

    public init(service: String = "com.saytoit.app") {
        self.service = service
    }

    public func store(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecureStorageError.encodingFailed
        }

        // Delete existing item first
        try? delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecureStorageError.keychainError(status)
        }
    }

    public func retrieve(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let string = String(data: data, encoding: .utf8) else {
                throw SecureStorageError.decodingFailed
            }
            return string
        case errSecItemNotFound:
            return nil
        default:
            throw SecureStorageError.keychainError(status)
        }
    }

    public func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.keychainError(status)
        }
    }
}

/// Errors from secure storage operations.
public enum SecureStorageError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case keychainError(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode value for storage"
        case .decodingFailed:
            return "Failed to decode stored value"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        }
    }
}

// MARK: - Convenience keys

public extension SecureStorage {
    static let deepgramAPIKeyName = "deepgram_api_key"
}

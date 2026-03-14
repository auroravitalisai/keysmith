import Foundation
import Security

/// Manages secure storage of password entries in the iOS Keychain.
/// Uses kSecClassGenericPassword with app-specific service identifier.
/// Data is encrypted at rest by the Secure Enclave.
final class KeychainManager: Sendable {
    
    static let shared = KeychainManager()
    
    private let service = "com.auroravitalis.keysmith.vault"
    private let account = "password-entries"
    private let accessGroup: String? = "group.com.auroravitalis.keysmith"
    
    private init() {}
    
    // MARK: - Public API
    
    /// Save all password entries to Keychain
    /// Uses atomic delete-then-add to ensure access control attributes are always set.
    func saveEntries(_ entries: [PasswordEntry]) throws {
        let data = try JSONEncoder().encode(entries)

        // Always delete-then-add to guarantee kSecAttrAccessible is set consistently
        let query = baseQuery()
        SecItemDelete(query as CFDictionary) // ignore status — may not exist yet

        var addQuery = baseQuery()
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Load all password entries from Keychain
    func loadEntries() throws -> [PasswordEntry] {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return []
        }
        
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.unhandledError(status: status)
        }
        
        return try JSONDecoder().decode([PasswordEntry].self, from: data)
    }
    
    /// Delete all stored entries
    func deleteAll() throws {
        let query = baseQuery()
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Private
    
    private func baseQuery() -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }
}

enum KeychainError: LocalizedError {
    case unhandledError(status: OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .unhandledError(let status):
            if let message = SecCopyErrorMessageString(status, nil) {
                return "Keychain error: \(message)"
            }
            return "Keychain error: \(status)"
        }
    }
}

import Foundation
import CryptoKit
import Security

@MainActor
final class AppLockManager: ObservableObject {

    private let keychainService = "com.auroravitalis.keysmith.pin"
    private let pinHashAccount = "pin-hash"
    private let pinSaltAccount = "pin-salt"

    @Published private(set) var failedAttempts: Int = 0
    @Published private(set) var lockoutEndDate: Date?

    // MARK: - Public API

    var hasPIN: Bool {
        loadKeychainData(account: pinHashAccount) != nil
    }

    var isLockedOut: Bool {
        guard let end = lockoutEndDate else { return false }
        if Date() >= end {
            lockoutEndDate = nil
            return false
        }
        return true
    }

    var lockoutRemainingSeconds: Int {
        guard let end = lockoutEndDate else { return 0 }
        return max(0, Int(end.timeIntervalSinceNow))
    }

    func setPIN(_ pin: String) {
        let salt = generateSalt()
        let hash = hashPIN(pin, salt: salt)

        saveKeychainData(hash, account: pinHashAccount)
        saveKeychainData(salt, account: pinSaltAccount)
        failedAttempts = 0
        lockoutEndDate = nil
    }

    func verify(_ pin: String) -> Bool {
        guard !isLockedOut else { return false }

        guard let storedHash = loadKeychainData(account: pinHashAccount),
              let storedSalt = loadKeychainData(account: pinSaltAccount) else {
            return false
        }

        let inputHash = hashPIN(pin, salt: storedSalt)

        if inputHash == storedHash {
            failedAttempts = 0
            lockoutEndDate = nil
            return true
        } else {
            failedAttempts += 1
            applyLockoutIfNeeded()
            return false
        }
    }

    func changePIN(oldPIN: String, newPIN: String) -> Bool {
        guard verify(oldPIN) else { return false }
        setPIN(newPIN)
        return true
    }

    func deletePIN() {
        deleteKeychainData(account: pinHashAccount)
        deleteKeychainData(account: pinSaltAccount)
        failedAttempts = 0
        lockoutEndDate = nil
    }

    // MARK: - Hashing

    private func generateSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    private func hashPIN(_ pin: String, salt: Data) -> Data {
        let pinData = Data(pin.utf8)
        var input = salt
        input.append(pinData)
        let digest = SHA256.hash(data: input)
        return Data(digest)
    }

    // MARK: - Lockout

    private func applyLockoutIfNeeded() {
        let duration: TimeInterval?
        switch failedAttempts {
        case 5: duration = 30
        case 10: duration = 300
        case 15...: duration = 1800
        default: duration = nil
        }

        if let duration {
            lockoutEndDate = Date().addingTimeInterval(duration)
        }
    }

    // MARK: - Keychain Helpers

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
        ]
    }

    private func saveKeychainData(_ data: Data, account: String) {
        deleteKeychainData(account: account)

        var query = baseQuery(account: account)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadKeychainData(account: String) -> Data? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func deleteKeychainData(account: String) {
        let query = baseQuery(account: account)
        SecItemDelete(query as CFDictionary)
    }
}

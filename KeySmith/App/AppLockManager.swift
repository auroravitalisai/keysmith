import Foundation
import CommonCrypto
import Security

@MainActor
final class AppLockManager: ObservableObject {

    private let keychainService = "com.auroravitalis.keysmith.pin"
    private let pinHashAccount = "pin-hash"
    private let pinSaltAccount = "pin-salt"
    private let failedAttemptsAccount = "failed-attempts"
    private let lockoutEndAccount = "lockout-end"

    var failedAttempts: Int {
        get {
            guard let data = loadKeychainData(account: failedAttemptsAccount) else { return 0 }
            return (try? JSONDecoder().decode(Int.self, from: data)) ?? 0
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                saveKeychainData(data, account: failedAttemptsAccount)
            }
            objectWillChange.send()
        }
    }

    var lockoutEndDate: Date? {
        get {
            guard let data = loadKeychainData(account: lockoutEndAccount) else { return nil }
            return try? JSONDecoder().decode(Date.self, from: data)
        }
        set {
            if let date = newValue, let data = try? JSONEncoder().encode(date) {
                saveKeychainData(data, account: lockoutEndAccount)
            } else {
                deleteKeychainData(account: lockoutEndAccount)
            }
            objectWillChange.send()
        }
    }

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
        deleteKeychainData(account: failedAttemptsAccount)
        deleteKeychainData(account: lockoutEndAccount)
    }

    // MARK: - Hashing

    private func generateSalt() -> Data {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes)
    }

    private func hashPIN(_ pin: String, salt: Data) -> Data {
        let pinData = Data(pin.utf8)
        var derivedKey = Data(count: 32)

        derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                pinData.withUnsafeBytes { pinBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        pinBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        pinData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        600_000,
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }

        return derivedKey
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

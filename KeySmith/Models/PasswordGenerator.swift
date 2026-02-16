import Foundation
import Security

enum PasswordStrength: String, CaseIterable, Identifiable {
    case pin = "PIN"
    case basic = "Basic"
    case strong = "Strong"
    case paranoid = "Paranoid"
    
    var id: String { rawValue }
    
    var defaultLength: Int {
        switch self {
        case .pin: return 6
        case .basic: return 12
        case .strong: return 20
        case .paranoid: return 32
        }
    }
    
    var description: String {
        switch self {
        case .pin: return "Numeric only"
        case .basic: return "Letters + numbers"
        case .strong: return "Mixed with symbols"
        case .paranoid: return "Maximum entropy"
        }
    }
    
    var icon: String {
        switch self {
        case .pin: return "number"
        case .basic: return "textformat.abc"
        case .strong: return "lock.shield"
        case .paranoid: return "bolt.shield"
        }
    }
}

struct PasswordOptions: Codable, Equatable {
    var length: Int = 16
    var includeUppercase: Bool = true
    var includeLowercase: Bool = true
    var includeNumbers: Bool = true
    var includeSymbols: Bool = true
    var excludeAmbiguous: Bool = false
    
    static let ambiguousChars: Set<Character> = ["0", "O", "l", "1", "I"]
    
    var characterPool: String {
        var pool = ""
        if includeLowercase { pool += "abcdefghijklmnopqrstuvwxyz" }
        if includeUppercase { pool += "ABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if includeNumbers { pool += "0123456789" }
        if includeSymbols { pool += "!@#$%^&*()-_=+[]{}|;:,.<>?" }
        
        if excludeAmbiguous {
            pool = String(pool.filter { !Self.ambiguousChars.contains($0) })
        }
        
        return pool
    }
}

class PasswordGenerator {
    
    /// Generate a cryptographically secure random password
    static func generate(options: PasswordOptions) -> String {
        let pool = options.characterPool
        guard !pool.isEmpty else { return "" }
        
        let poolArray = Array(pool)
        var passwordChars: [Character] = []
        
        // Use SecRandomCopyBytes for cryptographic randomness
        for _ in 0..<options.length {
            let index = secureRandomIndex(upperBound: poolArray.count)
            passwordChars.append(poolArray[index])
        }
        
        // Ensure at least one character from each enabled category
        var guaranteeIndex = 0
        
        if options.includeLowercase && !passwordChars.contains(where: { $0.isLowercase }) {
            let chars = Array("abcdefghijklmnopqrstuvwxyz")
            passwordChars[guaranteeIndex] = chars[secureRandomIndex(upperBound: chars.count)]
            guaranteeIndex += 1
        }
        if options.includeUppercase && !passwordChars.contains(where: { $0.isUppercase }) {
            let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            passwordChars[guaranteeIndex] = chars[secureRandomIndex(upperBound: chars.count)]
            guaranteeIndex += 1
        }
        if options.includeNumbers && !passwordChars.contains(where: { $0.isNumber }) {
            let chars = Array("0123456789")
            passwordChars[guaranteeIndex] = chars[secureRandomIndex(upperBound: chars.count)]
            guaranteeIndex += 1
        }
        if options.includeSymbols && !passwordChars.contains(where: { "!@#$%^&*()-_=+[]{}|;:,.<>?".contains($0) }) {
            let chars = Array("!@#$%^&*()-_=+[]{}|;:,.<>?")
            passwordChars[guaranteeIndex] = chars[secureRandomIndex(upperBound: chars.count)]
            guaranteeIndex += 1
        }
        
        // Fisher-Yates shuffle with secure randomness
        for i in stride(from: passwordChars.count - 1, through: 1, by: -1) {
            let j = secureRandomIndex(upperBound: i + 1)
            passwordChars.swapAt(i, j)
        }
        
        return String(passwordChars)
    }
    
    static func generate(strength: PasswordStrength) -> String {
        var options = PasswordOptions()
        options.length = strength.defaultLength
        
        switch strength {
        case .pin:
            options.includeUppercase = false
            options.includeLowercase = false
            options.includeNumbers = true
            options.includeSymbols = false
        case .basic:
            options.includeUppercase = true
            options.includeLowercase = true
            options.includeNumbers = true
            options.includeSymbols = false
        case .strong:
            options.includeUppercase = true
            options.includeLowercase = true
            options.includeNumbers = true
            options.includeSymbols = true
        case .paranoid:
            options.includeUppercase = true
            options.includeLowercase = true
            options.includeNumbers = true
            options.includeSymbols = true
            options.length = 32
        }
        
        return generate(options: options)
    }
    
    /// Estimate password entropy (bits)
    static func estimateEntropy(password: String) -> Double {
        let length = Double(password.count)
        var poolSize: Double = 0
        
        if password.contains(where: { $0.isLowercase }) { poolSize += 26 }
        if password.contains(where: { $0.isUppercase }) { poolSize += 26 }
        if password.contains(where: { $0.isNumber }) { poolSize += 10 }
        if password.contains(where: { "!@#$%^&*()-_=+[]{}|;:,.<>?".contains($0) }) { poolSize += 27 }
        
        guard poolSize > 0 else { return 0 }
        return length * log2(poolSize)
    }
    
    /// Normalized strength 0-1 (128 bits = 1.0)
    static func estimateStrength(password: String) -> Double {
        let entropy = estimateEntropy(password: password)
        return min(entropy / 128.0, 1.0)
    }
    
    // MARK: - Cryptographic Random
    
    /// Generate a cryptographically secure random index
    private static func secureRandomIndex(upperBound: Int) -> Int {
        var randomBytes = [UInt8](repeating: 0, count: 4)
        let status = SecRandomCopyBytes(kSecRandomDefault, 4, &randomBytes)
        
        guard status == errSecSuccess else {
            // Fallback to SystemRandomNumberGenerator (still crypto-quality on Apple platforms)
            return Int.random(in: 0..<upperBound)
        }
        
        let value = randomBytes.withUnsafeBytes { $0.load(as: UInt32.self) }
        return Int(value % UInt32(upperBound))
    }
}

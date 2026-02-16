import Foundation

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
}

struct PasswordOptions {
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
    
    static func generate(options: PasswordOptions) -> String {
        let pool = options.characterPool
        guard !pool.isEmpty else { return "" }
        
        let poolArray = Array(pool)
        var password = ""
        
        for _ in 0..<options.length {
            let index = Int.random(in: 0..<poolArray.count)
            password.append(poolArray[index])
        }
        
        // Ensure at least one character from each enabled category
        var result = Array(password)
        var insertIndex = 0
        
        if options.includeLowercase && !result.contains(where: { $0.isLowercase }) {
            let chars = "abcdefghijklmnopqrstuvwxyz"
            result[insertIndex] = chars.randomElement()!
            insertIndex += 1
        }
        if options.includeUppercase && !result.contains(where: { $0.isUppercase }) {
            let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            result[insertIndex] = chars.randomElement()!
            insertIndex += 1
        }
        if options.includeNumbers && !result.contains(where: { $0.isNumber }) {
            let chars = "0123456789"
            result[insertIndex] = chars.randomElement()!
            insertIndex += 1
        }
        if options.includeSymbols && !result.contains(where: { "!@#$%^&*()-_=+[]{}|;:,.<>?".contains($0) }) {
            let chars = "!@#$%^&*()-_=+[]{}|;:,.<>?"
            result[insertIndex] = chars.randomElement()!
            insertIndex += 1
        }
        
        // Shuffle to avoid predictable positions
        result.shuffle()
        
        return String(result)
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
    
    static func estimateStrength(password: String) -> Double {
        let length = Double(password.count)
        var poolSize: Double = 0
        
        if password.contains(where: { $0.isLowercase }) { poolSize += 26 }
        if password.contains(where: { $0.isUppercase }) { poolSize += 26 }
        if password.contains(where: { $0.isNumber }) { poolSize += 10 }
        if password.contains(where: { "!@#$%^&*()-_=+[]{}|;:,.<>?".contains($0) }) { poolSize += 27 }
        
        guard poolSize > 0 else { return 0 }
        
        let entropy = length * log2(poolSize)
        return min(entropy / 128.0, 1.0) // Normalize to 0-1, 128 bits = max
    }
}

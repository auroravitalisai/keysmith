import Foundation
import Security

enum PasswordStrength: String, CaseIterable, Identifiable {
    case pin = "PIN"
    case basic = "Basic"
    case strong = "Strong"
    case paranoid = "Paranoid"
    case passphrase = "Passphrase"

    var id: String { rawValue }

    var defaultLength: Int {
        switch self {
        case .pin: return 6
        case .basic: return 12
        case .strong: return 20
        case .paranoid: return 32
        case .passphrase: return 5 // word count
        }
    }

    var description: String {
        switch self {
        case .pin: return "Numeric only"
        case .basic: return "Letters + numbers"
        case .strong: return "Mixed with symbols"
        case .paranoid: return "Maximum entropy"
        case .passphrase: return "Memorable words"
        }
    }

    var icon: String {
        switch self {
        case .pin: return "number"
        case .basic: return "textformat.abc"
        case .strong: return "lock.shield"
        case .paranoid: return "bolt.shield"
        case .passphrase: return "text.book.closed"
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
        if strength == .passphrase {
            return generatePassphrase(wordCount: strength.defaultLength)
        }

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
        case .passphrase:
            break // handled above
        }

        return generate(options: options)
    }

    // MARK: - Passphrase Generation

    /// Generate a passphrase from the embedded word list
    static func generatePassphrase(wordCount: Int, separator: String = "-") -> String {
        let count = max(wordCount, 3)
        var words: [String] = []
        for _ in 0..<count {
            let index = secureRandomIndex(upperBound: Self.wordList.count)
            words.append(Self.wordList[index])
        }
        return words.joined(separator: separator)
    }

    /// Estimate password entropy (bits)
    static func estimateEntropy(password: String) -> Double {
        // Detect passphrase pattern (words separated by dashes)
        let words = password.split(separator: "-")
        if words.count >= 3 && words.allSatisfy({ $0.allSatisfy({ $0.isLetter }) }) {
            // Estimate as passphrase: log2(wordListSize) per word
            return Double(words.count) * log2(Double(Self.wordList.count))
        }

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

    // MARK: - Cryptographic Random (Rejection Sampling)

    private static func secureRandomIndex(upperBound: Int) -> Int {
        precondition(upperBound > 0)
        if upperBound == 1 { return 0 }

        // Use rejection sampling to eliminate modulo bias
        let bytesNeeded = upperBound <= 256 ? 1 : (upperBound <= 65536 ? 2 : 4)
        let maxValue: UInt64 = bytesNeeded == 1 ? 256 : (bytesNeeded == 2 ? 65536 : 4294967296)
        let limit = maxValue - (maxValue % UInt64(upperBound))

        while true {
            var randomBytes = [UInt8](repeating: 0, count: bytesNeeded)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytesNeeded, &randomBytes)
            guard status == errSecSuccess else {
                return Int.random(in: 0..<upperBound)
            }

            var value: UInt64 = 0
            for byte in randomBytes {
                value = (value << 8) | UInt64(byte)
            }

            if value < limit {
                return Int(value % UInt64(upperBound))
            }
        }
    }

    // MARK: - Embedded Word List (200 common English words for passphrases)

    static let wordList: [String] = [
        "abandon", "ability", "account", "achieve", "address",
        "advance", "airport", "ancient", "animal", "answer",
        "balance", "basket", "battle", "beauty", "beyond",
        "blanket", "blossom", "bottle", "branch", "bridge",
        "candle", "canyon", "captain", "castle", "center",
        "chapter", "circle", "client", "closed", "cluster",
        "coffee", "column", "comfort", "common", "corner",
        "cotton", "country", "courage", "current", "custom",
        "damage", "danger", "debate", "decade", "desert",
        "detail", "dinner", "doctor", "domain", "double",
        "dragon", "dream", "driver", "effort", "eleven",
        "enable", "energy", "engine", "enough", "entire",
        "escape", "estate", "evolve", "example", "export",
        "fabric", "falcon", "family", "feline", "filter",
        "finger", "flavor", "flower", "forest", "frozen",
        "future", "galaxy", "garden", "gather", "gentle",
        "ginger", "global", "golden", "govern", "growth",
        "hammer", "harbor", "heaven", "hidden", "hollow",
        "honey", "humble", "hunger", "hybrid", "impact",
        "indoor", "infant", "insect", "island", "jacket",
        "jungle", "kidney", "kitten", "ladder", "lament",
        "launch", "legend", "lender", "lesson", "letter",
        "lizard", "lumber", "magnet", "manage", "marble",
        "market", "master", "meadow", "method", "middle",
        "mirror", "mobile", "monkey", "mother", "mustard",
        "nature", "needle", "nerve", "noble", "normal",
        "notice", "number", "oblong", "obtain", "ocean",
        "office", "onward", "orange", "output", "oxygen",
        "palace", "panda", "patrol", "pencil", "permit",
        "piano", "pillow", "planet", "pocket", "poetry",
        "powder", "puzzle", "rabbit", "racing", "random",
        "reason", "record", "rescue", "result", "ribbon",
        "ripple", "rocket", "saddle", "salmon", "season",
        "secret", "silver", "simple", "sketch", "social",
        "spider", "spring", "square", "stable", "summer",
        "supply", "switch", "symbol", "tablet", "talent",
        "temple", "timber", "tissue", "tomato", "travel",
        "trophy", "tunnel", "turtle", "umbrella", "unique",
        "vacant", "valley", "vendor", "venture", "vessel",
        "violet", "volume", "wallet", "wander", "window",
    ]
}

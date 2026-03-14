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

    /// Short label for compact preset circles
    var shortLabel: String {
        switch self {
        case .pin: return "PIN"
        case .basic: return "Basic"
        case .strong: return "Strong"
        case .paranoid: return "Max"
        case .passphrase: return "Phrase"
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

        // Ensure at least one character from each enabled category.
        // Collect missing categories, pick distinct random positions,
        // then place guaranteed characters at those positions.
        let symbolSet = "!@#$%^&*()-_=+[]{}|;:,.<>?"
        let ambiguous = PasswordOptions.ambiguousChars

        func filtered(_ source: String) -> [Character] {
            if options.excludeAmbiguous {
                return Array(source.filter { !ambiguous.contains($0) })
            }
            return Array(source)
        }

        var needed: [Character] = []
        if options.includeLowercase && !passwordChars.contains(where: { $0.isLowercase }) {
            let chars = filtered("abcdefghijklmnopqrstuvwxyz")
            needed.append(chars[secureRandomIndex(upperBound: chars.count)])
        }
        if options.includeUppercase && !passwordChars.contains(where: { $0.isUppercase }) {
            let chars = filtered("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            needed.append(chars[secureRandomIndex(upperBound: chars.count)])
        }
        if options.includeNumbers && !passwordChars.contains(where: { $0.isNumber }) {
            let chars = filtered("0123456789")
            needed.append(chars[secureRandomIndex(upperBound: chars.count)])
        }
        if options.includeSymbols && !passwordChars.contains(where: { symbolSet.contains($0) }) {
            let chars = filtered(symbolSet)
            needed.append(chars[secureRandomIndex(upperBound: chars.count)])
        }

        if !needed.isEmpty {
            // Pick distinct random indices for guaranteed characters
            var indices = Set<Int>()
            while indices.count < needed.count {
                indices.insert(secureRandomIndex(upperBound: passwordChars.count))
            }
            for (index, char) in zip(indices.sorted(), needed) {
                passwordChars[index] = char
            }
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
                // Fatal rather than falling back to non-cryptographic RNG.
                // A password manager must never silently degrade randomness.
                fatalError("SecRandomCopyBytes failed with status \(status) — cannot generate secure passwords")
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

    // MARK: - Embedded Word List (1030 words ≈ 10 bits/word for strong passphrases)
    // Curated from common English words, 3-8 letters, no profanity, easy to spell.

    static let wordList: [String] = [
        // A (40)
        "abandon", "ability", "about", "above", "absent", "absorb", "account", "achieve", "acid", "across",
        "action", "active", "adapt", "address", "admit", "adopt", "advance", "advice", "afford", "again",
        "agent", "agree", "ahead", "alarm", "album", "alien", "almost", "alpha", "always", "amount",
        "anchor", "ancient", "angel", "animal", "annual", "answer", "apart", "appeal", "apple", "arena",
        // B (40)
        "badge", "balance", "bamboo", "banana", "banner", "barrel", "basket", "battle", "beach", "beauty",
        "become", "before", "begin", "behind", "belief", "below", "bench", "beyond", "bicycle", "blanket",
        "blossom", "board", "bonus", "border", "bottle", "bottom", "bounce", "brain", "branch", "brave",
        "bread", "bridge", "brief", "bright", "broken", "bronze", "brush", "bubble", "bucket", "bundle",
        // C (48)
        "cabin", "cable", "cactus", "camera", "campus", "candle", "canyon", "captain", "carbon", "carpet",
        "castle", "casual", "catalog", "catch", "cattle", "caught", "cause", "caution", "ceiling", "cellar",
        "center", "central", "cereal", "certain", "chair", "chance", "change", "chapter", "charge", "chart",
        "cheese", "cherry", "chicken", "circle", "citizen", "client", "climate", "clinic", "clock", "cluster",
        "coach", "coffee", "collect", "colony", "column", "comfort", "common", "coral",
        // D (40)
        "damage", "danger", "daring", "debate", "decade", "decent", "decide", "decline", "deliver", "demand",
        "deny", "depart", "depend", "desert", "design", "detail", "detect", "develop", "device", "diamond",
        "diesel", "digital", "dinner", "direct", "doctor", "dolphin", "domain", "donkey", "double", "dragon",
        "dream", "dress", "drift", "driver", "dune", "during", "dust", "dutch", "dwarf", "dynamic",
        // E (40)
        "eagle", "early", "earth", "easily", "echo", "editor", "effort", "eight", "either", "elbow",
        "elder", "elect", "eleven", "enable", "endure", "energy", "engine", "enjoy", "enough", "ensure",
        "entire", "entry", "episode", "equal", "equip", "escape", "estate", "ethics", "evening", "evolve",
        "exact", "example", "excess", "exhibit", "exile", "expand", "expect", "export", "expose", "extend",
        // F (40)
        "fabric", "facing", "factor", "falcon", "family", "famous", "fancy", "fantasy", "farmer", "fatal",
        "feline", "fence", "ferry", "fetch", "fever", "fiber", "field", "figure", "filter", "final",
        "finger", "finish", "fiscal", "fitness", "flame", "flavor", "flight", "float", "flower", "fluid",
        "focus", "follow", "force", "forest", "forget", "formal", "fortune", "fossil", "frozen", "future",
        // G (40)
        "gadget", "galaxy", "gallery", "game", "garage", "garden", "garlic", "gather", "gauge", "general",
        "genius", "gentle", "giant", "ginger", "glacier", "glad", "glass", "glimpse", "global", "glory",
        "glove", "golden", "govern", "grace", "grain", "grape", "grass", "gravity", "green", "grocery",
        "ground", "group", "growth", "guard", "guess", "guide", "guitar", "guru", "gym", "gypsum",
        // H (40)
        "habit", "half", "hammer", "hand", "happy", "harbor", "harvest", "hawk", "hazard", "health",
        "heart", "heaven", "heavy", "hedgehog", "hello", "helmet", "hero", "hidden", "hiker", "hint",
        "hobby", "hockey", "hollow", "home", "honey", "hood", "hope", "horizon", "horror", "horse",
        "hotel", "hover", "huge", "human", "humble", "humor", "hundred", "hunger", "hybrid", "hymn",
        // I (32)
        "icon", "ignore", "image", "impact", "import", "impose", "improve", "impulse", "include", "income",
        "indoor", "infant", "inform", "initial", "injury", "inmate", "inner", "input", "insect", "inside",
        "install", "intact", "into", "invest", "invite", "iron", "island", "isolate", "issue", "item",
        "ivory", "index",
        // J-K (24)
        "jacket", "jaguar", "janitor", "jargon", "jasmine", "jewel", "journey", "judge", "juice", "jumble",
        "jungle", "junior", "kangaroo", "keen", "kernel", "kidney", "kind", "kingdom", "kitchen", "kitten",
        "knife", "knock", "known", "koala",
        // L (40)
        "label", "labor", "ladder", "lament", "lamp", "laptop", "large", "later", "launch", "lava",
        "layer", "leader", "learn", "legend", "lemon", "lender", "length", "lesson", "letter", "level",
        "liberty", "library", "light", "limit", "liquid", "listen", "little", "lizard", "loan", "lobster",
        "local", "logic", "lonely", "loop", "lottery", "lounge", "loyal", "lucky", "lumber", "lunar",
        // M (40)
        "machine", "magnet", "major", "mammal", "manage", "manual", "maple", "marble", "march", "margin",
        "market", "marvel", "mask", "master", "matrix", "matter", "meadow", "media", "melody", "member",
        "mental", "mercy", "method", "middle", "million", "mineral", "minor", "minute", "mirror", "mobile",
        "model", "modify", "moment", "monkey", "monster", "month", "moral", "mother", "motion", "mustard",
        // N (32)
        "naive", "narrow", "nation", "nature", "naval", "near", "needle", "nerve", "network", "neutral",
        "noble", "noise", "normal", "north", "notable", "nothing", "notice", "novel", "number", "nurse",
        "nutmeg", "nylon", "napkin", "nasty", "native", "neck", "neglect", "nephew", "nest", "net",
        "nice", "night",
        // O (32)
        "oasis", "object", "oblong", "obtain", "obvious", "occur", "ocean", "office", "olive", "onion",
        "online", "onward", "opera", "option", "orange", "orbit", "orchard", "order", "organ", "orient",
        "orphan", "ostrich", "other", "outdoor", "output", "oval", "owner", "oxygen", "oyster", "ozone",
        "october", "often",
        // P (48)
        "paddle", "palace", "panda", "panel", "panic", "paper", "parade", "parent", "patrol", "pattern",
        "pause", "peanut", "pencil", "people", "pepper", "perfect", "permit", "person", "phrase", "piano",
        "picnic", "picture", "pillow", "pilot", "pink", "planet", "plastic", "plate", "pledge", "pluck",
        "plunge", "pocket", "poetry", "point", "polar", "polish", "pond", "popular", "portion", "powder",
        "power", "present", "pretty", "pride", "prison", "problem", "program", "puzzle",
        // Q-R (40)
        "quantum", "quarter", "queen", "query", "quick", "quiz", "quote", "rabbit", "raccoon", "racing",
        "radar", "radio", "raise", "random", "range", "rapid", "raven", "razor", "reason", "rebel",
        "record", "reform", "region", "regret", "regular", "relief", "remain", "remind", "remove", "render",
        "repair", "rescue", "resist", "result", "return", "reveal", "ribbon", "ripple", "ritual", "rocket",
        // S (56)
        "saddle", "safari", "sailor", "salmon", "salon", "sample", "sand", "sauce", "scale", "scatter",
        "scene", "scheme", "school", "scout", "screen", "script", "search", "season", "second", "secret",
        "section", "select", "senior", "series", "settle", "seven", "shadow", "shallow", "shift", "ship",
        "shoulder", "siege", "sight", "signal", "silent", "silver", "simple", "since", "sister", "sketch",
        "skill", "slender", "slice", "smart", "social", "solar", "solid", "south", "spider", "spirit",
        "spring", "square", "stable", "summer", "supply", "symbol",
        // T (48)
        "table", "tablet", "tackle", "talent", "target", "task", "taxi", "team", "temple", "tenant",
        "tender", "tennis", "term", "test", "theme", "theory", "three", "throw", "thumb", "ticket",
        "tiger", "timber", "tissue", "title", "toast", "today", "toilet", "token", "tomato", "tool",
        "topic", "torch", "total", "tourist", "toward", "tower", "track", "trade", "traffic", "travel",
        "tray", "trend", "trial", "trigger", "trophy", "truck", "tunnel", "turtle",
        // U-V (32)
        "ugly", "ultra", "umbrella", "unable", "uncle", "under", "unfair", "unfold", "unhappy", "uniform",
        "unique", "unit", "universe", "unlock", "until", "unusual", "update", "upper", "vacant", "valley",
        "valve", "vanish", "vapor", "vendor", "venture", "version", "vessel", "veteran", "viable", "violet",
        "virtual", "volume",
        // W-Z (32)
        "wage", "wagon", "wallet", "walnut", "wander", "warfare", "warm", "warrior", "water", "wealth",
        "weapon", "weather", "wedding", "welcome", "whale", "wheat", "whisper", "width", "wild", "window",
        "winter", "wisdom", "witness", "wonder", "world", "worth", "wrap", "yard", "year", "zebra",
        "zero", "zone",
        // Additional words to reach 1024 (≈10 bits/word)
        "abstract", "abuse", "accent", "access", "acquire", "actor", "actual", "adult", "affair", "angle",
        "angry", "ankle", "april", "arch", "arctic", "army", "arrow", "asset", "attend", "august",
        "atom", "aunt", "autumn", "avocado", "awake", "aware", "axis", "baby", "backup", "ballot",
        "bacon", "bag", "bake", "ball", "band", "bank", "bar", "barn", "base", "basic",
        "bean", "bear", "beef", "bell", "belt", "best", "betray", "bind", "bird", "bitter",
        "blade", "blame", "blast", "bleak", "blend", "blind", "block", "blood", "bloom", "blur",
        "boil", "bold", "bolt", "bomb", "bone", "book", "boost", "born", "boss", "both",
        "bowl", "brand", "brass", "breeze", "brick", "bring", "broad", "brown", "bulk", "bullet",
        "burden", "burger", "burn", "bus", "busy", "butter", "buyer", "cage", "cake", "calm",
        "camp", "canal", "cancel", "candy", "canvas", "capable", "card", "cargo", "carry", "cart",
        "case", "cash", "cast", "cave", "cement", "census", "chain", "chalk", "chaos", "cheap",
        "chest", "chief", "child", "chimney", "choice", "chunk", "civil", "claim", "clap", "claw",
        "clay", "clean", "clever", "cliff", "climb", "clip", "close", "cloth", "cloud", "clown",
        "club", "clump", "coast", "code", "coil", "coin", "come", "comic", "company", "concert",
        "conduct", "connect", "cook", "cool", "copper", "copy", "core", "corn", "correct", "cost",
        "couch", "couple", "course", "cousin", "cover", "craft", "crane", "crash", "crater", "crawl",
        "crazy", "cream", "crew", "crime", "crisp", "crop", "cross", "crowd", "cruel", "crush",
        "cry", "crystal", "cube", "culture", "cup", "curve", "cute", "cycle", "dad", "daily",
        "dance", "dark", "dash", "data", "dawn", "deal", "dear", "death", "debt", "decorate",
        "deer", "define", "defy", "degree", "delay", "delta", "denial", "dentist", "deputy", "derive",
        "desk", "dial", "dice", "diet", "differ", "dilemma", "dirt", "dish", "dismiss", "display",
        "doll", "door", "dose", "dove", "draft", "drama", "draw", "drink", "drop", "drum",
        "dry", "duck", "dumb", "duty", "eager", "earn", "east", "easy", "economy", "edge",
        "edit", "educate", "egg", "elegant", "element", "elite", "else", "embark", "emerge", "emit",
        "embody", "embrace", "employ", "empty", "enact", "enforce",
    ]
}

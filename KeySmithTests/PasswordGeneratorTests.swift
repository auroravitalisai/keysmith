import XCTest
@testable import KeySmith

final class PasswordGeneratorTests: XCTestCase {

    // MARK: - Strength Preset Length Tests

    func testPINPresetGeneratesCorrectLength() {
        let password = PasswordGenerator.generate(strength: .pin)
        XCTAssertEqual(password.count, 6, "PIN preset should generate 6-character password")
    }

    func testBasicPresetGeneratesCorrectLength() {
        let password = PasswordGenerator.generate(strength: .basic)
        XCTAssertEqual(password.count, 12, "Basic preset should generate 12-character password")
    }

    func testStrongPresetGeneratesCorrectLength() {
        let password = PasswordGenerator.generate(strength: .strong)
        XCTAssertEqual(password.count, 20, "Strong preset should generate 20-character password")
    }

    func testParanoidPresetGeneratesCorrectLength() {
        let password = PasswordGenerator.generate(strength: .paranoid)
        XCTAssertEqual(password.count, 32, "Paranoid preset should generate 32-character password")
    }

    func testPassphrasePresetGeneratesCorrectWordCount() {
        let password = PasswordGenerator.generate(strength: .passphrase)
        let words = password.split(separator: "-")
        XCTAssertEqual(words.count, 5, "Passphrase preset should generate 5 words")
    }

    // MARK: - Character Pool Filtering

    func testPINContainsOnlyDigits() {
        for _ in 0..<20 {
            let password = PasswordGenerator.generate(strength: .pin)
            XCTAssertTrue(
                password.allSatisfy { $0.isNumber },
                "PIN should contain only digits, got: \(password)"
            )
        }
    }

    func testBasicContainsNoSymbols() {
        let symbols = Set("!@#$%^&*()-_=+[]{}|;:,.<>?")
        for _ in 0..<20 {
            let password = PasswordGenerator.generate(strength: .basic)
            XCTAssertFalse(
                password.contains(where: { symbols.contains($0) }),
                "Basic preset should not contain symbols, got: \(password)"
            )
        }
    }

    func testCustomOptionsNumbersOnly() {
        var options = PasswordOptions()
        options.length = 16
        options.includeLowercase = false
        options.includeUppercase = false
        options.includeNumbers = true
        options.includeSymbols = false

        for _ in 0..<20 {
            let password = PasswordGenerator.generate(options: options)
            XCTAssertTrue(
                password.allSatisfy { $0.isNumber },
                "Numbers-only options should produce only digits, got: \(password)"
            )
        }
    }

    func testCustomOptionsLowercaseOnly() {
        var options = PasswordOptions()
        options.length = 16
        options.includeLowercase = true
        options.includeUppercase = false
        options.includeNumbers = false
        options.includeSymbols = false

        for _ in 0..<20 {
            let password = PasswordGenerator.generate(options: options)
            XCTAssertTrue(
                password.allSatisfy { $0.isLowercase },
                "Lowercase-only should produce only lowercase, got: \(password)"
            )
        }
    }

    func testCustomOptionsUppercaseOnly() {
        var options = PasswordOptions()
        options.length = 16
        options.includeLowercase = false
        options.includeUppercase = true
        options.includeNumbers = false
        options.includeSymbols = false

        for _ in 0..<20 {
            let password = PasswordGenerator.generate(options: options)
            XCTAssertTrue(
                password.allSatisfy { $0.isUppercase },
                "Uppercase-only should produce only uppercase, got: \(password)"
            )
        }
    }

    func testCustomOptionsSymbolsOnly() {
        let symbols = Set("!@#$%^&*()-_=+[]{}|;:,.<>?")
        var options = PasswordOptions()
        options.length = 16
        options.includeLowercase = false
        options.includeUppercase = false
        options.includeNumbers = false
        options.includeSymbols = true

        for _ in 0..<20 {
            let password = PasswordGenerator.generate(options: options)
            XCTAssertTrue(
                password.allSatisfy { symbols.contains($0) },
                "Symbols-only should produce only symbols, got: \(password)"
            )
        }
    }

    // MARK: - Character Category Guarantees

    func testStrongPresetContainsAllCategories() {
        let symbols = Set("!@#$%^&*()-_=+[]{}|;:,.<>?")
        // Run multiple times — guarantee logic should ensure all categories
        for _ in 0..<30 {
            let password = PasswordGenerator.generate(strength: .strong)
            XCTAssertTrue(password.contains(where: { $0.isLowercase }), "Strong should contain lowercase: \(password)")
            XCTAssertTrue(password.contains(where: { $0.isUppercase }), "Strong should contain uppercase: \(password)")
            XCTAssertTrue(password.contains(where: { $0.isNumber }), "Strong should contain number: \(password)")
            XCTAssertTrue(password.contains(where: { symbols.contains($0) }), "Strong should contain symbol: \(password)")
        }
    }

    func testParanoidPresetContainsAllCategories() {
        let symbols = Set("!@#$%^&*()-_=+[]{}|;:,.<>?")
        for _ in 0..<30 {
            let password = PasswordGenerator.generate(strength: .paranoid)
            XCTAssertTrue(password.contains(where: { $0.isLowercase }), "Paranoid should contain lowercase: \(password)")
            XCTAssertTrue(password.contains(where: { $0.isUppercase }), "Paranoid should contain uppercase: \(password)")
            XCTAssertTrue(password.contains(where: { $0.isNumber }), "Paranoid should contain number: \(password)")
            XCTAssertTrue(password.contains(where: { symbols.contains($0) }), "Paranoid should contain symbol: \(password)")
        }
    }

    func testGuaranteeWithAllCategoriesEnabled() {
        let symbols = Set("!@#$%^&*()-_=+[]{}|;:,.<>?")
        var options = PasswordOptions()
        options.length = 8 // Short password to stress the guarantee logic
        options.includeLowercase = true
        options.includeUppercase = true
        options.includeNumbers = true
        options.includeSymbols = true

        for _ in 0..<50 {
            let password = PasswordGenerator.generate(options: options)
            XCTAssertTrue(password.contains(where: { $0.isLowercase }), "Should contain lowercase: \(password)")
            XCTAssertTrue(password.contains(where: { $0.isUppercase }), "Should contain uppercase: \(password)")
            XCTAssertTrue(password.contains(where: { $0.isNumber }), "Should contain number: \(password)")
            XCTAssertTrue(password.contains(where: { symbols.contains($0) }), "Should contain symbol: \(password)")
        }
    }

    func testBasicPresetContainsLettersAndNumbers() {
        for _ in 0..<30 {
            let password = PasswordGenerator.generate(strength: .basic)
            XCTAssertTrue(password.contains(where: { $0.isLetter }), "Basic should contain letters: \(password)")
            XCTAssertTrue(password.contains(where: { $0.isNumber }), "Basic should contain numbers: \(password)")
        }
    }

    // MARK: - Passphrase Tests

    func testPassphraseWordCount() {
        for wordCount in [3, 4, 5, 6, 7, 8] {
            let passphrase = PasswordGenerator.generatePassphrase(wordCount: wordCount)
            let words = passphrase.split(separator: "-")
            XCTAssertEqual(words.count, wordCount, "Passphrase with wordCount=\(wordCount) should have \(wordCount) words")
        }
    }

    func testPassphraseMinimumWordCount() {
        // Requesting fewer than 3 words should still produce 3
        let passphrase = PasswordGenerator.generatePassphrase(wordCount: 1)
        let words = passphrase.split(separator: "-")
        XCTAssertEqual(words.count, 3, "Passphrase should have at least 3 words")
    }

    func testPassphraseCustomSeparator() {
        let passphrase = PasswordGenerator.generatePassphrase(wordCount: 4, separator: ".")
        let words = passphrase.split(separator: ".")
        XCTAssertEqual(words.count, 4, "Passphrase with dot separator should have 4 words")
    }

    func testPassphraseWordsAreFromWordList() {
        let wordSet = Set(PasswordGenerator.wordList)
        for _ in 0..<20 {
            let passphrase = PasswordGenerator.generatePassphrase(wordCount: 5)
            let words = passphrase.split(separator: "-").map(String.init)
            for word in words {
                XCTAssertTrue(wordSet.contains(word), "Word '\(word)' should be in the word list")
            }
        }
    }

    func testPassphraseWordsAreAlphabetic() {
        for _ in 0..<20 {
            let passphrase = PasswordGenerator.generatePassphrase(wordCount: 5)
            let words = passphrase.split(separator: "-")
            for word in words {
                XCTAssertTrue(word.allSatisfy { $0.isLetter }, "Passphrase word '\(word)' should be all letters")
            }
        }
    }

    // MARK: - Entropy Estimation

    func testEntropyOfEmptyStringIsZero() {
        let entropy = PasswordGenerator.estimateEntropy(password: "")
        XCTAssertEqual(entropy, 0, "Empty password should have 0 entropy")
    }

    func testEntropyIncreasesWithLength() {
        var options = PasswordOptions()
        options.includeLowercase = true
        options.includeUppercase = false
        options.includeNumbers = false
        options.includeSymbols = false

        // Lowercase-only entropy = length * log2(26)
        let shortEntropy = PasswordGenerator.estimateEntropy(password: "abcdef")
        let longEntropy = PasswordGenerator.estimateEntropy(password: "abcdefghijklmn")
        XCTAssertGreaterThan(longEntropy, shortEntropy, "Longer passwords should have more entropy")
    }

    func testEntropyIncreasesWithPoolSize() {
        // lowercase only: 8 * log2(26) ≈ 37.6
        let lowercaseEntropy = PasswordGenerator.estimateEntropy(password: "abcdefgh")
        // lowercase + uppercase: 8 * log2(52) ≈ 45.6
        let mixedEntropy = PasswordGenerator.estimateEntropy(password: "abcdEFGH")
        XCTAssertGreaterThan(mixedEntropy, lowercaseEntropy, "More character types should increase entropy")
    }

    func testEntropyForPINIsReasonable() {
        // 6-digit PIN: 6 * log2(10) ≈ 19.9 bits
        let entropy = PasswordGenerator.estimateEntropy(password: "384921")
        XCTAssertGreaterThan(entropy, 15, "6-digit PIN should have > 15 bits")
        XCTAssertLessThan(entropy, 25, "6-digit PIN should have < 25 bits")
    }

    func testEntropyForStrongPasswordIsHigh() {
        // 20-char mixed: 20 * log2(89) ≈ 129 bits
        let password = PasswordGenerator.generate(strength: .strong)
        let entropy = PasswordGenerator.estimateEntropy(password: password)
        XCTAssertGreaterThan(entropy, 80, "Strong preset should have high entropy")
    }

    func testEntropyForPassphraseIsReasonable() {
        // 5-word passphrase: 5 * log2(200) ≈ 38.2 bits
        let passphrase = PasswordGenerator.generate(strength: .passphrase)
        let entropy = PasswordGenerator.estimateEntropy(password: passphrase)
        XCTAssertGreaterThan(entropy, 30, "5-word passphrase should have > 30 bits entropy")
        XCTAssertLessThan(entropy, 60, "5-word passphrase should have < 60 bits entropy")
    }

    func testStrengthNormalizationCapsAtOne() {
        // Paranoid: 32 * log2(89) ≈ 207 bits → strength > 1.0 → capped to 1.0
        let password = PasswordGenerator.generate(strength: .paranoid)
        let strength = PasswordGenerator.estimateStrength(password: password)
        XCTAssertLessThanOrEqual(strength, 1.0, "Strength should be capped at 1.0")
        XCTAssertGreaterThanOrEqual(strength, 0.0, "Strength should be >= 0.0")
    }

    func testStrengthOfEmptyPasswordIsZero() {
        let strength = PasswordGenerator.estimateStrength(password: "")
        XCTAssertEqual(strength, 0.0, "Empty password strength should be 0.0")
    }

    // MARK: - Edge Cases

    func testGenerateWithLengthOne() {
        var options = PasswordOptions()
        options.length = 1
        options.includeLowercase = true
        options.includeUppercase = false
        options.includeNumbers = false
        options.includeSymbols = false

        let password = PasswordGenerator.generate(options: options)
        XCTAssertEqual(password.count, 1, "Length 1 should produce 1-character password")
        XCTAssertTrue(password.first!.isLowercase, "Single char from lowercase pool should be lowercase")
    }

    func testGenerateWithLengthSixtyFour() {
        var options = PasswordOptions()
        options.length = 64
        options.includeLowercase = true
        options.includeUppercase = true
        options.includeNumbers = true
        options.includeSymbols = true

        let password = PasswordGenerator.generate(options: options)
        XCTAssertEqual(password.count, 64, "Length 64 should produce 64-character password")
    }

    func testGenerateWithEmptyCharacterPoolReturnsEmpty() {
        var options = PasswordOptions()
        options.length = 16
        options.includeLowercase = false
        options.includeUppercase = false
        options.includeNumbers = false
        options.includeSymbols = false

        let password = PasswordGenerator.generate(options: options)
        XCTAssertEqual(password, "", "Empty character pool should return empty string")
    }

    // MARK: - Exclude Ambiguous Characters

    func testExcludeAmbiguousRemovesAmbiguousChars() {
        var options = PasswordOptions()
        options.excludeAmbiguous = true
        let pool = options.characterPool
        let ambiguous: Set<Character> = ["0", "O", "l", "1", "I"]
        for char in ambiguous {
            XCTAssertFalse(pool.contains(char), "Pool should not contain ambiguous char '\(char)'")
        }
    }

    func testExcludeAmbiguousStillGeneratesValidPassword() {
        var options = PasswordOptions()
        options.length = 20
        options.excludeAmbiguous = true
        let ambiguous: Set<Character> = ["0", "O", "l", "1", "I"]

        for _ in 0..<20 {
            let password = PasswordGenerator.generate(options: options)
            XCTAssertEqual(password.count, 20)
            XCTAssertFalse(password.contains(where: { ambiguous.contains($0) }), "Should not contain ambiguous chars: \(password)")
        }
    }

    // MARK: - Character Pool Composition

    func testCharacterPoolWithAllOptionsEnabled() {
        let options = PasswordOptions() // Defaults: all true except excludeAmbiguous
        let pool = options.characterPool
        XCTAssertTrue(pool.contains("a"), "Pool should contain lowercase")
        XCTAssertTrue(pool.contains("A"), "Pool should contain uppercase")
        XCTAssertTrue(pool.contains("0"), "Pool should contain numbers")
        XCTAssertTrue(pool.contains("!"), "Pool should contain symbols")
    }

    func testCharacterPoolWithOnlyNumbers() {
        var options = PasswordOptions()
        options.includeLowercase = false
        options.includeUppercase = false
        options.includeNumbers = true
        options.includeSymbols = false
        let pool = options.characterPool
        XCTAssertEqual(pool, "0123456789")
    }

    func testCharacterPoolEmptyWhenAllDisabled() {
        var options = PasswordOptions()
        options.includeLowercase = false
        options.includeUppercase = false
        options.includeNumbers = false
        options.includeSymbols = false
        XCTAssertTrue(options.characterPool.isEmpty, "Pool should be empty when all options disabled")
    }

    // MARK: - Uniqueness / Randomness Sanity

    func testGeneratedPasswordsAreNotIdentical() {
        // Generate several passwords and verify they're not all the same
        var passwords = Set<String>()
        for _ in 0..<10 {
            passwords.insert(PasswordGenerator.generate(strength: .strong))
        }
        XCTAssertGreaterThan(passwords.count, 1, "Generated passwords should not all be identical")
    }

    func testGeneratedPassphrasesAreNotIdentical() {
        var passphrases = Set<String>()
        for _ in 0..<10 {
            passphrases.insert(PasswordGenerator.generatePassphrase(wordCount: 5))
        }
        XCTAssertGreaterThan(passphrases.count, 1, "Generated passphrases should not all be identical")
    }

    // MARK: - Strength Preset Default Lengths

    func testStrengthPresetDefaultLengths() {
        XCTAssertEqual(PasswordStrength.pin.defaultLength, 6)
        XCTAssertEqual(PasswordStrength.basic.defaultLength, 12)
        XCTAssertEqual(PasswordStrength.strong.defaultLength, 20)
        XCTAssertEqual(PasswordStrength.paranoid.defaultLength, 32)
        XCTAssertEqual(PasswordStrength.passphrase.defaultLength, 5)
    }

    // MARK: - Generate with Custom Length via Options

    func testCustomLengthIsRespected() {
        for length in [4, 10, 25, 50, 64] {
            var options = PasswordOptions()
            options.length = length
            options.includeLowercase = true
            options.includeUppercase = false
            options.includeNumbers = false
            options.includeSymbols = false
            let password = PasswordGenerator.generate(options: options)
            XCTAssertEqual(password.count, length, "Password with length=\(length) should have \(length) characters")
        }
    }

    // MARK: - Word List Integrity

    func testWordListIsNotEmpty() {
        XCTAssertFalse(PasswordGenerator.wordList.isEmpty, "Word list should not be empty")
    }

    func testWordListHasExpectedSize() {
        XCTAssertEqual(PasswordGenerator.wordList.count, 200, "Word list should have 200 words")
    }

    func testWordListContainsOnlyAlphabeticWords() {
        for word in PasswordGenerator.wordList {
            XCTAssertTrue(word.allSatisfy { $0.isLetter }, "Word '\(word)' should be all letters")
            XCTAssertFalse(word.isEmpty, "Word list should not contain empty strings")
        }
    }
}

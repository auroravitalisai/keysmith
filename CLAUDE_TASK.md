# Task: Security Hardening for KeySmith

Read all Swift files in KeySmith/ and KeySmithKeyboard/ directories.
Read the security checklist at /Users/narissara/.openclaw/workspace/KeySmith-Security-Compliance-Checklist.md.

Apply these fixes:

## 1. Fix modulo bias (PasswordGenerator.swift)
Replace the current `secureRandomIndex` with rejection sampling:
```swift
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
```

## 2. Clipboard expiration (GeneratorView.swift, VaultView.swift)
Replace all `UIPasteboard.general.string = password` with:
```swift
UIPasteboard.general.setItems(
    [[UIPasteboard.typeAutomatic: password]],
    options: [.expirationDate: Date().addingTimeInterval(30)]
)
```
Remove the manual DispatchQueue clipboard clearing code.

## 3. Create PrivacyInfo.xcprivacy
Create KeySmith/PrivacyInfo.xcprivacy:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array/>
</dict>
</plist>
```

## 4. Add accessibility labels
Add .accessibilityLabel() and .accessibilityHint() to all buttons in GeneratorView and VaultView.

## 5. Passphrase mode
Add a `.passphrase` case to PasswordStrength and a `generatePassphrase(wordCount:)` method with an embedded list of 200 common words. Separator should be "-".

## After changes:
```bash
xcodegen generate
xcodebuild -project KeySmith.xcodeproj -scheme KeySmith -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | grep -E 'error:|BUILD'
```
Fix errors until BUILD SUCCEEDED, then:
```bash
git add -A && git commit -m "v3: Security hardening - rejection sampling, clipboard expiry, privacy manifest, accessibility, passphrase mode"
```

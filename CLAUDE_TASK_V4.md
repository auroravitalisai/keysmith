# Task: Polish & Testing

## 1. Unit Tests for PasswordGenerator
Create KeySmithTests/PasswordGeneratorTests.swift:
- Test each strength preset generates correct length
- Test character pool filtering works (PIN = numbers only, etc.)
- Test passphrase generates correct word count
- Test generated passwords contain at least one char from each enabled category
- Test entropy estimation returns reasonable values
- Test edge cases: length 1, length 64, empty character pool

## 2. Dark Mode Verification
Review all views and ensure:
- No hardcoded colors (use semantic colors like .primary, .secondary, Color(.systemBackground))
- All custom backgrounds use Color(.secondarySystemGroupedBackground) not hardcoded values
- Check KeyboardViewController.swift uses dynamic colors too

## 3. Edge Cases
- GeneratorView: If ALL character toggles are off, show an alert or auto-enable lowercase
- VaultView: Handle error state (show store.error if not nil)
- EditEntryView: Trim whitespace from title/username/url before saving
- PasswordStore: Handle Keychain errors gracefully (show user-friendly messages)

## 4. README.md
Create a solid README with:
- App description and features
- Screenshots placeholder section
- Privacy section (on-device only, no telemetry)
- Build instructions (requires Xcode 16+, XcodeGen)
- License: MIT

## After changes:
```bash
xcodegen generate
xcodebuild -project KeySmith.xcodeproj -scheme KeySmith -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' build 2>&1 | grep -E 'error:|BUILD'
git add -A && git commit -m "v4: Unit tests, dark mode, edge cases, README"
git push origin main
```

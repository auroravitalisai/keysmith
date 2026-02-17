# KeySmith

A privacy-first password generator and vault for iOS, with a custom keyboard extension for generating passwords anywhere.

## Features

- **Password Generator** -- Cryptographically secure passwords using `SecRandomCopyBytes` with rejection sampling to eliminate modulo bias
- **Strength Presets** -- PIN (6 digits), Basic (12 chars), Strong (20 chars), Paranoid (32 chars), and Passphrase (memorable words)
- **Passphrase Mode** -- Generate memorable passphrases from a 200-word list with customizable word count and separator
- **Password Vault** -- Save, organize, and manage passwords with categories (Login, Wi-Fi, Credit Card, Secure Note, Other)
- **Biometric Authentication** -- Face ID / Touch ID with device passcode fallback to protect the vault
- **Keychain Storage** -- All saved passwords are encrypted via the iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **Custom Keyboard** -- Generate and insert passwords directly from any app using the KeySmith keyboard extension
- **Clipboard Expiry** -- Copied passwords automatically clear from the clipboard after 30 seconds
- **Entropy Meter** -- Real-time strength visualization with bits-of-entropy calculation
- **Accessibility** -- Full VoiceOver support with labels and hints on all interactive elements

## Screenshots

<!-- Add screenshots here -->
| Generator | Vault | Keyboard |
|-----------|-------|----------|
| ![Generator](docs/screenshots/generator.png) | ![Vault](docs/screenshots/vault.png) | ![Keyboard](docs/screenshots/keyboard.png) |

## Privacy

KeySmith is designed with a zero-trust, offline-first approach:

- **On-Device Only** -- All password generation and storage happens locally. Nothing leaves your device.
- **No Telemetry** -- Zero analytics, zero tracking, zero data collection. The privacy manifest (`PrivacyInfo.xcprivacy`) declares no collected data types.
- **No Network Access** -- The app makes no network requests whatsoever.
- **Keychain Encrypted** -- Saved passwords are protected by the iOS Keychain and the Secure Enclave.
- **Clipboard Auto-Clear** -- Passwords copied to the clipboard expire automatically.

## Build Instructions

### Requirements

- Xcode 16.0+
- iOS 17.0+ deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

### Steps

```bash
# Install XcodeGen (if not already installed)
brew install xcodegen

# Clone the repository
git clone https://github.com/auroravitalisai/KeySmith.git
cd KeySmith

# Generate the Xcode project
xcodegen generate

# Open in Xcode
open KeySmith.xcodeproj

# Or build from the command line
xcodebuild -project KeySmith.xcodeproj -scheme KeySmith -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Running Tests

```bash
xcodebuild test -project KeySmith.xcodeproj -scheme KeySmith -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

- **SwiftUI** for all app views with MVVM pattern
- **UIKit** (`UIInputViewController`) for the keyboard extension
- **PasswordGenerator** -- Shared between the app and keyboard extension via source compilation
- **KeychainManager** -- Singleton managing secure read/write to the iOS Keychain
- **PasswordStore** -- `@MainActor ObservableObject` providing reactive CRUD with biometric auth gating

## License

MIT License

Copyright (c) 2025 Aurora Vitalis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

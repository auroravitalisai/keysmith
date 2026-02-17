# KeySmith v5: Glassmorphic Redesign — Master Plan

> Architect: Aurora Vitalis
> Date: 2026-02-17
> Philosophy: Security that feels premium. Simplicity that hides complexity.

---

## 1. Design System — "Liquid Glass"

### Theme Engine
Create a centralized `Theme` system. Every view pulls from this. No hardcoded colors anywhere.

```
Design/
  Theme.swift              — Color tokens, gradients, shadows, blur values
  GlassModifiers.swift     — .glassCard(), .glassButton(), .frostedBackground()
  Typography.swift          — Font scale (display, headline, body, caption, mono)
  Spacing.swift             — Consistent spacing tokens (4, 8, 12, 16, 24, 32, 48)
  AnimationTokens.swift     — Standard spring/easeInOut curves
```

### Color Palette
**Dark mode (primary):**
- Background: Deep navy/charcoal gradient (#0A0E1A → #1A1F35)
- Glass cards: White 8-12% opacity with 20pt blur
- Accent: Electric blue (#4A9EFF) with subtle glow
- Success: Emerald (#34D399)
- Warning: Amber (#FBBF24)
- Danger: Rose (#F43F5E)
- Text primary: White 90%
- Text secondary: White 55%

**Light mode:**
- Background: Soft white/light gray gradient (#F5F7FA → #E8ECF4)
- Glass cards: White 70% opacity with 10pt blur, subtle border
- Accent: Deep blue (#2563EB)
- Same semantic colors, adjusted for contrast

### Glass Card Component
```swift
// Every card in the app uses this
.background(.ultraThinMaterial)
.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
.shadow(color: .black.opacity(0.15), radius: 15, y: 8)
.overlay(
    RoundedRectangle(cornerRadius: 20, style: .continuous)
        .stroke(.white.opacity(0.1), lineWidth: 0.5)
)
```

---

## 2. Architecture Overhaul

### New File Structure
```
KeySmith/
  App/
    KeySmithApp.swift
    AppState.swift           — Global app state (locked/unlocked, onboarded, etc.)
    AppLockManager.swift     — PIN + biometric gate logic
  
  Design/
    Theme.swift
    GlassModifiers.swift
    Typography.swift
    Spacing.swift
    AnimationTokens.swift
    Components/
      GlassCard.swift
      GlassButton.swift
      GlassPINField.swift
      StrengthMeter.swift
      PasswordDisplay.swift
  
  Features/
    Onboarding/
      OnboardingView.swift
      WelcomeStep.swift
      CreatePINStep.swift
      EnableKeyboardStep.swift
    
    LockScreen/
      LockScreenView.swift   — PIN entry + Face ID button
      PINInputView.swift      — Custom PIN dots with glass styling
    
    Generator/
      GeneratorView.swift
      StrengthPresetPicker.swift
      CharacterToggleRow.swift
      LengthSlider.swift
    
    Vault/
      VaultView.swift
      VaultEntryRow.swift
      EditEntryView.swift
      SavePasswordSheet.swift
    
    Settings/
      SettingsView.swift
      SetupGuideView.swift
      SecuritySettingsView.swift
      AppearanceSettingsView.swift
  
  Models/
    PasswordGenerator.swift
    PasswordEntry.swift
  
  Services/
    KeychainManager.swift
    PasswordStore.swift
    BiometricService.swift
    HapticService.swift       — Tactile feedback on generate, copy, unlock
  
  Resources/
    PrivacyInfo.xcprivacy
```

### AppState (New — Controls Everything)
```swift
@MainActor
class AppState: ObservableObject {
    @Published var isLocked: Bool = true
    @Published var hasCompletedOnboarding: Bool = false
    @Published var hasPIN: Bool = false
    @Published var colorScheme: ColorScheme? = nil  // nil = system
    
    // App lifecycle
    func lockApp() { isLocked = true }
    func unlockApp() { isLocked = false }
    
    // Called on scenePhase change to .background
    func handleBackground() { lockApp() }
}
```

### Root View Flow
```swift
@main struct KeySmithApp: App {
    @StateObject var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !appState.hasCompletedOnboarding {
                    OnboardingView()
                } else if appState.isLocked {
                    LockScreenView()
                } else {
                    MainTabView()
                }
            }
            .environmentObject(appState)
            .onChange(of: scenePhase) { phase in
                if phase == .background { appState.handleBackground() }
            }
        }
    }
}
```

---

## 3. User Flows

### First Launch
```
[Welcome Screen]
  "KeySmith — Your passwords, your device, your rules."
  Beautiful animated key + glass effect
  [Get Started]
      ↓
[Create PIN]
  "Set a PIN to protect your vault"
  6-digit PIN with glass dot indicators
  Confirm PIN
      ↓
[Enable Face ID] (optional)
  "Use Face ID for quick access?"
  [Enable] / [Skip]
      ↓
[Enable Keyboard] (optional)
  "Enable KeySmith keyboard to generate passwords anywhere"
  [Open Settings] / [Later]
      ↓
[Ready!]
  "You're all set. Start generating."
  [Continue to App]
```

### Every Launch After
```
[Lock Screen]
  App icon + "KeySmith" 
  Face ID auto-triggers
  PIN pad with glass keys as fallback
  Subtle background animation
      ↓
[Last Used Tab]
  Generator / Vault / Settings
```

### Generate Password Flow
```
[Generator Tab]
  Glass card with password display (large, monospaced)
  Strength presets as glass pills below
  [Generate] [Copy] buttons — glass style, side by side
  Length slider with glass track
  Character toggles — minimal, tucked below
  [Save to Vault] — secondary action
```

### Copy Flow
```
Tap Copy → 
  Haptic feedback (medium impact)
  Button morphs: "Copy" → "Copied!" with checkmark
  Toast/banner: "Copied — clears in 30s"
  Password goes to clipboard with native expiration
```

---

## 4. Lock Screen Design

The lock screen IS the brand moment. It should feel like unlocking a safe.

- Dark gradient background with subtle particle/shimmer animation
- App icon centered, large, with glow effect  
- "KeySmith" in display font below
- Face ID icon pulses gently, auto-triggers on appear
- PIN pad appears if Face ID fails or user taps "Use PIN"
- PIN dots: 6 glass circles that fill with accent color
- Wrong PIN: shake animation + haptic (error)
- Correct PIN: dots pulse green → fade out → app reveals

---

## 5. Keyboard Extension Redesign

The keyboard needs to match the app's glass aesthetic. Since it's UIKit, we create glass effects programmatically:

- Dark translucent background (not opaque)
- Password display in a frosted glass card
- Strength pills match the app's design language
- Action buttons with glass styling
- Consistent corner radii (16pt for cards, 10pt for buttons)
- Same color tokens as the app

---

## 6. Security Architecture

### App Lock
- PIN stored as salted hash in Keychain (NOT plaintext)
- Max 5 failed attempts → 30s lockout → escalating delays
- Biometric unlock optional, stored as Keychain flag
- Auto-lock: immediately on background (configurable: immediately/1min/5min)

### Keychain Access Groups
- `group.com.auroravitalis.keysmith` — shared between app + keyboard
- App Groups entitlement for UserDefaults sharing (settings sync)

### Data Flow
- App writes encrypted entries → Keychain (access group)
- Keyboard reads entries → Can suggest saved passwords (v2 feature)
- No network access. Ever. PrivacyInfo.xcprivacy declares zero collection.

---

## 7. Implementation Phases

### Phase 1: Foundation (THIS TASK)
- [ ] New file structure (reorganize everything)
- [ ] Theme/Design system
- [ ] AppState + app lock flow
- [ ] Lock screen with PIN + Face ID
- [ ] Onboarding flow (3-4 screens)
- [ ] Glassmorphic GeneratorView
- [ ] Glassmorphic VaultView
- [ ] Updated Settings with security options
- [ ] App Groups + Keychain Access Groups in project.yml
- [ ] Dark + light mode full support
- [ ] Haptic feedback throughout

### Phase 2: Polish
- [ ] Keyboard extension visual refresh
- [ ] Animations and transitions
- [ ] Password health audit screen
- [ ] Widget for quick generation
- [ ] App Store screenshots with glass design

### Phase 3: Ship
- [ ] Final QA
- [ ] App Store submission
- [ ] GitHub Pages update
- [ ] Launch content (tweet, blog post)

---

## 8. Code Quality Rules

- **Zero hardcoded colors** — everything through Theme
- **Zero magic numbers** — everything through Spacing/Typography
- **Every view under 150 lines** — extract components aggressively
- **Every interactive element has accessibility labels**
- **Every state change has haptic feedback**
- **Every animation uses spring curves** (natural feel)
- **Glass modifiers are reusable** — .glassCard(), .glassButton()
- **Dark mode is primary** — design dark first, adapt for light

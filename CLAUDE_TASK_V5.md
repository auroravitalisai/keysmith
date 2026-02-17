# Task: KeySmith v5 — Native Liquid Glass Redesign (iOS 26)

## CRITICAL: Read These First
1. `REDESIGN.md` — Architecture and user flow plan
2. `LIQUID_GLASS_REFERENCE.md` — iOS 26 native Liquid Glass API reference

## Context
We have Xcode 26.2. We're targeting **iOS 26**. This means we use Apple's NATIVE `.glassEffect()` API, NOT custom glassmorphism hacks. No `.ultraThinMaterial` fake glass. The real thing.

Update `project.yml` deployment target from iOS 17 to iOS 26.

## Architecture Changes

### New File Structure
```
KeySmith/
  App/
    KeySmithApp.swift         — Root with AppState, scenePhase handling
    AppState.swift            — locked/unlocked, onboarded, colorScheme
    AppLockManager.swift      — PIN hash+salt in Keychain, attempt tracking, lockout
  
  Design/
    Theme.swift               — Color tokens, gradient backgrounds
    Typography.swift          — Font scale
    Spacing.swift             — Spacing tokens (4/8/12/16/24/32)
    HapticService.swift       — Feedback wrappers
  
  Components/
    GlassCard.swift           — Reusable glass card wrapper
    PasswordDisplay.swift     — Monospaced password text display
    StrengthMeter.swift       — Entropy bar with color
    PINInputView.swift        — 6-dot PIN entry with glass keys
  
  Features/
    Onboarding/
      OnboardingView.swift    — Welcome → Create PIN → Face ID → Keyboard
    LockScreen/
      LockScreenView.swift    — PIN + Face ID gate
    Generator/
      GeneratorView.swift     — Main generator (glass redesign)
    Vault/
      VaultView.swift
      VaultEntryRow.swift
      EditEntryView.swift
    Settings/
      SettingsView.swift
      SetupGuideView.swift
  
  Models/                     — KEEP AS-IS (PasswordGenerator, PasswordEntry)
  Services/
    KeychainManager.swift     — KEEP, add access group support
    PasswordStore.swift       — KEEP, remove auth (moved to AppLockManager)
    BiometricService.swift    — LAContext wrapper
```

### Root View Flow
```swift
@main struct KeySmithApp: App {
    @StateObject var appState = AppState()
    @Environment(\.scenePhase) var scenePhase
    
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
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    appState.lockApp()
                }
            }
        }
    }
}
```

## Step-by-Step Implementation

### Step 1: Update project.yml
- Change deploymentTarget iOS from "17.0" to "26.0"
- Add entitlements for App Groups and Keychain Access Groups
- Create .entitlements files for both targets

### Step 2: Create Design System
**Theme.swift:**
```swift
import SwiftUI

enum Theme {
    // Background gradients (content behind glass needs visual richness)
    static let darkGradient = LinearGradient(
        colors: [Color(hex: "0A0E1A"), Color(hex: "1A1F35")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let lightGradient = LinearGradient(
        colors: [Color(hex: "F5F7FA"), Color(hex: "E8ECF4")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    
    // Semantic colors
    static let success = Color.green
    static let warning = Color.orange  
    static let danger = Color.red
    static let accent = Color.blue
}

extension Color {
    init(hex: String) { /* standard hex init */ }
}
```

**Spacing.swift:**
```swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}
```

### Step 3: App Lock System
**AppLockManager.swift:**
- Store PIN as SHA256(salt + pin) in Keychain
- Generate random 16-byte salt on first PIN creation
- Track failed attempts in memory (reset on success)
- After 5 failures: 30s lockout. After 10: 5min. After 15: 30min.
- Verify PIN: hash input with stored salt, compare to stored hash
- Change PIN: verify old PIN first, then store new hash

**AppState.swift:**
```swift
@MainActor
class AppState: ObservableObject {
    @Published var isLocked = true
    @Published var hasCompletedOnboarding: Bool
    @AppStorage("selectedTab") var selectedTab: Int = 0
    
    private let lockManager = AppLockManager()
    
    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboardingComplete")
    }
    
    func lockApp() { isLocked = true }
    func unlockApp() { isLocked = false }
    func verifyPIN(_ pin: String) -> Bool { lockManager.verify(pin) }
    func setPIN(_ pin: String) { lockManager.setPIN(pin) }
    var hasPIN: Bool { lockManager.hasPIN }
}
```

### Step 4: Lock Screen
Use native Liquid Glass for the PIN pad:
```swift
struct LockScreenView: View {
    @EnvironmentObject var appState: AppState
    @State private var enteredPIN = ""
    @State private var isWrong = false
    @Namespace private var pinNamespace
    
    var body: some View {
        ZStack {
            // Rich gradient background (glass needs content behind it)
            Theme.adaptiveGradient
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.xxl) {
                // App branding
                Image(systemName: "key.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                
                Text("KeySmith")
                    .font(.largeTitle.bold())
                
                // PIN dots
                HStack(spacing: Spacing.lg) {
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(i < enteredPIN.count ? Color.accentColor : .white.opacity(0.3))
                            .frame(width: 14, height: 14)
                    }
                }
                .modifier(ShakeEffect(shakes: isWrong ? 3 : 0))
                
                // Glass number pad
                GlassEffectContainer {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: Spacing.lg) {
                        ForEach(1...9, id: \.self) { num in
                            pinButton("\(num)")
                        }
                        // Bottom row: Face ID, 0, Delete
                        pinButton(systemImage: "faceid")
                        pinButton("0")
                        pinButton(systemImage: "delete.left")
                    }
                }
                .padding(.horizontal, Spacing.xxl)
            }
        }
        .onAppear { tryBiometric() }
    }
    
    func pinButton(_ text: String) -> some View {
        Button { appendDigit(text) } label: {
            Text(text).font(.title2.bold())
                .frame(width: 72, height: 72)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}
```

### Step 5: Onboarding
4 pages using TabView with page style. Glass buttons for navigation.
- Welcome: App icon + "Your passwords, your device, your rules."
- Create PIN: PINInputView (enter + confirm)
- Face ID: Optional biometric opt-in
- Keyboard: Instructions + Open Settings button

### Step 6: Redesign GeneratorView
KEY DESIGN PRINCIPLE: Glass is for CONTROLS only. The password display, strength meter — these are CONTENT. Use glass for buttons, presets, toggles.

```swift
struct GeneratorView: View {
    var body: some View {
        ZStack {
            Theme.adaptiveGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Password display (CONTENT - no glass)
                    PasswordDisplay(text: generatedPassword)
                    
                    // Strength meter (CONTENT)
                    StrengthMeter(password: generatedPassword)
                    
                    // Action buttons (CONTROLS - use glass)
                    GlassEffectContainer {
                        HStack(spacing: Spacing.lg) {
                            Button { generate() } label: {
                                Label("Generate", systemImage: "arrow.triangle.2.circlepath")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                            .controlSize(.large)
                            
                            Button { copy() } label: {
                                Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glassProminent)
                            .tint(copied ? .green : .blue)
                            .controlSize(.large)
                        }
                    }
                    
                    // Strength presets (CONTROLS - glass pills)
                    GlassEffectContainer {
                        HStack(spacing: Spacing.sm) {
                            ForEach(PasswordStrength.allCases) { strength in
                                Button { selectStrength(strength) } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: strength.icon)
                                        Text(strength.rawValue).font(.caption.bold())
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.sm)
                                }
                                .buttonStyle(.glass)
                                .glassEffect(
                                    selectedStrength == strength 
                                        ? .regular.tint(.blue) 
                                        : .regular
                                )
                            }
                        }
                    }
                    
                    // Length + toggles in sections
                    // ...
                }
                .padding()
            }
        }
        .navigationTitle("Generator")
    }
}
```

### Step 7: Redesign VaultView
- Use native List (it gets glass treatment automatically in iOS 26)
- Entry rows with category icons
- Glass-styled search
- Lock/unlock is now handled at app level (remove from VaultView)

### Step 8: Redesign SettingsView  
- Security section: Change PIN, Face ID toggle, Auto-lock duration picker
- Appearance: System/Dark/Light
- Keyboard: Setup guide
- About: Version, dev, links
- Use native Form (auto-glass in iOS 26)

### Step 9: TabView (auto-glass)
```swift
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var store = PasswordStore()
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            Tab("Generate", systemImage: "key", value: 0) {
                NavigationStack { GeneratorView(store: store) }
            }
            Tab("Vault", systemImage: "lock.shield", value: 1) {
                NavigationStack { VaultView(store: store) }
            }
            Tab("Settings", systemImage: "gear", value: 2) {
                NavigationStack { SettingsView() }
            }
        }
    }
}
```

### Step 10: Keyboard Extension
Keep UIKit but update colors to match the new design. Use system dynamic colors. Match corner radii.

### Step 11: Entitlements
Create `KeySmith/KeySmith.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.auroravitalis.keysmith</string>
    </array>
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.auroravitalis.keysmith.shared</string>
    </array>
</dict>
</plist>
```

### Step 12: Build + Test + Commit
```bash
xcodegen generate
xcodebuild -project KeySmith.xcodeproj -scheme KeySmith -destination 'platform=iOS Simulator,name=iPhone 16,OS=26.0' build 2>&1 | tail -10
# Fix ALL errors
git add -A && git commit -m "v5: Native Liquid Glass redesign — iOS 26, app lock, onboarding, glass UI"
git push origin main
```

## Rules
- **Use native .glassEffect() API** — not .ultraThinMaterial hacks
- **Glass is for controls/navigation only** — never on content
- **Every view under 150 lines** — extract components
- **Zero hardcoded colors** — use Theme tokens
- **Haptic feedback** on generate, copy, unlock, wrong PIN
- **All interactive elements get accessibility labels**
- **Dark mode is primary** — gradient backgrounds for glass richness
- **.interactive() on all tappable glass elements**
- **NO placeholder code** — everything functional
- **Read existing Models/** carefully — keep PasswordGenerator and PasswordEntry as-is

## Priority (if constrained)
1. project.yml update (iOS 26 target)
2. AppState + AppLockManager (PIN system)
3. Lock screen (glass PIN pad)  
4. Generator redesign (glass controls)
5. Root flow (onboarding → lock → tabs)
6. Vault + Settings redesign
7. Keyboard visual refresh

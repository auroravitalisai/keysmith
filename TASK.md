# TASK: Eliminate Magic Numbers & Enforce Design Tokens

## Context
KeySmith iOS app. All design tokens live in `KeySmith/Design/`:
- `Theme.swift` — colors, gradients, semantic tokens, icon sizes
- `Spacing.swift` — spacing constants  
- `Typography.swift` — text styles
- `BrandButtonStyles.swift` — button styles for brand screens

## Rules
1. **NO magic opacity values** — use Theme tokens:
   - `.white.opacity(0.7)` → `Theme.textSecondary`
   - `.white.opacity(0.5)` → `Theme.textTertiary`
   - `.white.opacity(0.6)` → `Theme.textSecondary` (round up)
   - `.white` for text → `Theme.textPrimary`
   - `.white.opacity(0.3)` for dots → `Theme.dotInactive`

2. **NO magic font sizes** — use Theme icon size tokens:
   - `.font(.system(size: 72))` → `.font(.system(size: Theme.iconSizeHero))`
   - `.font(.system(size: 64))` → `.font(.system(size: Theme.iconSizeLarge))`
   - `.font(.system(size: 56))` → `.font(.system(size: Theme.iconSizeMedium))`
   - `.font(.system(size: 48))` → `.font(.system(size: Theme.iconSizeSmall))`

3. **NO hardcoded colors** in view files:
   - `.foregroundStyle(.white)` on brand screens → `Theme.textPrimary`
   - `Color.accentColor` → `Theme.accent`
   - `.secondary.opacity(0.3)` → `Theme.dotInactive`

4. **NO `.buttonStyle(.glass)` or `.buttonStyle(.glassProminent)` on brand screens** (onboarding, lock screen). Use `BrandButtonStyles` instead. Glass is ONLY for adaptive screens (Generator, Vault, Settings).

5. **NO `GlassEffectContainer` on brand screens** (onboarding, lock screen). Already removed from PIN pad — verify no others remain.

## Files to Check
- `KeySmith/Features/Onboarding/OnboardingView.swift`
- `KeySmith/Features/LockScreen/LockScreenView.swift`
- `KeySmith/Components/PINInputView.swift`
- `KeySmith/Features/Settings/SettingsView.swift`
- `KeySmith/Features/Settings/SetupGuideView.swift`
- `KeySmith/Features/Vault/VaultView.swift`
- `KeySmith/Features/Vault/EditEntryView.swift`
- `KeySmith/Features/Generator/GeneratorView.swift`

## DO NOT touch
- `KeySmith/Design/` files (already correct)
- `KeySmith/App/` files
- `KeySmith/Services/` files

## Verification
After changes, run:
```bash
# Should return NO results:
grep -rn "opacity(0\." KeySmith/Features/ KeySmith/Components/ --include="*.swift" | grep -v "Design/"
grep -rn "\.system(size: [0-9]" KeySmith/Features/ KeySmith/Components/ --include="*.swift"
```

Build must succeed:
```bash
xcodebuild -project KeySmith.xcodeproj -scheme KeySmith -destination 'platform=iOS Simulator,id=C340D143-E59C-404F-A469-25CE3C53D54D' build 2>&1 | tail -5
```

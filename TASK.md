# KeySmith UI Cleanup Task

## 1. Fix Button Size Inconsistency in GeneratorView

In `KeySmith/Features/Generator/GeneratorView.swift`, the `actionButtons` section:

- **Generate button** uses `.background(.ultraThinMaterial, in: Capsule())` — this is NOT glass style, it's a raw material
- **Copy button** uses `.background(Theme.accent, in: Capsule())` — solid color

Both should use consistent styling. Fix:
- Make Generate and Copy buttons the same height/width by ensuring both use `.frame(maxWidth: .infinity)` AND `.frame(height: 50)` explicitly
- Replace `.ultraThinMaterial` on Generate with `.buttonStyle(.glass)` and remove the manual background/frame/capsule — let glass handle it
- For Copy button, keep the solid gold background since it's the primary CTA, but ensure same height
- "Save to Vault" is fine with `.buttonStyle(.glass)`

## 2. Component Extraction (150-line rule)

Extract views to keep each file under ~150 lines:

### GeneratorView.swift (340 lines → split)
- Extract `PasswordDisplay` section + `StrengthMeter` → already separate? Check.
- Extract `strengthPresets` → `StrengthPresetsView.swift` in `KeySmith/Components/`
- Extract `lengthControl` + `characterOptions` → `PasswordOptionsView.swift` in `KeySmith/Components/`
- Extract `SavePasswordSheet` → `KeySmith/Components/SavePasswordSheet.swift` (it's already a separate struct, just move the file)
- Keep GeneratorView.swift with just body + action methods

### OnboardingView.swift (329 lines → split)
- Extract each onboarding page into its own view in `KeySmith/Components/`
- Keep OnboardingView as the coordinator

### SettingsView.swift (309 lines → split)  
- Extract `ChangePINView` → `KeySmith/Features/Settings/ChangePINView.swift` (separate file)
- Each section can stay as computed properties since they're small individually

### VaultView.swift (223 lines) — borderline, extract if easy
- Extract `entryRow` → `VaultEntryRow.swift` in `KeySmith/Components/`

### EditEntryView.swift (228 lines) — borderline, leave for now

## 3. Color/Style Consistency Check

- NO hardcoded colors (hex values, Color.blue, etc.) in view files — use Theme tokens
- NO `.buttonStyle(.glass)` on brand screens (onboarding, lock screen) — use `.brandPINKey` or brand button styles
- `.buttonStyle(.glass)` is FINE on adaptive screens (Generator, Vault, Settings)
- All backgrounds use either `.adaptiveGradientBackground()` (adaptive screens) or `Theme.darkGradient` (brand screens)
- Verify `.scrollContentBackground(.hidden)` is on any Form/List that uses `.adaptiveGradientBackground()`

## 4. Build Verification

After all changes, verify:
```bash
cd /Users/narissara/Developer/KeySmith
xcodebuild -project KeySmith.xcodeproj -scheme KeySmith -destination 'id=C340D143-E59C-404F-A469-25CE3C53D54D' build 2>&1 | tail -5
```

Must build clean with no errors.

## 5. Commit

```bash
git add -A && git commit -m "Component extraction + button consistency fix"
```

## Rules
- Use Theme/Spacing/Typography tokens ONLY — no magic numbers
- No hardcoded colors in view files
- Every view file under 150 lines (target, not hard limit for borderline cases)
- Swift 6.0, iOS 26, strict concurrency
- Don't break existing functionality

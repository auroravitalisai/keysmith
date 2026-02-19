# PRD: KeySmith Design Consistency — Light & Dark Mode

## Problem
The app has inconsistent colors, opaque black/grey cards, and weird hover states in dark mode. Every component must look polished and consistent in BOTH light and dark mode before App Store submission.

## Brand Identity
- **Navy Dark:** #121845
- **Navy Mid:** #233064
- **Gold Accent:** #F5B731
- **Gold on Light:** #996600 (WCAG AA on white)
- **Success:** #34D399
- **Warning:** #FBBF24
- **Danger:** #F43F5E

## Design System Rules

### Dark Mode
- **Background:** Always navy gradient (navyDark → navyMid)
- **Cards/Containers:** Liquid Glass (`.glassEffect()`) — translucent, NEVER opaque black or grey
- **Text Primary:** White
- **Text Secondary:** White 92% opacity
- **Text Tertiary:** White 65% opacity
- **Accent/Selected:** Gold #F5B731 (NOT default system blue)
- **Borders:** White 10-15% opacity
- **Navigation/Tab bars:** Navy dark with `.toolbarBackground`

### Light Mode
- **Background:** Light gradient (#F5F7FA → #E8ECF4)
- **Cards/Containers:** System grouped background or light glass material
- **Text:** System default (dark)
- **Accent/Selected:** Gold on light #996600 or system accent
- **Navigation/Tab bars:** System default

### Components Must Be Consistent
- Toggle rows
- Slider controls
- Buttons (primary gold, secondary glass)
- Cards/sections
- Navigation bars
- Tab bars
- Form sections
- Preset selector buttons (selected = gold tint, unselected = plain glass)
- Password display
- Strength meter

## Specific Issues to Fix

### 1. PasswordOptionsView.swift
- Character toggles use `.background(.regularMaterial)` — looks opaque grey in dark mode
- **Fix:** Use `.glassEffect(.regular)` on the container, or match GlassCard pattern
- Toggle tint should be gold in dark mode

### 2. StrengthPresetsView.swift  
- Selected preset uses `Theme.accent` tint which gives weird blue-ish color
- **Fix:** Selected state should use `.glassEffect(.regular.tint(Theme.gold).interactive())`
- Unselected should use `.glassEffect(.regular.interactive())`

### 3. SettingsView.swift
- Form uses system grouped background which is opaque grey in dark mode
- **Fix:** Form sections should be glass. Consider using List with .listStyle(.insetGrouped) and custom row backgrounds, or switch to ScrollView with manual sections using GlassCard
- Version shows "2.0.0" — change to "1.0.0"

### 4. VaultView.swift
- Check if vault entries use opaque backgrounds
- **Fix:** Entry rows should be glass or translucent

### 5. EditEntryView.swift
- Has GlassEffectContainer already — verify it looks correct
- Check text field backgrounds

### 6. GeneratorView.swift
- Action buttons already use GlassEffectContainer — verify
- Ensure Copy button's green success state works in both modes

### 7. Global
- All `Color(.systemBackground)` should be checked — in dark mode this is pure black, not navy
- All `.background(.regularMaterial)` should use `.glassEffect()` instead for true glass
- The accent color throughout should be gold, not system blue
- Check Assets.xcassets for AccentColor — should be set to gold

## Testing Checklist
After all fixes:
- [ ] Generator screen — dark mode: navy gradient bg, glass cards, gold accents
- [ ] Generator screen — light mode: light gradient bg, clean cards, proper contrast
- [ ] Vault screen — both modes consistent
- [ ] Settings screen — both modes, no opaque grey sections
- [ ] Lock screen — both modes
- [ ] Onboarding — both modes
- [ ] Keyboard extension — verify it wasn't broken
- [ ] Build succeeds with zero errors

## Out of Scope
- New features
- Animation changes
- Layout changes
- Only colors, materials, and glass effects

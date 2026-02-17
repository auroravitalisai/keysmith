# KeySmith Brand Colors

Extracted from the app icon. These are the CANONICAL brand colors. Use everywhere.

## Primary Palette
| Name | Hex | Usage |
|------|-----|-------|
| Navy Dark | #121845 | Background edges, darkest areas |
| Navy Mid | #233064 | Background mid-gradient |
| Navy Light | #324178 | Background center glow |
| Gold | #F5B731 | Accent, key elements, primary actions |

## Semantic Colors  
| Name | Hex | Usage |
|------|-----|-------|
| Success | #34D399 | Copied, unlocked, strong password |
| Warning | #FBBF24 | Fair password, expiring |
| Danger | #F43F5E | Weak password, wrong PIN, delete |

## Usage Rules
- Gold (#F5B731) is the PRIMARY accent color throughout the app
- Navy gradient is the background for all screens (provides richness for Liquid Glass)
- In light mode: navy becomes light gray, gold stays gold
- Glass elements tinted with gold for primary actions: `.glassEffect(.regular.tint(Theme.gold))`
- Tab bar, toolbar, buttons — all use gold as accent via `.tint(Theme.gold)`

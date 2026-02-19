# TASK: Fix Black vs Navy Background Clash

## The Problem
In dark mode, the system chrome (navigation bar, tab bar, status bar area, List/Form backgrounds) renders as pure black (#000000), while our content uses a dark navy gradient (#121845 → #233064). This creates a jarring, ugly seam between the two. It looks like two different apps stitched together.

## The Fix

### 1. Navigation Bar — Navy Background
In `MainTabView.swift` or `KeySmithApp.swift`, configure the UINavigationBarAppearance to use our navy color in dark mode:

```swift
// In init() or .onAppear of MainTabView or KeySmithApp
let navAppearance = UINavigationBarAppearance()
navAppearance.configureWithOpaqueBackground()
navAppearance.backgroundColor = UIColor(Theme.navyDark)
navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
UINavigationBar.appearance().standardAppearance = navAppearance
UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
UINavigationBar.appearance().compactAppearance = navAppearance
```

BUT — this should ONLY apply in dark mode. In light mode, use default system appearance. Check `@Environment(\.colorScheme)` or use the `appearanceMode` AppStorage.

**Better approach**: Create a ViewModifier that conditionally applies toolbar background:
```swift
.toolbarBackground(Theme.navyDark, for: .navigationBar)
.toolbarBackground(.visible, for: .navigationBar)
```

Apply this in each NavigationStack content view (GeneratorView, VaultView, SettingsView) conditionally for dark mode only.

### 2. Tab Bar — Navy Background  
Similarly for the tab bar:
```swift
.toolbarBackground(Theme.navyDark, for: .tabBar)
.toolbarBackground(.visible, for: .tabBar)
```

Apply on the TabView in MainTabView.swift, conditionally for dark mode.

### 3. List/Form Backgrounds
VaultView and SettingsView use List/Form. These have their own background. We already have `.scrollContentBackground(.hidden)` and `.adaptiveGradientBackground()` — verify these are working. The List rows themselves might still show black backgrounds. If so, add:
```swift
.listRowBackground(Color.clear)
```
to list rows, or use:
```swift
.listStyle(.plain)
```

### 4. Vault Empty State
The empty state in VaultView shows a navy card floating on black. Remove the card container — just show the content directly on the gradient background. The empty state VStack should NOT have any separate background/card — it inherits from `.adaptiveGradientBackground()`.

### 5. Light Mode
In light mode, everything should use system defaults with our light gradient. Don't apply navy toolbar backgrounds in light mode. The `.adaptiveGradientBackground()` modifier already handles the light/dark switch — toolbar backgrounds should follow the same pattern.

### Implementation Strategy

Create a new ViewModifier in `KeySmith/Design/Theme.swift`:

```swift
struct AdaptiveToolbarStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content
                .toolbarBackground(Theme.navyDark, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            content
        }
    }
}

extension View {
    func adaptiveToolbarStyle() -> some View {
        modifier(AdaptiveToolbarStyle())
    }
}
```

Apply `.adaptiveToolbarStyle()` to GeneratorView, VaultView, SettingsView.

For the tab bar, apply in MainTabView:
```swift
TabView { ... }
    .toolbarBackground(colorScheme == .dark ? Theme.navyDark : .automatic, for: .tabBar)
    .toolbarBackground(.visible, for: .tabBar)
```

### Build & Verify
```bash
xcodebuild -project KeySmith.xcodeproj -scheme KeySmith -destination 'id=C340D143-E59C-404F-A469-25CE3C53D54D' build 2>&1 | tail -5
```

### Commit
```bash
git add -A && git commit -m "Fix black vs navy background clash — unified dark mode appearance"
```

## Rules
- Theme tokens only — no hardcoded colors
- Don't break light mode
- Don't touch onboarding or lock screen (they use Theme.darkGradient always)
- Test that it builds clean

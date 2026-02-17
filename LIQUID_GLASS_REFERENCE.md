# iOS 26 Liquid Glass — Quick Reference for KeySmith

> Source: github.com/conorluddy/LiquidGlassReference

## Core APIs

### .glassEffect()
```swift
.glassEffect()                           // Default: .regular, .capsule
.glassEffect(.regular, in: .capsule)     // Explicit
.glassEffect(.regular.tint(.blue))       // Tinted
.glassEffect(.regular.interactive())     // Press/bounce/shimmer
.glassEffect(.clear)                     // High transparency (over media)
.glassEffect(.identity)                  // No effect (conditional)
```

### Button Styles
```swift
.buttonStyle(.glass)            // Secondary — translucent
.buttonStyle(.glassProminent)   // Primary — opaque, bold
.tint(.blue)                    // Color
.controlSize(.large)            // Size
.buttonBorderShape(.capsule)    // Shape
```

### GlassEffectContainer
Groups glass elements. Enables morphing. Shares sampling region.
```swift
GlassEffectContainer(spacing: 30) {
    // Glass elements morph together within spacing distance
    Button("A") { }.glassEffect(.regular.interactive())
    Button("B") { }.glassEffect(.regular.interactive())
}
```

### Morphing with glassEffectID
```swift
@Namespace private var ns

GlassEffectContainer {
    Button("Toggle") { withAnimation(.bouncy) { expanded.toggle() } }
        .glassEffect()
        .glassEffectID("toggle", in: ns)
    
    if expanded {
        Button("Action") { }
            .glassEffect()
            .glassEffectID("action", in: ns)
    }
}
```

### Shapes
```swift
.capsule           // Default
.circle
RoundedRectangle(cornerRadius: 16)
.rect(cornerRadius: .containerConcentric)  // Matches container corners
.ellipse
```

### Toolbar (auto-glass in iOS 26)
```swift
.toolbar {
    ToolbarItem(placement: .confirmationAction) {
        Button("Save") { }  // Auto gets .glassProminent
    }
}
```

### TabView (auto-glass in iOS 26)
```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab("Settings", systemImage: "gear") { SettingsView() }
}
```

## Design Rules
1. Glass is for NAVIGATION layer only (bars, buttons, controls)
2. NEVER apply glass to content (lists, tables, media, text blocks)
3. Tinting is for SEMANTIC meaning (primary action), not decoration
4. .interactive() only on tappable elements
5. Let iOS handle accessibility automatically (reduced transparency, contrast, motion)
6. Dark mode: glass adapts automatically
7. Content behind glass should have visual richness (gradients, images)

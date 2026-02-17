import SwiftUI

enum Theme {

    // MARK: - Background Gradients

    // Brand colors from app icon
    static let navyDark = Color(hex: "121845")
    static let navyMid = Color(hex: "233064")
    static let navyLight = Color(hex: "324178")
    static let gold = Color(hex: "F5B731")

    static let darkGradient = LinearGradient(
        colors: [navyDark, navyMid],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let lightGradient = LinearGradient(
        colors: [Color(hex: "F5F7FA"), Color(hex: "E8ECF4")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: - Semantic Colors

    static let success = Color(hex: "34D399")
    static let warning = Color(hex: "FBBF24")
    static let danger = Color(hex: "F43F5E")
    static let accent = gold

    // MARK: - Text on Dark Background

    /// Primary text on navy: pure white
    static let textPrimary = Color.white
    /// Secondary text on navy: clearly readable, slightly softer than primary
    static let textSecondary = Color.white.opacity(0.92)
    /// Tertiary/hint text on navy
    static let textTertiary = Color.white.opacity(0.65)

    // MARK: - Interactive Elements on Dark Background

    /// Empty PIN dot — hollow ring style for visibility
    static let dotInactive = Color.white.opacity(0.45)
    /// Filled PIN dot
    static let dotActive = gold

    // MARK: - PIN Pad Keys

    /// PIN key normal state — high contrast on navy
    static let pinKeyNormal = Color(hex: "6E7CC0")
    /// PIN key pressed state — brighter for tap feedback
    static let pinKeyPressed = Color(hex: "8B96D4")

    // MARK: - Icon Sizes (for onboarding/brand screens)

    static let iconSizeHero: CGFloat = 72
    static let iconSizeLarge: CGFloat = 64
    static let iconSizeMedium: CGFloat = 56
    static let iconSizeSmall: CGFloat = 48
}

// MARK: - Adaptive Gradient Modifier

struct AdaptiveGradientBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                Group {
                    if colorScheme == .dark {
                        Theme.darkGradient
                    } else {
                        Theme.lightGradient
                    }
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    func adaptiveGradientBackground() -> some View {
        modifier(AdaptiveGradientBackground())
    }
}

// MARK: - Hex Color Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}

import SwiftUI

// MARK: - Brand Button Styles (for screens with forced dark/navy background)

/// Primary button: gold fill, navy text
struct BrandPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Theme.navyDark)
            .padding(.vertical, Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(Theme.gold)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary button: white outline on navy, gold text
struct BrandSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Theme.gold)
            .padding(.vertical, Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// PIN pad key: circular, subtle white glass on navy
struct BrandPINKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.white)
            .font(.title2.bold())
            .background(
                Circle()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.25 : 0.1))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BrandPrimaryButtonStyle {
    static var brandPrimary: BrandPrimaryButtonStyle { .init() }
}

extension ButtonStyle where Self == BrandSecondaryButtonStyle {
    static var brandSecondary: BrandSecondaryButtonStyle { .init() }
}

extension ButtonStyle where Self == BrandPINKeyStyle {
    static var brandPINKey: BrandPINKeyStyle { .init() }
}

import SwiftUI

/// Shared PIN dots indicator used across lock screen, onboarding, and change PIN flows.
struct PINDotsView: View {
    let count: Int
    let maxDigits: Int
    var activeColor: Color = Theme.gold
    var inactiveStyle: PINDotInactiveStyle = .stroke

    enum PINDotInactiveStyle {
        case stroke
        case filled(Color)
    }

    var body: some View {
        HStack(spacing: Spacing.lg) {
            ForEach(0..<maxDigits, id: \.self) { index in
                if index < count {
                    Circle()
                        .fill(activeColor)
                        .frame(width: 16, height: 16)
                        .scaleEffect(1.1)
                        .animation(.spring(duration: 0.2), value: count)
                } else {
                    switch inactiveStyle {
                    case .stroke:
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 2.5)
                            .frame(width: 16, height: 16)
                            .animation(.spring(duration: 0.2), value: count)
                    case .filled(let color):
                        Circle()
                            .fill(color)
                            .frame(width: 14, height: 14)
                            .animation(.spring(duration: 0.2), value: count)
                    }
                }
            }
        }
        .accessibilityLabel("PIN entry, \(count) of \(maxDigits) digits entered")
    }
}

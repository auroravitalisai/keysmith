import SwiftUI

/// Displays password strength as a colored bar with entropy bits.
/// This is CONTENT — no glass effect.
struct StrengthMeter: View {
    let password: String

    private var strength: Double {
        PasswordGenerator.estimateStrength(password: password)
    }

    private var entropy: Double {
        PasswordGenerator.estimateEntropy(password: password)
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)
                        .frame(height: 6)
                    Capsule()
                        .fill(strengthColor)
                        .frame(width: geo.size.width * strength, height: 6)
                        .animation(.spring(duration: 0.3), value: strength)
                }
            }
            .frame(height: 6)

            HStack {
                Text(strengthLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(strengthColor)
                Spacer()
                Text("\(Int(entropy)) bits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Password strength: \(strengthLabel), \(Int(entropy)) bits of entropy")
    }

    private var strengthColor: Color {
        switch strength {
        case 0..<0.3: return Theme.danger
        case 0.3..<0.6: return Theme.warning
        case 0.6..<0.8: return Theme.accent
        default: return Theme.success
        }
    }

    private var strengthLabel: String {
        switch strength {
        case 0..<0.3: return "Weak"
        case 0.3..<0.6: return "Fair"
        case 0.6..<0.8: return "Strong"
        default: return "Excellent"
        }
    }
}

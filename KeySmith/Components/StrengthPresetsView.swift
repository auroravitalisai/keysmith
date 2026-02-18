import SwiftUI

struct StrengthPresetsView: View {
    @Binding var selectedStrength: PasswordStrength
    @Binding var passwordLength: Double
    var onPresetSelected: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Preset")
                .font(.headline)
                .padding(.leading, Spacing.xs)

            GlassEffectContainer(spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    ForEach(PasswordStrength.allCases) { strength in
                        Button {
                            selectedStrength = strength
                            passwordLength = Double(strength.defaultLength)
                            onPresetSelected()
                            HapticService.selection()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: strength.icon)
                                    .font(.body)
                                Text(strength.shortLabel)
                                    .font(.caption2.bold())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                        }
                        .buttonStyle(.glass)
                        .glassEffect(
                            selectedStrength == strength
                                ? .regular.tint(Theme.accent).interactive()
                                : .regular.interactive()
                        )
                        .accessibilityLabel("\(strength.rawValue) preset: \(strength.description)")
                        .accessibilityAddTraits(selectedStrength == strength ? .isSelected : [])
                    }
                }
            }
        }
    }
}

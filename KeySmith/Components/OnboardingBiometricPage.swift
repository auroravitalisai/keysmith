import SwiftUI

struct OnboardingBiometricPage: View {
    let biometricIcon: String
    let biometricName: String
    var onEnable: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            Image(systemName: biometricIcon)
                .font(.system(size: Theme.iconSizeLarge))
                .foregroundStyle(Theme.gold)

            VStack(spacing: Spacing.md) {
                Text("Quick Unlock")
                    .font(Typography.headline)

                Text("Use \(biometricName) for fast access?")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Spacing.lg) {
                Button {
                    onEnable()
                } label: {
                    Text("Enable \(biometricName)")
                        .font(.headline)
                }
                .buttonStyle(.brandPrimary)
                .accessibilityLabel("Enable \(biometricName)")
                .accessibilityHint("Use \(biometricName) for quick unlock")

                Button("Skip") {
                    onSkip()
                }
                .foregroundStyle(Theme.textSecondary)
                .accessibilityLabel("Skip biometric setup")
                .accessibilityHint("Continue without enabling \(biometricName)")
            }
            .padding(.horizontal, Spacing.xxl)

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }
}

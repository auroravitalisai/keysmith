import SwiftUI

struct OnboardingKeyboardPage: View {
    var onOpenSettings: () -> Void
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            Image(systemName: "keyboard")
                .font(.system(size: Theme.iconSizeMedium))
                .foregroundStyle(Theme.gold)

            VStack(spacing: Spacing.md) {
                Text("Keyboard Extension")
                    .font(Typography.headline)

                Text("Generate passwords anywhere with the KeySmith keyboard.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Spacing.lg) {
                Button {
                    onOpenSettings()
                } label: {
                    Label("Open Settings", systemImage: "gear")
                        .font(.headline)
                }
                .buttonStyle(.brandSecondary)

                Button {
                    onContinue()
                } label: {
                    Text("Continue to App")
                        .font(.headline)
                }
                .buttonStyle(.brandPrimary)
            }
            .padding(.horizontal, Spacing.xxl)

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }
}

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

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    setupStep(number: "1", text: "Open Settings → General → Keyboard")
                    setupStep(number: "2", text: "Tap Keyboards → Add New Keyboard")
                    setupStep(number: "3", text: "Select KeySmith")
                    setupStep(number: "4", text: "Tap KeySmith → Allow Full Access")
                }
                .padding(.top, Spacing.sm)
                .padding(.horizontal, Spacing.md)
            }

            VStack(spacing: Spacing.lg) {
                Button {
                    onOpenSettings()
                } label: {
                    Label("Open Settings", systemImage: "gear")
                        .font(.headline)
                }
                .buttonStyle(.brandSecondary)
                .accessibilityLabel("Open Settings")
                .accessibilityHint("Opens system settings to enable the KeySmith keyboard")

                Button {
                    onContinue()
                } label: {
                    Text("Continue to App")
                        .font(.headline)
                }
                .buttonStyle(.brandPrimary)
                .accessibilityLabel("Continue to App")
                .accessibilityHint("Skip keyboard setup and enter the app")
            }
            .padding(.horizontal, Spacing.xxl)

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }

    private func setupStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.gold)
                .frame(width: 20, height: 20)
                .background(Theme.gold.opacity(0.2), in: Circle())

            Text(text)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

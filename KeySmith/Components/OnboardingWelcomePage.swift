import SwiftUI

struct OnboardingWelcomePage: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: Theme.iconSizeHero))
                .foregroundStyle(Theme.gold)

            VStack(spacing: Spacing.md) {
                Text("KeySmith")
                    .font(Typography.display)
                    .foregroundStyle(Theme.textPrimary)

                Text("Your passwords, your device, your rules.")
                    .font(.title2)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Get Started")
                    .font(.headline)
            }
            .buttonStyle(.brandPrimary)
            .padding(.horizontal, Spacing.xxl)

            Spacer().frame(height: Spacing.xxl)
        }
        .padding(.horizontal, Spacing.xl)
    }
}

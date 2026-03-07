import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var pinStep: PINStep = .create
    @State private var pinMismatch = false

    enum PINStep {
        case create, confirm
    }

    var body: some View {
        ZStack {
            Theme.darkGradient
                .ignoresSafeArea()

            TabView(selection: $currentPage) {
                OnboardingWelcomePage {
                    withAnimation { currentPage = 1 }
                }.tag(0)

                createPINPage.tag(1)

                OnboardingBiometricPage(
                    biometricIcon: appState.biometricService.biometricIcon,
                    biometricName: appState.biometricService.biometricName,
                    onEnable: {
                        appState.biometricEnabled = true
                        HapticService.success()
                        withAnimation { currentPage = 3 }
                    },
                    onSkip: {
                        appState.biometricEnabled = false
                        withAnimation { currentPage = 3 }
                    }
                ).tag(2)

                OnboardingKeyboardPage(
                    onOpenSettings: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    },
                    onContinue: finishOnboarding
                ).tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    // MARK: - Create PIN Page

    private var createPINPage: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(.system(size: Theme.iconSizeSmall))
                    .foregroundStyle(Theme.gold)

                Text(pinStep == .create ? "Create a PIN" : "Confirm Your PIN")
                    .font(Typography.headline)

                Text(pinStep == .create
                     ? "Set a 6-digit PIN to protect your vault."
                     : "Enter your PIN again to confirm.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            PINDotsView(
                count: (pinStep == .create ? newPIN : confirmPIN).count,
                maxDigits: 6
            )

            PINPadView(
                onDigit: { appendPINDigit($0) },
                onDelete: { deletePINDigit() },
                keySize: 76,
                keyFont: .title.weight(.regular)
            )
            .padding(.horizontal, Spacing.lg)

            if pinMismatch {
                Text("PINs don't match. Try again.")
                    .font(.caption)
                    .foregroundStyle(Theme.danger)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - PIN Actions

    private func appendPINDigit(_ digit: String) {
        pinMismatch = false
        HapticService.light()

        switch pinStep {
        case .create:
            guard newPIN.count < 6 else { return }
            newPIN += digit
            if newPIN.count == 6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation { pinStep = .confirm }
                }
            }
        case .confirm:
            guard confirmPIN.count < 6 else { return }
            confirmPIN += digit
            if confirmPIN.count == 6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    validatePINs()
                }
            }
        }
    }

    private func deletePINDigit() {
        HapticService.light()
        switch pinStep {
        case .create:
            guard !newPIN.isEmpty else { return }
            newPIN.removeLast()
        case .confirm:
            guard !confirmPIN.isEmpty else { return }
            confirmPIN.removeLast()
        }
    }

    private func validatePINs() {
        if newPIN == confirmPIN {
            appState.setPIN(newPIN)
            HapticService.success()

            if appState.biometricService.isBiometricAvailable {
                withAnimation { currentPage = 2 }
            } else {
                withAnimation { currentPage = 3 }
            }
        } else {
            pinMismatch = true
            HapticService.error()
            confirmPIN = ""
            pinStep = .create
            newPIN = ""
        }
    }

    private func finishOnboarding() {
        HapticService.success()
        appState.completeOnboarding()
        appState.unlockApp()
    }
}

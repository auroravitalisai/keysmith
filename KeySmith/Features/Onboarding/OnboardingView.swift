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

            pinDotsView
            pinPadView

            if pinMismatch {
                Text("PINs don't match. Try again.")
                    .font(.caption)
                    .foregroundStyle(Theme.danger)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }

    private var pinDotsView: some View {
        let currentInput = pinStep == .create ? newPIN : confirmPIN

        return HStack(spacing: Spacing.lg) {
            ForEach(0..<6, id: \.self) { index in
                if index < currentInput.count {
                    Circle()
                        .fill(Theme.gold)
                        .frame(width: 16, height: 16)
                        .scaleEffect(1.1)
                        .animation(.spring(duration: 0.2), value: currentInput.count)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 2.5)
                        .frame(width: 16, height: 16)
                        .animation(.spring(duration: 0.2), value: currentInput.count)
                }
            }
        }
    }

    private var pinPadView: some View {
        let rows = [["1","2","3"],["4","5","6"],["7","8","9"],["","0","delete"]]
        return VStack(spacing: Spacing.md) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: Spacing.md) {
                    ForEach(row, id: \.self) { key in
                        onboardingKey(key)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    @ViewBuilder
    private func onboardingKey(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(width: 76, height: 76)
        } else if key == "delete" {
            Button {
                deletePINDigit()
            } label: {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .frame(width: 76, height: 76)
            }
            .buttonStyle(.brandPINKey)
            .buttonBorderShape(.circle)
        } else {
            Button {
                appendPINDigit(key)
            } label: {
                Text(key)
                    .font(.title.weight(.regular))
                    .frame(width: 76, height: 76)
            }
            .buttonStyle(.brandPINKey)
            .buttonBorderShape(.circle)
        }
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

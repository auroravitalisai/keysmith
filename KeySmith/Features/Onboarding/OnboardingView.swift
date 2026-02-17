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
                welcomePage.tag(0)
                createPINPage.tag(1)
                biometricPage.tag(2)
                keyboardPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
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
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
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

    // MARK: - Page 2: Create PIN

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
                Circle()
                    .fill(index < currentInput.count ? Theme.gold : Theme.dotInactive)
                    .frame(width: 14, height: 14)
                    .scaleEffect(index < currentInput.count ? 1.2 : 1.0)
                    .animation(.spring(duration: 0.2), value: currentInput.count)
            }
        }
    }

    private var pinPadView: some View {
        VStack(spacing: Spacing.md) {
            ForEach(numberRows, id: \.self) { row in
                HStack(spacing: Spacing.md) {
                    ForEach(row, id: \.self) { key in
                        onboardingKey(key)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var numberRows: [[String]] {
        [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["", "0", "delete"],
        ]
    }

    @ViewBuilder
    private func onboardingKey(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(width: 64, height: 64)
        } else if key == "delete" {
            Button {
                deletePINDigit()
            } label: {
                Image(systemName: "delete.left")
                    .font(.title3)
                    .frame(width: 64, height: 64)
            }
            .buttonStyle(.brandPINKey)
            .buttonBorderShape(.circle)
        } else {
            Button {
                appendPINDigit(key)
            } label: {
                Text(key)
                    .font(.title3.bold())
                    .frame(width: 64, height: 64)
            }
            .buttonStyle(.brandPINKey)
            .buttonBorderShape(.circle)
        }
    }

    // MARK: - Page 3: Biometric

    private var biometricPage: some View {
        VStack(spacing: Spacing.xxl) {
            Spacer()

            Image(systemName: appState.biometricService.biometricIcon)
                .font(.system(size: Theme.iconSizeLarge))
                .foregroundStyle(Theme.gold)

            VStack(spacing: Spacing.md) {
                Text("Quick Unlock")
                    .font(Typography.headline)

                Text("Use \(appState.biometricService.biometricName) for fast access?")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: Spacing.lg) {
                Button {
                    appState.biometricEnabled = true
                    HapticService.success()
                    withAnimation { currentPage = 3 }
                } label: {
                    Text("Enable \(appState.biometricService.biometricName)")
                        .font(.headline)
                }
                .buttonStyle(.brandPrimary)

                Button("Skip") {
                    appState.biometricEnabled = false
                    withAnimation { currentPage = 3 }
                }
                .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, Spacing.xxl)

            Spacer()
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Page 4: Keyboard

    private var keyboardPage: some View {
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
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gear")
                        .font(.headline)
                }
                .buttonStyle(.brandSecondary)

                Button {
                    finishOnboarding()
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

    // MARK: - Adaptive Gradient

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

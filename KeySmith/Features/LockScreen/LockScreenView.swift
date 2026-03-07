import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject var appState: AppState
    @State private var enteredPIN = ""
    @State private var isWrong = false
    @State private var showPINPad = false

    var body: some View {
        ZStack {
            Theme.darkGradient
                .ignoresSafeArea()

            VStack(spacing: Spacing.xxl) {
                Spacer()

                branding

                pinDots

                if showPINPad {
                    pinPad
                } else {
                    biometricPrompt
                }

                if appState.lockManager.isLockedOut {
                    lockoutNotice
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.xl)
        }
        .onAppear { attemptBiometric() }
    }

    // MARK: - Branding

    private var branding: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "key.fill")
                .font(.system(size: Theme.iconSizeSmall))
                .foregroundStyle(Theme.gold)

            Text("KeySmith")
                .font(Typography.display)
        }
    }

    // MARK: - PIN Dots

    private var pinDots: some View {
        PINDotsView(count: enteredPIN.count, maxDigits: 6)
            .modifier(ShakeEffect(shakes: isWrong ? 3 : 0))
            .animation(.spring(duration: 0.4), value: isWrong)
    }

    // MARK: - PIN Pad

    private var pinPad: some View {
        PINPadView(
            onDigit: { appendDigit($0) },
            onDelete: {
                guard !enteredPIN.isEmpty else { return }
                enteredPIN.removeLast()
                HapticService.light()
            },
            keySize: 76,
            extraLeadingKey: appState.biometricEnabled
                ? .biometric(icon: appState.biometricService.biometricIcon, action: attemptBiometric)
                : .empty
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Biometric

    private var biometricPrompt: some View {
        VStack(spacing: Spacing.lg) {
            if appState.biometricEnabled {
                Button {
                    attemptBiometric()
                } label: {
                    Label(appState.biometricService.biometricName, systemImage: appState.biometricService.biometricIcon)
                        .font(.headline)
                }
                .buttonStyle(.brandSecondary)
                .padding(.horizontal, Spacing.xxl)
            }

            Button("Use PIN") {
                withAnimation(.spring(duration: 0.3)) {
                    showPINPad = true
                }
            }
            .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Lockout

    private var lockoutNotice: some View {
        Text("Too many attempts. Try again in \(appState.lockManager.lockoutRemainingSeconds)s")
            .font(.caption)
            .foregroundStyle(Theme.danger)
            .multilineTextAlignment(.center)
    }

    // MARK: - Adaptive Gradient

    // MARK: - Actions

    private func appendDigit(_ digit: String) {
        guard enteredPIN.count < 6, !appState.lockManager.isLockedOut else { return }
        enteredPIN += digit
        HapticService.light()

        if enteredPIN.count == 6 {
            verifyPIN()
        }
    }

    private func verifyPIN() {
        if appState.verifyPIN(enteredPIN) {
            HapticService.success()
            appState.unlockApp()
        } else {
            HapticService.error()
            isWrong = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isWrong = false
                enteredPIN = ""
            }
        }
    }

    private func attemptBiometric() {
        Task {
            let success = await appState.attemptBiometricUnlock()
            if success {
                HapticService.success()
            } else {
                withAnimation(.spring(duration: 0.3)) {
                    showPINPad = true
                }
            }
        }
    }
}

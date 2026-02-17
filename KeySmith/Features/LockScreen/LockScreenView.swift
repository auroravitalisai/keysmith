import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject var appState: AppState
    @State private var enteredPIN = ""
    @State private var isWrong = false
    @State private var showPINPad = false

    var body: some View {
        ZStack {
            adaptiveGradient
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
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("KeySmith")
                .font(Typography.display)
        }
    }

    // MARK: - PIN Dots

    private var pinDots: some View {
        HStack(spacing: Spacing.lg) {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(index < enteredPIN.count ? Color.accentColor : .secondary.opacity(0.3))
                    .frame(width: 14, height: 14)
                    .scaleEffect(index < enteredPIN.count ? 1.2 : 1.0)
                    .animation(.spring(duration: 0.2), value: enteredPIN.count)
            }
        }
        .modifier(ShakeEffect(shakes: isWrong ? 3 : 0))
        .animation(.spring(duration: 0.4), value: isWrong)
    }

    // MARK: - PIN Pad

    private var pinPad: some View {
        GlassEffectContainer(spacing: Spacing.sm) {
            VStack(spacing: Spacing.md) {
                ForEach(numberRows, id: \.self) { row in
                    HStack(spacing: Spacing.md) {
                        ForEach(row, id: \.self) { key in
                            pinKey(key)
                        }
                    }
                }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var numberRows: [[String]] {
        [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["biometric", "0", "delete"],
        ]
    }

    @ViewBuilder
    private func pinKey(_ key: String) -> some View {
        if key == "biometric" {
            if appState.biometricEnabled {
                Button { attemptBiometric() } label: {
                    Image(systemName: appState.biometricService.biometricIcon)
                        .font(.title2)
                        .frame(width: 72, height: 72)
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .accessibilityLabel(appState.biometricService.biometricName)
            } else {
                Color.clear.frame(width: 72, height: 72)
            }
        } else if key == "delete" {
            Button {
                guard !enteredPIN.isEmpty else { return }
                enteredPIN.removeLast()
                HapticService.light()
            } label: {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .frame(width: 72, height: 72)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Delete")
        } else {
            Button { appendDigit(key) } label: {
                Text(key)
                    .font(.title2.bold())
                    .frame(width: 72, height: 72)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(key)
        }
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
                .buttonStyle(.glass)
                .controlSize(.large)
            }

            Button("Use PIN") {
                withAnimation(.spring(duration: 0.3)) {
                    showPINPad = true
                }
            }
            .foregroundStyle(.secondary)
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

    @Environment(\.colorScheme) private var colorScheme

    private var adaptiveGradient: some View {
        Group {
            if colorScheme == .dark {
                Theme.darkGradient
            } else {
                Theme.lightGradient
            }
        }
    }

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

import SwiftUI

struct GeneratorView: View {
    @ObservedObject var store: PasswordStore

    @State private var generatedPassword = ""
    @State private var selectedStrength: PasswordStrength = .strong
    @State private var passwordLength: Double = 20
    @State private var includeUppercase = true
    @State private var includeLowercase = true
    @State private var includeNumbers = true
    @State private var includeSymbols = true
    @State private var copied = false
    @State private var showSaveSheet = false
    @State private var showEmptyPoolAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                PasswordDisplay(text: generatedPassword) { copyPassword() }

                if !generatedPassword.isEmpty {
                    StrengthMeter(password: generatedPassword)
                }

                actionButtons

                StrengthPresetsView(
                    selectedStrength: $selectedStrength,
                    passwordLength: $passwordLength
                ) {
                    applyStrengthPreset(selectedStrength)
                    generateNewPassword()
                }

                PasswordOptionsView(
                    passwordLength: $passwordLength,
                    includeUppercase: $includeUppercase,
                    includeLowercase: $includeLowercase,
                    includeNumbers: $includeNumbers,
                    includeSymbols: $includeSymbols,
                    onOptionChanged: generateNewPassword
                )
            }
            .padding()
        }
        .adaptiveGradientBackground()
        .navigationTitle("Generator")
        .onAppear { generateNewPassword() }
        .sheet(isPresented: $showSaveSheet) {
            SavePasswordSheet(password: generatedPassword, store: store)
        }
        .alert("No Characters Selected", isPresented: $showEmptyPoolAlert) {
            Button("OK") {
                includeLowercase = true
                generateNewPassword()
            }
        } message: {
            Text("At least one character type must be enabled. Lowercase has been re-enabled.")
        }
    }

    // MARK: - Action Buttons (CONTROLS — glass)

    private var actionButtons: some View {
        VStack(spacing: Spacing.md) {
            GlassEffectContainer(spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            generateNewPassword()
                        }
                        HapticService.medium()
                    } label: {
                        Label("Generate", systemImage: "arrow.triangle.2.circlepath")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Generate new password")

                    Button {
                        copyPassword()
                    } label: {
                        Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                            .font(.headline)
                            .foregroundStyle(Theme.navyDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(copied ? Theme.success : Theme.accent, in: Capsule())
                    }
                    .accessibilityLabel(copied ? "Password copied" : "Copy password")
                }
            }

            Button {
                showSaveSheet = true
            } label: {
                Label("Save to Vault", systemImage: "square.and.arrow.down")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.regular)
            .accessibilityLabel("Save to vault")
        }
    }

    // MARK: - Actions

    private func generateNewPassword() {
        if selectedStrength == .passphrase {
            generatedPassword = PasswordGenerator.generatePassphrase(wordCount: Int(passwordLength))
        } else {
            if !includeUppercase && !includeLowercase && !includeNumbers && !includeSymbols {
                showEmptyPoolAlert = true
                return
            }
            var options = PasswordOptions()
            options.length = Int(passwordLength)
            options.includeUppercase = includeUppercase
            options.includeLowercase = includeLowercase
            options.includeNumbers = includeNumbers
            options.includeSymbols = includeSymbols
            generatedPassword = PasswordGenerator.generate(options: options)
        }
        copied = false
    }

    private func copyPassword() {
        guard !generatedPassword.isEmpty else { return }
        UIPasteboard.general.setItems(
            [[UIPasteboard.typeAutomatic: generatedPassword]],
            options: [.expirationDate: Date().addingTimeInterval(30)]
        )
        HapticService.medium()
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }

    private func applyStrengthPreset(_ strength: PasswordStrength) {
        switch strength {
        case .pin:
            includeUppercase = false
            includeLowercase = false
            includeNumbers = true
            includeSymbols = false
        case .basic:
            includeUppercase = true
            includeLowercase = true
            includeNumbers = true
            includeSymbols = false
        case .strong, .paranoid:
            includeUppercase = true
            includeLowercase = true
            includeNumbers = true
            includeSymbols = true
        case .passphrase:
            break
        }
    }
}

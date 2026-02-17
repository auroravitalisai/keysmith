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
                passwordDisplay
                strengthMeter
                actionButtons
                strengthPresets
                lengthControl
                characterOptions
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

    // MARK: - Password Display (CONTENT — no glass)

    private var passwordDisplay: some View {
        PasswordDisplay(text: generatedPassword) {
            copyPassword()
        }
    }

    // MARK: - Strength Meter (CONTENT — no glass)

    private var strengthMeter: some View {
        Group {
            if !generatedPassword.isEmpty {
                StrengthMeter(password: generatedPassword)
            }
        }
    }

    // MARK: - Action Buttons (CONTROLS — glass)

    private var actionButtons: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                Button {
                    withAnimation(.spring(duration: 0.2)) {
                        generateNewPassword()
                    }
                    HapticService.medium()
                } label: {
                    Label("Generate", systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .accessibilityLabel("Generate new password")

                Button {
                    copyPassword()
                } label: {
                    Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.headline)
                        .foregroundStyle(Theme.navyDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(copied ? Theme.success : Theme.accent, in: Capsule())
                }
                .accessibilityLabel(copied ? "Password copied" : "Copy password")
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

    // MARK: - Strength Presets (CONTROLS — glass)

    private var strengthPresets: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Preset")
                .font(.headline)
                .padding(.leading, Spacing.xs)

            GlassEffectContainer(spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    ForEach(PasswordStrength.allCases) { strength in
                        Button {
                            selectedStrength = strength
                            passwordLength = Double(strength.defaultLength)
                            applyStrengthPreset(strength)
                            generateNewPassword()
                            HapticService.selection()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: strength.icon)
                                    .font(.body)
                                Text(strength.shortLabel)
                                    .font(.caption2.bold())
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                        }
                        .buttonStyle(.glass)
                        .glassEffect(
                            selectedStrength == strength
                                ? .regular.tint(Theme.accent).interactive()
                                : .regular.interactive()
                        )
                        .accessibilityLabel("\(strength.rawValue) preset: \(strength.description)")
                        .accessibilityAddTraits(selectedStrength == strength ? .isSelected : [])
                    }
                }
            }
        }
    }

    // MARK: - Length Control

    private var lengthControl: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Length")
                    .font(.headline)
                Spacer()
                Text("\(Int(passwordLength))")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.tint)
            }
            .padding(.horizontal, Spacing.xs)

            Slider(value: $passwordLength, in: 4...64, step: 1) {
                Text("Length")
            } onEditingChanged: { editing in
                if !editing { generateNewPassword() }
            }
            .tint(.accentColor)
            .accessibilityLabel("Password length")
            .accessibilityValue("\(Int(passwordLength)) characters")
        }
    }

    // MARK: - Character Options

    private var characterOptions: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Characters")
                .font(.headline)
                .padding(.leading, Spacing.xs)

            VStack(spacing: 0) {
                toggleRow("ABC", "Uppercase", $includeUppercase)
                Divider().padding(.leading, 44)
                toggleRow("abc", "Lowercase", $includeLowercase)
                Divider().padding(.leading, 44)
                toggleRow("123", "Numbers", $includeNumbers)
                Divider().padding(.leading, 44)
                toggleRow("#$%", "Symbols", $includeSymbols)
            }
            .padding(Spacing.xs)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func toggleRow(_ icon: String, _ label: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: Spacing.md) {
                Text(icon)
                    .font(Typography.monoSmall)
                    .frame(width: 32)
                Text(label)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .onChange(of: isOn.wrappedValue) {
            generateNewPassword()
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

// MARK: - Save Password Sheet

struct SavePasswordSheet: View {
    let password: String
    @ObservedObject var store: PasswordStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var username = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var category: PasswordEntry.Category = .login

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title (e.g. Gmail)", text: $title)
                    TextField("Username / Email", text: $username)
                    TextField("Website URL", text: $url)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }

                Section("Password") {
                    Text(password)
                        .font(Typography.mono)
                        .foregroundStyle(.secondary)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(PasswordEntry.Category.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Save Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = PasswordEntry(
                            title: title.isEmpty ? "Untitled" : title,
                            username: username,
                            password: password,
                            url: url,
                            notes: notes,
                            category: category
                        )
                        store.addEntry(entry)
                        HapticService.success()
                        dismiss()
                    }
                    .disabled(title.isEmpty && username.isEmpty)
                }
            }
        }
    }
}

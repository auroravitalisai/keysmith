import SwiftUI

struct GeneratorView: View {
    @ObservedObject var store: PasswordStore
    
    @State private var generatedPassword: String = ""
    @State private var selectedStrength: PasswordStrength = .strong
    @State private var passwordLength: Double = 20
    @State private var includeUppercase = true
    @State private var includeLowercase = true
    @State private var includeNumbers = true
    @State private var includeSymbols = true
    @State private var copied = false
    @State private var showSaveSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Password display card
                    passwordCard
                    
                    // Generate + Copy buttons side by side
                    actionButtons
                    
                    // Strength presets
                    strengthPicker
                    
                    // Length control
                    lengthControl
                    
                    // Character toggles
                    characterOptions
                }
                .padding()
            }
            .navigationTitle("Generator")
            .background(Color(.systemGroupedBackground))
            .onAppear { generateNewPassword() }
            .sheet(isPresented: $showSaveSheet) {
                SavePasswordSheet(
                    password: generatedPassword,
                    store: store
                )
            }
        }
    }
    
    // MARK: - Password Display
    
    private var passwordCard: some View {
        VStack(spacing: 12) {
            Text(generatedPassword.isEmpty ? "Tap Generate" : generatedPassword)
                .font(.system(.title3, design: .monospaced))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 80)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .contentShape(Rectangle())
                .onTapGesture { copyPassword() }
            
            // Strength meter
            if !generatedPassword.isEmpty {
                strengthMeter
            }
        }
    }
    
    private var strengthMeter: some View {
        let strength = PasswordGenerator.estimateStrength(password: generatedPassword)
        let entropy = PasswordGenerator.estimateEntropy(password: generatedPassword)
        
        return VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    Capsule()
                        .fill(strengthColor(strength))
                        .frame(width: geo.size.width * strength, height: 6)
                }
            }
            .frame(height: 6)
            
            HStack {
                Text(strengthLabel(strength))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(strengthColor(strength))
                Spacer()
                Text("\(Int(entropy)) bits")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Action Buttons (Generate + Copy side by side)
    
    private var actionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Generate button
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        generateNewPassword()
                    }
                } label: {
                    Label("Generate", systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                
                // Copy button
                Button {
                    copyPassword()
                } label: {
                    Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(copied ? .green : .orange)
            }
            
            // Save to vault button (secondary)
            Button {
                showSaveSheet = true
            } label: {
                Label("Save to Vault", systemImage: "square.and.arrow.down")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Strength Picker
    
    private var strengthPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preset")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(PasswordStrength.allCases) { strength in
                    Button {
                        selectedStrength = strength
                        passwordLength = Double(strength.defaultLength)
                        applyStrengthPreset(strength)
                        generateNewPassword()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: strength.icon)
                                .font(.body)
                            Text(strength.rawValue)
                                .font(.caption.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedStrength == strength ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(selectedStrength == strength ? .white : .primary)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Length
    
    private var lengthControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Length")
                    .font(.headline)
                Spacer()
                Text("\(Int(passwordLength))")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Color.accentColor)
            }
            
            Slider(value: $passwordLength, in: 4...64, step: 1) {
                Text("Length")
            } onEditingChanged: { editing in
                if !editing { generateNewPassword() }
            }
            .tint(.accentColor)
        }
    }
    
    // MARK: - Character Options
    
    private var characterOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Characters")
                .font(.headline)
            
            VStack(spacing: 0) {
                toggleRow("ABC", "Uppercase", $includeUppercase)
                Divider().padding(.leading, 44)
                toggleRow("abc", "Lowercase", $includeLowercase)
                Divider().padding(.leading, 44)
                toggleRow("123", "Numbers", $includeNumbers)
                Divider().padding(.leading, 44)
                toggleRow("#$%", "Symbols", $includeSymbols)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private func toggleRow(_ icon: String, _ label: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(.subheadline, design: .monospaced))
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
        var options = PasswordOptions()
        options.length = Int(passwordLength)
        options.includeUppercase = includeUppercase
        options.includeLowercase = includeLowercase
        options.includeNumbers = includeNumbers
        options.includeSymbols = includeSymbols
        generatedPassword = PasswordGenerator.generate(options: options)
        copied = false
    }
    
    private func copyPassword() {
        UIPasteboard.general.string = generatedPassword
        // Auto-clear clipboard after 30 seconds for security
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if UIPasteboard.general.string == self.generatedPassword {
                UIPasteboard.general.string = ""
            }
        }
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
        }
    }
    
    private func strengthColor(_ value: Double) -> Color {
        switch value {
        case 0..<0.3: return .red
        case 0.3..<0.6: return .orange
        case 0.6..<0.8: return .yellow
        default: return .green
        }
    }
    
    private func strengthLabel(_ value: Double) -> String {
        switch value {
        case 0..<0.3: return "Weak"
        case 0.3..<0.6: return "Fair"
        case 0.6..<0.8: return "Strong"
        default: return "Excellent"
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
                        .font(.system(.body, design: .monospaced))
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
                        dismiss()
                    }
                    .disabled(title.isEmpty && username.isEmpty)
                }
            }
        }
    }
}

#Preview {
    GeneratorView(store: PasswordStore())
}

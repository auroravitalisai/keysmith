import SwiftUI

struct ContentView: View {
    @State private var generatedPassword: String = ""
    @State private var selectedStrength: PasswordStrength = .strong
    @State private var passwordLength: Double = 20
    @State private var copied = false
    @State private var includeUppercase = true
    @State private var includeLowercase = true
    @State private var includeNumbers = true
    @State private var includeSymbols = true
    @State private var showSetupGuide = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Setup banner
                    setupBanner
                    
                    // Password display
                    passwordDisplay
                    
                    // Strength picker
                    strengthPicker
                    
                    // Length slider
                    lengthControl
                    
                    // Character options
                    characterOptions
                    
                    // Generate button
                    generateButton
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("KeySmith")
            .background(Color(.systemGroupedBackground))
            .onAppear {
                generateNewPassword()
            }
        }
    }
    
    // MARK: - Components
    
    private var setupBanner: some View {
        Button {
            showSetupGuide = true
        } label: {
            HStack {
                Image(systemName: "keyboard")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Enable Keyboard")
                        .font(.headline)
                    Text("Tap to set up KeySmith keyboard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSetupGuide) {
            SetupGuideView()
        }
    }
    
    private var passwordDisplay: some View {
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
                .onTapGesture {
                    copyPassword()
                }
            
            // Strength meter
            if !generatedPassword.isEmpty {
                let strength = PasswordGenerator.estimateStrength(password: generatedPassword)
                VStack(spacing: 4) {
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
                    
                    Text(strengthLabel(strength))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Copy button
            Button {
                copyPassword()
            } label: {
                Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            .tint(copied ? .green : .accentColor)
        }
    }
    
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
                            Text(strength.rawValue)
                                .font(.subheadline.weight(.semibold))
                            Text(strength.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
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
    
    private var lengthControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Length")
                    .font(.headline)
                Spacer()
                Text("\(Int(passwordLength))")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            Slider(value: $passwordLength, in: 4...64, step: 1) {
                Text("Length")
            } onEditingChanged: { editing in
                if !editing {
                    generateNewPassword()
                }
            }
            .tint(.accentColor)
        }
    }
    
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
    
    private var generateButton: some View {
        Button {
            generateNewPassword()
        } label: {
            Label("Generate", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
    
    // MARK: - Actions
    
    private func generateNewPassword() {
        var options = PasswordOptions()
        options.length = Int(passwordLength)
        options.includeUppercase = includeUppercase
        options.includeLowercase = includeLowercase
        options.includeNumbers = includeNumbers
        options.includeSymbols = includeSymbols
        
        withAnimation(.easeInOut(duration: 0.2)) {
            generatedPassword = PasswordGenerator.generate(options: options)
        }
        copied = false
    }
    
    private func copyPassword() {
        UIPasteboard.general.string = generatedPassword
        withAnimation {
            copied = true
        }
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

#Preview {
    ContentView()
}

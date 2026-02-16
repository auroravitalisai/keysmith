import SwiftUI

struct EditEntryView: View {
    @ObservedObject var store: PasswordStore
    let entry: PasswordEntry?
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var url: String = ""
    @State private var notes: String = ""
    @State private var category: PasswordEntry.Category = .login
    @State private var showPassword: Bool = false
    @State private var showGenerator: Bool = false
    
    var isEditing: Bool { entry != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Username / Email", text: $username)
                        .textInputAutocapitalization(.never)
                        .textContentType(.username)
                    TextField("Website URL", text: $url)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                }
                
                Section("Password") {
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                                .font(.system(.body, design: .monospaced))
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Password", text: $password)
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !password.isEmpty {
                        let strength = PasswordGenerator.estimateStrength(password: password)
                        HStack {
                            Capsule()
                                .fill(strengthColor(strength))
                                .frame(height: 4)
                            Text(strengthLabel(strength))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        showGenerator = true
                    } label: {
                        Label("Generate Password", systemImage: "wand.and.stars")
                    }
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
                        .frame(minHeight: 80)
                }
                
                if isEditing {
                    Section {
                        if let entry = entry {
                            LabeledContent("Created", value: entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                            LabeledContent("Modified", value: entry.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Password" : "New Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let entry = entry {
                    title = entry.title
                    username = entry.username
                    password = entry.password
                    url = entry.url
                    notes = entry.notes
                    category = entry.category
                }
            }
            .sheet(isPresented: $showGenerator) {
                QuickGeneratorSheet(password: $password)
            }
        }
    }
    
    private func saveEntry() {
        if var existing = entry {
            existing.title = title
            existing.username = username
            existing.password = password
            existing.url = url
            existing.notes = notes
            existing.category = category
            store.updateEntry(existing)
        } else {
            let newEntry = PasswordEntry(
                title: title,
                username: username,
                password: password,
                url: url,
                notes: notes,
                category: category
            )
            store.addEntry(newEntry)
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

// MARK: - Quick Generator Sheet

struct QuickGeneratorSheet: View {
    @Binding var password: String
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedStrength: PasswordStrength = .strong
    @State private var preview: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(preview)
                    .font(.system(.title3, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                
                HStack(spacing: 8) {
                    ForEach(PasswordStrength.allCases) { strength in
                        Button {
                            selectedStrength = strength
                            regenerate()
                        } label: {
                            Text(strength.rawValue)
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedStrength == strength ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                                .foregroundStyle(selectedStrength == strength ? .white : .primary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                HStack(spacing: 12) {
                    Button {
                        regenerate()
                    } label: {
                        Label("Regenerate", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        password = preview
                        dismiss()
                    } label: {
                        Label("Use This", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Generate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { regenerate() }
        }
    }
    
    private func regenerate() {
        preview = PasswordGenerator.generate(strength: selectedStrength)
    }
}

#Preview {
    EditEntryView(store: PasswordStore(), entry: nil)
}

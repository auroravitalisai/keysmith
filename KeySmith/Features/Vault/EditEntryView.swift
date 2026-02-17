import SwiftUI

struct EditEntryView: View {
    @ObservedObject var store: PasswordStore
    let entry: PasswordEntry?
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var username = ""
    @State private var password = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var category: PasswordEntry.Category = .login
    @State private var showPassword = false
    @State private var showGenerator = false

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
                                .font(Typography.mono)
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("Password", text: $password)
                                .font(Typography.mono)
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
                        StrengthMeter(password: password)
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

                if isEditing, let entry {
                    Section {
                        LabeledContent("Created", value: entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Modified", value: entry.modifiedAt.formatted(date: .abbreviated, time: .shortened))
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
                        HapticService.success()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let entry {
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
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        let trimmedURL = url.trimmingCharacters(in: .whitespaces)

        if var existing = entry {
            existing.title = trimmedTitle
            existing.username = trimmedUsername
            existing.password = password
            existing.url = trimmedURL
            existing.notes = notes
            existing.category = category
            store.updateEntry(existing)
        } else {
            let newEntry = PasswordEntry(
                title: trimmedTitle,
                username: trimmedUsername,
                password: password,
                url: trimmedURL,
                notes: notes,
                category: category
            )
            store.addEntry(newEntry)
        }
    }
}

// MARK: - Quick Generator Sheet

struct QuickGeneratorSheet: View {
    @Binding var password: String
    @Environment(\.dismiss) var dismiss

    @State private var selectedStrength: PasswordStrength = .strong
    @State private var preview = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Text(preview)
                    .font(Typography.monoLarge)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity, minHeight: 60)

                GlassEffectContainer(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(PasswordStrength.allCases) { strength in
                            Button {
                                selectedStrength = strength
                                regenerate()
                                HapticService.selection()
                            } label: {
                                Text(strength.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.glass)
                            .glassEffect(
                                selectedStrength == strength
                                    ? .regular.tint(Theme.gold).interactive()
                                    : .regular.interactive()
                            )
                        }
                    }
                }

                GlassEffectContainer(spacing: Spacing.md) {
                    HStack(spacing: Spacing.md) {
                        Button {
                            regenerate()
                            HapticService.medium()
                        } label: {
                            Label("Regenerate", systemImage: "arrow.triangle.2.circlepath")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.large)

                        Button {
                            password = preview
                            HapticService.success()
                            dismiss()
                        } label: {
                            Label("Use This", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Theme.gold)
                        .controlSize(.large)
                    }
                }

                Spacer()
            }
            .padding()
            .adaptiveGradientBackground()
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

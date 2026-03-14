import SwiftUI

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
                        .accessibilityLabel("Title")
                        .accessibilityHint("Enter a name for this password entry")
                    TextField("Username / Email", text: $username)
                        .accessibilityLabel("Username or Email")
                    TextField("Website URL", text: $url)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .accessibilityLabel("Website URL")
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
                    .accessibilityLabel("Category")
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                        .accessibilityLabel("Notes")
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

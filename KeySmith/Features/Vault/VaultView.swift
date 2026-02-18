import SwiftUI

struct VaultView: View {
    @ObservedObject var store: PasswordStore
    @State private var showAddSheet = false
    @State private var selectedEntry: PasswordEntry?

    var body: some View {
        Group {
            if store.entries.isEmpty {
                emptyView
            } else {
                entryList
            }
        }
        .scrollContentBackground(.hidden)
        .adaptiveGradientBackground()
        .navigationTitle("Vault")
        .searchable(text: $store.searchText, prompt: "Search passwords")
        .alert("Error", isPresented: Binding(
            get: { store.error != nil },
            set: { if !$0 { store.error = nil } }
        )) {
            Button("OK") { store.error = nil }
        } message: {
            Text(store.error ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add password")
            }

            ToolbarItem(placement: .topBarLeading) {
                categoryMenu
            }
        }
        .sheet(isPresented: $showAddSheet) {
            EditEntryView(store: store, entry: nil)
        }
        .sheet(item: $selectedEntry) { entry in
            EditEntryView(store: store, entry: entry)
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: Theme.iconSizeSmall))
                .foregroundStyle(.secondary)

            Text("No Saved Passwords")
                .font(.title3.weight(.semibold))

            Text("Generate a password and save it to your vault, or add one manually.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showAddSheet = true
            } label: {
                Label("Add Password", systemImage: "plus")
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.accent)
            .controlSize(.large)
            .accessibilityLabel("Add password")
        }
        .padding()
    }

    // MARK: - Entry List (auto-glass via iOS 26 List)

    private var entryList: some View {
        List {
            if !store.favoriteEntries.isEmpty && store.selectedCategory == nil {
                Section("Favorites") {
                    ForEach(store.favoriteEntries) { entry in
                        entryRow(entry)
                    }
                }
            }

            Section(store.selectedCategory?.rawValue ?? "All Passwords") {
                ForEach(store.filteredEntries) { entry in
                    entryRow(entry)
                }
                .onDelete { offsets in
                    store.deleteEntries(at: offsets)
                }
            }
        }
    }

    private func entryRow(_ entry: PasswordEntry) -> some View {
        VaultEntryRow(
            entry: entry,
            onSelect: { selectedEntry = entry },
            onDelete: { store.deleteEntry(entry) },
            onToggleFavorite: { store.toggleFavorite(entry) },
            onCopyPassword: { copyToClipboard(entry.password) },
            onCopyUsername: { copyToClipboard(entry.username) }
        )
    }

    // MARK: - Category Filter

    private var categoryMenu: some View {
        Menu {
            Button {
                store.selectedCategory = nil
            } label: {
                Label("All", systemImage: "tray.full")
            }

            Divider()

            ForEach(PasswordEntry.Category.allCases) { category in
                Button {
                    store.selectedCategory = category
                } label: {
                    Label(category.rawValue, systemImage: category.icon)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter by category")
    }

    // MARK: - Helpers

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.setItems(
            [[UIPasteboard.typeAutomatic: text]],
            options: [.expirationDate: Date().addingTimeInterval(30)]
        )
        HapticService.medium()
    }
}

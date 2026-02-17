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
            .tint(Theme.gold)
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
        Button {
            selectedEntry = entry
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: entry.category.icon)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)

                    if !entry.username.isEmpty {
                        Text(entry.username)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title)\(entry.username.isEmpty ? "" : ", \(entry.username)")\(entry.isFavorite ? ", favorite" : "")")
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.deleteEntry(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                store.toggleFavorite(entry)
            } label: {
                Label(
                    entry.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: entry.isFavorite ? "star.slash" : "star.fill"
                )
            }
            .tint(.yellow)
        }
        .contextMenu {
            Button {
                copyToClipboard(entry.password)
            } label: {
                Label("Copy Password", systemImage: "doc.on.doc")
            }

            if !entry.username.isEmpty {
                Button {
                    copyToClipboard(entry.username)
                } label: {
                    Label("Copy Username", systemImage: "person.crop.circle")
                }
            }

            Button {
                store.toggleFavorite(entry)
            } label: {
                Label(
                    entry.isFavorite ? "Remove Favorite" : "Add Favorite",
                    systemImage: entry.isFavorite ? "star.slash" : "star"
                )
            }

            Divider()

            Button(role: .destructive) {
                store.deleteEntry(entry)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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

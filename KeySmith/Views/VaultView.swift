import SwiftUI

struct VaultView: View {
    @ObservedObject var store: PasswordStore
    @State private var showAddSheet = false
    @State private var selectedEntry: PasswordEntry? = nil
    
    var body: some View {
        NavigationStack {
            Group {
                if !store.isUnlocked {
                    lockedView
                } else if store.entries.isEmpty {
                    emptyView
                } else {
                    entryList
                }
            }
            .navigationTitle("Vault")
            .searchable(text: $store.searchText, prompt: "Search passwords")
            .toolbar {
                if store.isUnlocked {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        categoryMenu
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                EditEntryView(store: store, entry: nil)
            }
            .sheet(item: $selectedEntry) { entry in
                EditEntryView(store: store, entry: entry)
            }
        }
    }
    
    // MARK: - Locked
    
    private var lockedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("Vault Locked")
                .font(.title2.weight(.semibold))
            
            Text("Authenticate to access your saved passwords")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Unlock") {
                Task { await store.authenticate() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Empty
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 48))
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
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Entry List
    
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
            HStack(spacing: 12) {
                Image(systemName: entry.category.icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
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
                UIPasteboard.general.string = entry.password
                clearClipboardAfterDelay(entry.password)
            } label: {
                Label("Copy Password", systemImage: "doc.on.doc")
            }
            
            if !entry.username.isEmpty {
                Button {
                    UIPasteboard.general.string = entry.username
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
    }
    
    // MARK: - Helpers
    
    private func clearClipboardAfterDelay(_ password: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if UIPasteboard.general.string == password {
                UIPasteboard.general.string = ""
            }
        }
    }
}

#Preview {
    VaultView(store: PasswordStore())
}

import Foundation
import SwiftUI

/// Observable store for password entries with Keychain persistence.
/// Authentication is handled at the app level by AppState/AppLockManager.
@MainActor
final class PasswordStore: ObservableObject {

    @Published var entries: [PasswordEntry] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: PasswordEntry.Category? = nil
    @Published var error: String? = nil

    private let keychain = KeychainManager.shared

    var filteredEntries: [PasswordEntry] {
        var result = entries

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.username.localizedCaseInsensitiveContains(searchText) ||
                $0.url.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result.sorted { lhs, rhs in
            if lhs.isFavorite != rhs.isFavorite { return lhs.isFavorite }
            return lhs.title.localizedCompare(rhs.title) == .orderedAscending
        }
    }

    var favoriteEntries: [PasswordEntry] {
        entries.filter { $0.isFavorite }
            .sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
    }

    // MARK: - CRUD
    
    func loadEntries() {
        do {
            entries = try keychain.loadEntries()
        } catch {
            self.error = error.localizedDescription
            entries = []
        }
    }
    
    func addEntry(_ entry: PasswordEntry) {
        entries.append(entry)
        save()
    }
    
    func updateEntry(_ entry: PasswordEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var updated = entry
            updated.modifiedAt = Date()
            entries[index] = updated
            save()
        }
    }
    
    func deleteEntry(_ entry: PasswordEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }
    
    func deleteEntries(at offsets: IndexSet) {
        let filtered = filteredEntries
        let toDelete = offsets.map { filtered[$0] }
        for entry in toDelete {
            entries.removeAll { $0.id == entry.id }
        }
        save()
    }
    
    func toggleFavorite(_ entry: PasswordEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index].isFavorite.toggle()
            save()
        }
    }
    
    func deleteAll() {
        entries = []
        save()
    }
    
    // MARK: - Persistence
    
    private func save() {
        do {
            try keychain.saveEntries(entries)
        } catch {
            self.error = error.localizedDescription
        }
    }
}

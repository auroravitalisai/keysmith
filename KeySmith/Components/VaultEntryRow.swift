import SwiftUI

struct VaultEntryRow: View {
    let entry: PasswordEntry
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    let onCopyPassword: () -> Void
    let onCopyUsername: () -> Void

    var body: some View {
        Button {
            onSelect()
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
                        .foregroundStyle(Theme.warning)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title)\(entry.username.isEmpty ? "" : ", \(entry.username)")\(entry.isFavorite ? ", favorite" : "")")
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                onToggleFavorite()
            } label: {
                Label(
                    entry.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: entry.isFavorite ? "star.slash" : "star.fill"
                )
            }
            .tint(Theme.accent)
        }
        .contextMenu {
            Button {
                onCopyPassword()
            } label: {
                Label("Copy Password", systemImage: "doc.on.doc")
            }

            if !entry.username.isEmpty {
                Button {
                    onCopyUsername()
                } label: {
                    Label("Copy Username", systemImage: "person.crop.circle")
                }
            }

            Button {
                onToggleFavorite()
            } label: {
                Label(
                    entry.isFavorite ? "Remove Favorite" : "Add Favorite",
                    systemImage: entry.isFavorite ? "star.slash" : "star"
                )
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

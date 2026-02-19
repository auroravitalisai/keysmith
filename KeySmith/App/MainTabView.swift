import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var store = PasswordStore()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            Tab("Generate", systemImage: "key", value: 0) {
                NavigationStack {
                    GeneratorView(store: store)
                }
            }

            Tab("Vault", systemImage: "lock.shield", value: 1) {
                NavigationStack {
                    VaultView(store: store)
                }
            }

            Tab("Settings", systemImage: "gear", value: 2) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .toolbarBackgroundVisibility(.visible, for: .tabBar)
        .toolbarBackground(colorScheme == .dark ? Theme.navyDark : Color(.systemBackground), for: .tabBar)
        .onAppear {
            store.loadEntries()
        }
    }
}

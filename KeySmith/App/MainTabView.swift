import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var store = PasswordStore()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            Tab("Vault", systemImage: "lock.shield", value: 0) {
                NavigationStack {
                    VaultView(store: store)
                }
            }

            Tab("Generate", systemImage: "key", value: 1) {
                NavigationStack {
                    GeneratorView(store: store)
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

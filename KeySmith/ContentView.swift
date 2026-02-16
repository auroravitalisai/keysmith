import SwiftUI

struct ContentView: View {
    @StateObject private var store = PasswordStore()
    
    var body: some View {
        TabView {
            GeneratorView(store: store)
                .tabItem {
                    Label("Generate", systemImage: "key")
                }
            
            VaultView(store: store)
                .tabItem {
                    Label("Vault", systemImage: "lock.shield")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .task {
            await store.authenticate()
        }
    }
}

#Preview {
    ContentView()
}

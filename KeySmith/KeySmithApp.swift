import SwiftUI

@main
struct KeySmithApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if !appState.hasCompletedOnboarding {
                    OnboardingView()
                } else if appState.isLocked {
                    LockScreenView()
                } else {
                    MainTabView()
                }
            }
            .tint(Theme.gold)
            .environmentObject(appState)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    appState.lockApp()
                }
            }
        }
    }
}

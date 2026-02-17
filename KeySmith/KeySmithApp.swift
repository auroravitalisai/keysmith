import SwiftUI

@main
struct KeySmithApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

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
            .preferredColorScheme(colorScheme)
            .environmentObject(appState)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    appState.lockApp()
                }
            }
        }
    }
}

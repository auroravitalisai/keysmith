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

    init() {
        configureUIKitAppearance()
    }

    /// Set UIKit appearance proxies — navy for dark mode, defaults for light
    private static func configureUIKitAppearance() {
        let navyUI = UIColor(Theme.navyDark)

        // Use a dynamic UIColor that adapts to trait changes
        let adaptiveBg = UIColor { traits in
            traits.userInterfaceStyle == .dark ? navyUI : .systemBackground
        }

        // Tab bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = adaptiveBg
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = adaptiveBg
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }

    private func configureUIKitAppearance() {
        Self.configureUIKitAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Root background — fills entire window including safe areas
                AdaptiveRootBackground()

                Group {
                    if !appState.hasCompletedOnboarding {
                        OnboardingView()
                    } else if appState.isLocked {
                        LockScreenView()
                    } else {
                        MainTabView()
                    }
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

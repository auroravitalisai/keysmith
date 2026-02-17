import SwiftUI

@MainActor
final class AppState: ObservableObject {

    @Published var isLocked: Bool = true
    @Published var hasCompletedOnboarding: Bool
    @AppStorage("selectedTab") var selectedTab: Int = 0

    let lockManager = AppLockManager()
    let biometricService = BiometricService.shared

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboardingComplete")
    }

    var hasPIN: Bool {
        lockManager.hasPIN
    }

    var biometricEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometricEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "biometricEnabled") }
    }

    func lockApp() {
        isLocked = true
    }

    func unlockApp() {
        isLocked = false
    }

    func verifyPIN(_ pin: String) -> Bool {
        lockManager.verify(pin)
    }

    func setPIN(_ pin: String) {
        lockManager.setPIN(pin)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
    }

    func attemptBiometricUnlock() async -> Bool {
        guard biometricEnabled, biometricService.isBiometricAvailable else { return false }
        let success = await biometricService.authenticate()
        if success {
            unlockApp()
        }
        return success
    }
}

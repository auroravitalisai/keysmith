import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSetupGuide = false
    @State private var clipboardTimeout: Double = 30
    @State private var showChangePIN = false
    @State private var showDeleteConfirm = false

    @AppStorage("appearanceMode") private var appearanceMode: Int = 0  // 0=system, 1=light, 2=dark

    var body: some View {
        Form {
            appearanceSection
            securitySection
            keyboardSection
            privacySection
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .adaptiveGradientBackground()
        .navigationTitle("Settings")
        .sheet(isPresented: $showSetupGuide) {
            SetupGuideView()
        }
        .sheet(isPresented: $showChangePIN) {
            ChangePINView()
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker(selection: $appearanceMode) {
                Text("System").tag(0)
                Text("Light").tag(1)
                Text("Dark").tag(2)
            } label: {
                Label("Theme", systemImage: "circle.lefthalf.filled")
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Security

    private var securitySection: some View {
        Section("Security") {
            Button {
                showChangePIN = true
            } label: {
                Label("Change PIN", systemImage: "lock.rotation")
            }

            Toggle(isOn: Binding(
                get: { appState.biometricEnabled },
                set: { appState.biometricEnabled = $0 }
            )) {
                Label(appState.biometricService.biometricName, systemImage: appState.biometricService.biometricIcon)
            }
            .disabled(!appState.biometricService.isBiometricAvailable)

            HStack {
                Text("Clipboard auto-clear")
                Spacer()
                Text("\(Int(clipboardTimeout))s")
                    .foregroundStyle(.secondary)
            }
            Slider(value: $clipboardTimeout, in: 10...120, step: 10)
                .tint(.accentColor)

            Text("Passwords copied to clipboard are automatically cleared after this duration.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Keyboard

    private var keyboardSection: some View {
        Section("Keyboard") {
            Button {
                showSetupGuide = true
            } label: {
                Label("Enable KeySmith Keyboard", systemImage: "keyboard")
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Keyboard Settings", systemImage: "gear")
            }
        }
    }

    // MARK: - Privacy

    private var privacySection: some View {
        Section("Privacy") {
            Label {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("On-Device Only")
                    Text("All passwords are generated and stored locally. Nothing leaves your device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(Theme.success)
            }

            Label {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Keychain Encrypted")
                    Text("Saved passwords are protected by the iOS Keychain and Secure Enclave.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "cpu.fill")
                    .foregroundStyle(Theme.accent)
            }

            Label {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("No Analytics")
                    Text("Zero tracking. Zero telemetry. Zero data collection.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "eye.slash.fill")
                    .foregroundStyle(Theme.accent)
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "2.0.0")
            LabeledContent("Build", value: "1")
            LabeledContent("Developer", value: "Aurora Vitalis")

            Link(destination: URL(string: "https://github.com/auroravitalisai")!) {
                Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        }
    }
}

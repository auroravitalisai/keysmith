import SwiftUI

struct SettingsView: View {
    @State private var showSetupGuide = false
    @State private var clipboardTimeout: Double = 30
    
    var body: some View {
        NavigationStack {
            Form {
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
                
                Section("Security") {
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
                
                Section("Privacy") {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("On-Device Only")
                                .font(.body)
                            Text("All passwords are generated and stored locally. Nothing leaves your device.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.green)
                    }
                    
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Keychain Encrypted")
                                .font(.body)
                            Text("Saved passwords are protected by the iOS Keychain and Secure Enclave.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "cpu.fill")
                            .foregroundStyle(.blue)
                    }
                    
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No Analytics")
                                .font(.body)
                            Text("Zero tracking. Zero telemetry. Zero data collection.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "eye.slash.fill")
                            .foregroundStyle(.purple)
                    }
                }
                
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build", value: "1")
                    LabeledContent("Developer", value: "Aurora Vitalis")
                    
                    Link(destination: URL(string: "https://github.com/auroravitalisai")!) {
                        Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showSetupGuide) {
                SetupGuideView()
            }
        }
    }
}

#Preview {
    SettingsView()
}

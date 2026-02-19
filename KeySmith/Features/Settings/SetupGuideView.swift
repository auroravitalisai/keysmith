import SwiftUI

struct SetupGuideView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    Text("Enable KeySmith Keyboard")
                        .font(Typography.display)

                    stepView(number: 1, title: "Open Settings", description: "Go to Settings > General > Keyboard > Keyboards")
                    stepView(number: 2, title: "Add Keyboard", description: "Tap \"Add New Keyboard\" and select KeySmith")
                    stepView(number: 3, title: "Allow Full Access", description: "Tap KeySmith and enable \"Allow Full Access\" for clipboard features")
                    stepView(number: 4, title: "Use It", description: "In any text field, tap the globe icon to switch to KeySmith")

                    privacyNote

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Theme.gold)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .adaptiveGradientBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func stepView(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.lg) {
            Text("\(number)")
                .font(.headline)
                .frame(width: 32, height: 32)
                .background(Theme.accent)
                .foregroundStyle(Theme.textPrimary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "lock.shield")
                .font(.title2)
                .foregroundStyle(Theme.success)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Your Privacy")
                    .font(.headline)
                Text("KeySmith generates passwords entirely on your device. No data is collected, stored, or transmitted. Full Access is only needed to copy passwords to your clipboard.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

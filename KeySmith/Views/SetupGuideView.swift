import SwiftUI

struct SetupGuideView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Enable KeySmith Keyboard")
                        .font(.largeTitle.bold())
                    
                    stepView(
                        number: 1,
                        title: "Open Settings",
                        description: "Go to Settings > General > Keyboard > Keyboards"
                    )
                    
                    stepView(
                        number: 2,
                        title: "Add Keyboard",
                        description: "Tap \"Add New Keyboard\" and select KeySmith"
                    )
                    
                    stepView(
                        number: 3,
                        title: "Allow Full Access",
                        description: "Tap KeySmith and enable \"Allow Full Access\" for clipboard features"
                    )
                    
                    stepView(
                        number: 4,
                        title: "Use It",
                        description: "In any text field, tap the globe icon 🌐 to switch to KeySmith"
                    )
                    
                    // Privacy note
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.title2)
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Privacy")
                                .font(.headline)
                            Text("KeySmith generates passwords entirely on your device. No data is collected, stored, or transmitted. Full Access is only needed to copy passwords to your clipboard.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .controlSize(.large)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func stepView(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.headline)
                .frame(width: 32, height: 32)
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SetupGuideView()
}

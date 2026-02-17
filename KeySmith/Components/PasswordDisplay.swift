import SwiftUI

/// Displays the generated password in a monospaced font.
/// This is CONTENT — no glass effect applied.
struct PasswordDisplay: View {
    let text: String
    var onTap: (() -> Void)?

    var body: some View {
        Text(text.isEmpty ? "Tap Generate" : text)
            .font(Typography.monoLarge)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.5)
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: 80)
            .contentShape(Rectangle())
            .onTapGesture { onTap?() }
            .accessibilityLabel("Generated password")
            .accessibilityValue(text.isEmpty ? "No password generated" : "Password generated, tap to copy")
            .accessibilityHint("Tap to copy password to clipboard")
    }
}

import SwiftUI

/// Shared PIN number pad used across lock screen, onboarding, and change PIN flows.
struct PINPadView: View {
    var onDigit: (String) -> Void
    var onDelete: () -> Void
    var keySize: CGFloat = 72
    var keyFont: Font = .title2.bold()
    var extraLeadingKey: PINPadExtraKey = .empty

    enum PINPadExtraKey {
        case empty
        case biometric(icon: String, action: () -> Void)
    }

    private var numberRows: [[String]] {
        [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["extra", "0", "delete"],
        ]
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            ForEach(numberRows, id: \.self) { row in
                HStack(spacing: Spacing.md) {
                    ForEach(row, id: \.self) { key in
                        padKey(key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func padKey(_ key: String) -> some View {
        if key == "extra" {
            extraKeyView
        } else if key == "delete" {
            Button {
                onDelete()
            } label: {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .frame(width: keySize, height: keySize)
            }
            .buttonStyle(.brandPINKey)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Delete")
        } else {
            Button {
                onDigit(key)
            } label: {
                Text(key)
                    .font(keyFont)
                    .frame(width: keySize, height: keySize)
            }
            .buttonStyle(.brandPINKey)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Digit \(key)")
        }
    }

    @ViewBuilder
    private var extraKeyView: some View {
        switch extraLeadingKey {
        case .empty:
            Color.clear.frame(width: keySize, height: keySize)
        case .biometric(let icon, let action):
            Button { action() } label: {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: keySize, height: keySize)
            }
            .buttonStyle(.brandPINKey)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Unlock with biometrics")
        }
    }
}

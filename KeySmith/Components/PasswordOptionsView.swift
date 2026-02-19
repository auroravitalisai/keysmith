import SwiftUI

struct PasswordOptionsView: View {
    @Binding var passwordLength: Double
    @Binding var includeUppercase: Bool
    @Binding var includeLowercase: Bool
    @Binding var includeNumbers: Bool
    @Binding var includeSymbols: Bool
    var onOptionChanged: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            lengthControl
            characterOptions
        }
    }

    // MARK: - Length Control

    private var lengthControl: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Length")
                    .font(.headline)
                Spacer()
                Text("\(Int(passwordLength))")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.tint)
            }
            .padding(.horizontal, Spacing.xs)

            Slider(value: $passwordLength, in: 4...64, step: 1) {
                Text("Length")
            } onEditingChanged: { editing in
                if !editing { onOptionChanged() }
            }
            .tint(.accentColor)
            .accessibilityLabel("Password length")
            .accessibilityValue("\(Int(passwordLength)) characters")
        }
    }

    // MARK: - Character Options

    private var characterOptions: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Characters")
                .font(.headline)
                .padding(.leading, Spacing.xs)

            VStack(spacing: 0) {
                toggleRow("ABC", "Uppercase", $includeUppercase)
                Divider().padding(.leading, 44)
                toggleRow("abc", "Lowercase", $includeLowercase)
                Divider().padding(.leading, 44)
                toggleRow("123", "Numbers", $includeNumbers)
                Divider().padding(.leading, 44)
                toggleRow("#$%", "Symbols", $includeSymbols)
            }
            .padding(Spacing.xs)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func toggleRow(_ icon: String, _ label: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: Spacing.md) {
                Text(icon)
                    .font(Typography.monoSmall)
                    .frame(width: 32)
                Text(label)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .onChange(of: isOn.wrappedValue) {
            onOptionChanged()
        }
    }
}

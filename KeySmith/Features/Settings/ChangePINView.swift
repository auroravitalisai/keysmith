import SwiftUI

struct ChangePINView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var step: Step = .current
    @State private var error = ""

    enum Step { case current, newPIN, confirm }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xxl) {
                Spacer()

                Text(stepTitle)
                    .font(Typography.headline)

                if !error.isEmpty {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.danger)
                }

                pinDotsFor(currentInput)

                VStack(spacing: Spacing.md) {
                    ForEach(numberRows, id: \.self) { row in
                        HStack(spacing: Spacing.md) {
                            ForEach(row, id: \.self) { key in
                                changePINKey(key)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, Spacing.xl)
            .adaptiveGradientBackground()
            .navigationTitle("Change PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var stepTitle: String {
        switch step {
        case .current: return "Enter Current PIN"
        case .newPIN: return "Enter New PIN"
        case .confirm: return "Confirm New PIN"
        }
    }

    private var currentInput: String {
        switch step {
        case .current: return currentPIN
        case .newPIN: return newPIN
        case .confirm: return confirmPIN
        }
    }

    private var numberRows: [[String]] {
        [["1","2","3"],["4","5","6"],["7","8","9"],["","0","delete"]]
    }

    private func pinDotsFor(_ input: String) -> some View {
        HStack(spacing: Spacing.lg) {
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(index < input.count ? Theme.accent : Theme.dotInactive)
                    .frame(width: 14, height: 14)
            }
        }
    }

    @ViewBuilder
    private func changePINKey(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear.frame(width: 64, height: 64)
        } else if key == "delete" {
            Button { deleteDigit() } label: {
                Image(systemName: "delete.left").font(.title3).frame(width: 64, height: 64)
            }
            .buttonStyle(.brandPINKey)
            .buttonBorderShape(.circle)
        } else {
            Button { appendDigit(key) } label: {
                Text(key).font(.title3.bold()).frame(width: 64, height: 64)
            }
            .buttonStyle(.brandPINKey)
            .buttonBorderShape(.circle)
        }
    }

    private func appendDigit(_ digit: String) {
        error = ""
        HapticService.light()

        switch step {
        case .current:
            guard currentPIN.count < 6 else { return }
            currentPIN += digit
            if currentPIN.count == 6 {
                if appState.verifyPIN(currentPIN) {
                    withAnimation { step = .newPIN }
                } else {
                    error = "Incorrect PIN"
                    HapticService.error()
                    currentPIN = ""
                }
            }
        case .newPIN:
            guard newPIN.count < 6 else { return }
            newPIN += digit
            if newPIN.count == 6 {
                withAnimation { step = .confirm }
            }
        case .confirm:
            guard confirmPIN.count < 6 else { return }
            confirmPIN += digit
            if confirmPIN.count == 6 {
                if newPIN == confirmPIN {
                    appState.setPIN(newPIN)
                    HapticService.success()
                    dismiss()
                } else {
                    error = "PINs don't match"
                    HapticService.error()
                    confirmPIN = ""
                    newPIN = ""
                    step = .newPIN
                }
            }
        }
    }

    private func deleteDigit() {
        HapticService.light()
        switch step {
        case .current: if !currentPIN.isEmpty { currentPIN.removeLast() }
        case .newPIN: if !newPIN.isEmpty { newPIN.removeLast() }
        case .confirm: if !confirmPIN.isEmpty { confirmPIN.removeLast() }
        }
    }
}

import SwiftUI

/// A 6-digit PIN entry view with glass number pad.
struct PINInputView: View {
    @Binding var pin: String
    let maxDigits: Int = 6
    var onComplete: ((String) -> Void)?

    @State private var shakeCount: CGFloat = 0
    @State private var isWrong = false

    var body: some View {
        VStack(spacing: Spacing.xxl) {
            pinDots
            numberPad
        }
    }

    // MARK: - PIN Dots

    private var pinDots: some View {
        HStack(spacing: Spacing.lg) {
            ForEach(0..<maxDigits, id: \.self) { index in
                Circle()
                    .fill(index < pin.count ? Color.accentColor : .secondary.opacity(0.3))
                    .frame(width: 14, height: 14)
                    .scaleEffect(index < pin.count ? 1.2 : 1.0)
                    .animation(.spring(duration: 0.2), value: pin.count)
            }
        }
        .modifier(ShakeEffect(shakes: shakeCount))
        .accessibilityLabel("PIN entry, \(pin.count) of \(maxDigits) digits entered")
    }

    // MARK: - Number Pad

    private var numberPad: some View {
        GlassEffectContainer(spacing: Spacing.sm) {
            VStack(spacing: Spacing.md) {
                ForEach(numberRows, id: \.self) { row in
                    HStack(spacing: Spacing.md) {
                        ForEach(row, id: \.self) { key in
                            numberKey(key)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.xxl)
    }

    private var numberRows: [[String]] {
        [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["", "0", "delete"],
        ]
    }

    @ViewBuilder
    private func numberKey(_ key: String) -> some View {
        if key.isEmpty {
            Color.clear
                .frame(width: 72, height: 72)
        } else if key == "delete" {
            Button {
                guard !pin.isEmpty else { return }
                pin.removeLast()
                HapticService.light()
            } label: {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .frame(width: 72, height: 72)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Delete")
        } else {
            Button {
                appendDigit(key)
            } label: {
                Text(key)
                    .font(.title2.bold())
                    .frame(width: 72, height: 72)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel(key)
        }
    }

    // MARK: - Actions

    private func appendDigit(_ digit: String) {
        guard pin.count < maxDigits else { return }
        pin += digit
        HapticService.light()

        if pin.count == maxDigits {
            onComplete?(pin)
        }
    }

    func triggerShake() {
        isWrong = true
        withAnimation(.spring(duration: 0.4)) {
            shakeCount += 3
        }
        HapticService.error()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isWrong = false
        }
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(shakes * .pi * 2) * 10
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

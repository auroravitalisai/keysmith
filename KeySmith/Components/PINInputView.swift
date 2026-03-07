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
            PINDotsView(count: pin.count, maxDigits: maxDigits)
                .modifier(ShakeEffect(shakes: shakeCount))
                .accessibilityLabel("PIN entry, \(pin.count) of \(maxDigits) digits entered")

            PINPadView(
                onDigit: { appendDigit($0) },
                onDelete: {
                    guard !pin.isEmpty else { return }
                    pin.removeLast()
                    HapticService.light()
                },
                keySize: 72
            )
            .padding(.horizontal, Spacing.xxl)
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

import SwiftUI

/// A reusable glass card container using native Liquid Glass.
/// Use this for grouping controls — never for content display.
struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Spacing.lg)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.regularMaterial)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

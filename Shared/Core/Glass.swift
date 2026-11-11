import SwiftUI

/// Liquid Glass on iOS 26 / watchOS 26, frosted material on older systems.
extension View {
    @ViewBuilder
    func glassBackground<S: Shape>(in shape: S) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, watchOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            fallback(in: shape)
        }
        #else
        fallback(in: shape)
        #endif
    }

    private func fallback<S: Shape>(in shape: S) -> some View {
        self
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.stroke(Color.white.opacity(0.5), lineWidth: 1))
    }

    func glassCard(cornerRadius: CGFloat = 32) -> some View {
        glassBackground(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    func glassCircle() -> some View {
        glassBackground(in: Circle())
    }
}

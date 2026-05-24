import SwiftUI

enum Theme {
    static let cardCorner: CGFloat = 14
    static let panelCorner: CGFloat = 18

    static let pop = Animation.spring(response: 0.45, dampingFraction: 0.78)
    static let smooth = Animation.smooth(duration: 0.35)
    static let snap = Animation.snappy(duration: 0.25)
}

/// Subtle drifting gradient that follows the active accent color.
struct AmbientBackground: View {
    let accent: Color
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor)

            // Soft accent glow blending in from corners
            RadialGradient(
                colors: [accent.opacity(0.22), .clear],
                center: UnitPoint(x: 0.15 + phase * 0.05, y: 0.1),
                startRadius: 30, endRadius: 520
            )
            RadialGradient(
                colors: [accent.opacity(0.14), .clear],
                center: UnitPoint(x: 0.85 - phase * 0.05, y: 0.95),
                startRadius: 30, endRadius: 520
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: phase)
        .onAppear { phase = 1 }
    }
}

/// Reusable pressable card style with hover + press feedback.
struct PressableCardStyle: ButtonStyle {
    var hovered: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : (hovered ? 1.01 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovered)
    }
}

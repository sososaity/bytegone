import SwiftUI

/// Big animated circular gauge — outer track is total scanned, filled arc is selected portion.
struct HeroGauge: View {
    let selected: Int64
    let total: Int64
    let accent: Color
    let title: String
    let caption: String

    @State private var spin: Double = 0

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(selected) / Double(total))
    }

    var body: some View {
        ZStack {
            // Background blurred halo
            Circle()
                .fill(accent.opacity(0.25))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .scaleEffect(0.6 + 0.4 * progress)
                .animation(.smooth(duration: 0.8), value: progress)

            // Outer track
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 14)
                .frame(width: 220, height: 220)

            // Animated progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [accent.opacity(0.85), accent, accent.opacity(0.6), accent.opacity(0.85)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 220, height: 220)
                .animation(.smooth(duration: 0.7), value: progress)

            // Subtle rotating shimmer line
            Circle()
                .trim(from: 0, to: 0.02)
                .stroke(.white.opacity(0.85), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(spin - 90))
                .frame(width: 220, height: 220)
                .opacity(progress > 0 ? 0.5 : 0)
                .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: spin)

            VStack(spacing: 6) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1.5)

                Text(formatBytes(selected))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.7)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )

                Text(caption)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
        }
        .onAppear { spin = 360 }
    }
}

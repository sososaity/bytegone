import SwiftUI

// MARK: - Empty state (pre-scan)

struct EmptyStateView: View {
    @EnvironmentObject var store: ScanStore
    @State private var hover = false

    var body: some View {
        VStack(spacing: 16) {
            PulseRing(color: Color(red: 0.36, green: 0.62, blue: 1.00), active: true)
                .frame(width: 110, height: 110)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.36, green: 0.62, blue: 1.00),
                                    Color(red: 0.66, green: 0.45, blue: 1.00)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.pulse, options: .repeating)
                )

            Text("Ready to clean up")
                .font(.system(size: 18, weight: .semibold))

            Text("Scan to discover caches, build artifacts, logs, and other reclaimable space.\nNothing is touched until you confirm.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await store.scanAll() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Scan disk").font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 22).padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 0.36, green: 0.62, blue: 1.00),
                                Color(red: 0.66, green: 0.45, blue: 1.00)
                            ],
                            startPoint: .leading, endPoint: .trailing
                        ))
                )
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0.36, green: 0.62, blue: 1.00).opacity(hover ? 0.45 : 0.2),
                        radius: hover ? 16 : 8, x: 0, y: 4)
                .scaleEffect(hover ? 1.03 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hover)
            }
            .buttonStyle(.plain)
            .onHover { hover = $0 }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

// MARK: - Pulsing concentric rings

struct PulseRing: View {
    let color: Color
    let active: Bool

    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Pulser(delay: Double(i) * 0.7, color: color, active: active)
            }
        }
    }
}

private struct Pulser: View {
    let delay: Double
    let color: Color
    let active: Bool

    @State private var animate = false

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .scaleEffect(animate ? 1.6 : 0.6)
            .opacity(animate ? 0.0 : 0.55)
            .onAppear {
                guard active else { return }
                withAnimation(.easeOut(duration: 2.1).repeatForever(autoreverses: false).delay(delay)) {
                    animate = true
                }
            }
    }
}

// MARK: - Completion overlay

struct CompletionOverlay: View {
    let result: CleanupResult
    @EnvironmentObject var store: ScanStore
    @State private var bounced = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.green.opacity(0.4), Color.green.opacity(0.1)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 96, height: 96)
                        .blur(radius: 8)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: bounced)
                }

                VStack(spacing: 6) {
                    Text("Cleanup complete")
                        .font(.system(size: 20, weight: .bold))
                    Text("Freed \(formatBytes(result.freedBytes)) • \(result.deletedCount) items")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                        .monospacedDigit()
                    if !result.errors.isEmpty {
                        Text("\(result.errors.count) item(s) skipped")
                            .font(.system(size: 11)).foregroundStyle(.orange)
                            .help(result.errors.prefix(8).joined(separator: "\n"))
                    }
                }

                if result.freedBytes >= SupportLink.promptThresholdBytes {
                    SupportPrompt(freed: result.freedBytes) {
                        SupportLink.open()
                        dismiss()
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Button("Done") { dismiss() }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.top, 4)
            }
            .padding(28)
            .frame(width: 360)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 12)
            .onAppear {
                bounced.toggle()
            }
        }
    }

    private struct SupportPrompt: View {
        let freed: Int64
        let onSupport: () -> Void
        @State private var hovered = false

        var body: some View {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Text("☕")
                        .font(.system(size: 16))
                    Text("Bytegone freed **\(formatBytes(freed))**.")
                        .font(.system(size: 12))
                }
                Text("Like it? Caffeine fuels future updates.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Button(action: onSupport) {
                    HStack(spacing: 6) {
                        Image(systemName: "cup.and.saucer.fill")
                        Text(SupportLink.cta)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(LinearGradient(
                                colors: [
                                    Color(red: 1.00, green: 0.78, blue: 0.20),
                                    Color(red: 0.95, green: 0.55, blue: 0.30),
                                ],
                                startPoint: .leading, endPoint: .trailing
                            ))
                    )
                    .foregroundStyle(.white)
                    .scaleEffect(hovered ? 1.03 : 1.0)
                    .shadow(color: Color(red: 1.00, green: 0.78, blue: 0.20).opacity(hovered ? 0.4 : 0.15),
                            radius: hovered ? 10 : 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
                .onHover { hovered = $0 }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovered)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.orange.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private func dismiss() {
        withAnimation(Theme.pop) { store.showCompletion = false }
    }
}

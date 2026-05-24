import SwiftUI

/// Slides up from the bottom whenever the user has anything selected.
struct ActionBar: View {
    @EnvironmentObject var store: ScanStore
    @State private var pressed = false

    private var visible: Bool { store.totalSelected > 0 }

    var body: some View {
        Group {
            if visible {
                content
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: visible)
    }

    private var content: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(store.selectedCount) selected")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                Text(formatBytes(store.totalSelected))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            Spacer()

            Button {
                withAnimation(.snappy(duration: 0.2)) {
                    store.selectAllEverywhere(false)
                }
            } label: {
                Text("Clear")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.primary.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)

            Button {
                pressed = true
                Task {
                    try? await Task.sleep(for: .milliseconds(120))
                    store.cleanSelected()
                    pressed = false
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .symbolEffect(.bounce, value: pressed)
                    Text("Move to Trash")
                        .font(.system(size: 13, weight: .semibold))
                }
                .padding(.horizontal, 18).padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.34, blue: 0.34),
                                    Color(red: 0.96, green: 0.50, blue: 0.30),
                                ],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                )
                .foregroundStyle(.white)
                .scaleEffect(pressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: pressed)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return)
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 8)
        .frame(maxWidth: 640)
    }
}

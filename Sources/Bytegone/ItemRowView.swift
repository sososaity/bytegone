import SwiftUI
import AppKit

struct ItemRow: View {
    let item: ScanItem
    let accent: Color
    let maxSize: Int64
    @EnvironmentObject var store: ScanStore
    @State private var hovered = false

    private var sizeFraction: CGFloat {
        guard maxSize > 0 else { return 0 }
        return CGFloat(Double(item.size) / Double(maxSize))
    }

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { item.selected },
                set: { _ in
                    withAnimation(.snappy(duration: 0.2)) { store.toggle(item) }
                }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.url.lastPathComponent)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(item.selected ? .primary : .secondary)

                // Inline size bar — proportional to largest item in this category.
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [accent.opacity(0.85), accent.opacity(0.45)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * sizeFraction)
                            .opacity(item.selected ? 1.0 : 0.45)
                    }
                }
                .frame(height: 3)
            }

            Spacer(minLength: 8)

            Text(formatBytes(item.size))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: 70, alignment: .trailing)

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            } label: {
                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .opacity(hovered ? 1 : 0.35)
            .help("Reveal in Finder")
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(hovered ? Color.primary.opacity(0.04) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered in
            withAnimation(.easeOut(duration: 0.15)) { hovered = isHovered }
        }
        .onTapGesture {
            withAnimation(.snappy(duration: 0.2)) { store.toggle(item) }
        }
    }
}

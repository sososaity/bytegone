import SwiftUI

struct CategoryDetailView: View {
    let category: CleanupCategory
    @EnvironmentObject var store: ScanStore

    private var items: [ScanItem] {
        store.itemsByCategory[category] ?? []
    }

    private var maxSize: Int64 {
        items.map(\.size).max() ?? 1
    }

    private var allSelected: Bool {
        !items.isEmpty && items.allSatisfy(\.selected)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                    .padding(.top, 28)

                if items.isEmpty {
                    emptyHere
                } else {
                    list
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(category.accent.opacity(0.22))
                    .frame(width: 56, height: 56)
                Image(systemName: category.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(category.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.system(size: 22, weight: .bold))
                Text(category.hint)
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatBytes(store.size(of: category)))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(category.accent)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
        }
    }

    private var list: some View {
        VStack(spacing: 0) {
            HStack {
                Toggle("", isOn: Binding(
                    get: { allSelected },
                    set: { store.selectAll(in: category, $0) }
                ))
                .labelsHidden()
                .toggleStyle(.checkbox)

                Text(allSelected ? "Deselect all" : "Select all")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Sorted by size")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            Divider().opacity(0.4)

            ForEach(Array(items.prefix(200).enumerated()), id: \.element.id) { idx, item in
                ItemRow(item: item, accent: category.accent, maxSize: maxSize)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.85).delay(Double(idx) * 0.015),
                        value: items.count
                    )
                if idx != items.prefix(200).count - 1 {
                    Divider().padding(.leading, 50).opacity(0.25)
                }
            }

            if items.count > 200 {
                Text("…and \(items.count - 200) more not shown")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    .padding(14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private var emptyHere: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(category.accent.opacity(0.7))
                .symbolEffect(.bounce, value: items.isEmpty)
            Text(store.hasScanned ? "Nothing here to clean" : "Run a scan to discover items")
                .font(.system(size: 14, weight: .semibold))
            Text(store.hasScanned
                 ? "This category is already tidy."
                 : "Click Scan disk in the sidebar.")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                .fill(.regularMaterial.opacity(0.6))
        )
    }
}

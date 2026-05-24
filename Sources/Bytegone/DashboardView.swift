import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: ScanStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PermissionsBanner()
                    .padding(.top, 28)
                    .animation(Theme.smooth, value: store.fullDiskAccess)

                hero
                    .padding(.top, store.fullDiskAccess == .denied ? 0 : 16)

                if !store.hasScanned {
                    EmptyStateView()
                        .padding(.top, 12)
                } else {
                    grid
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hero: some View {
        VStack(spacing: 20) {
            HeroGauge(
                selected: store.totalSelected,
                total: max(store.totalScanned, store.totalSelected),
                accent: Color(red: 0.36, green: 0.62, blue: 1.00),
                title: "Reclaimable",
                caption: store.hasScanned
                    ? "\(store.selectedCount) of \(store.totalCount) items selected"
                    : "Run a scan to begin"
            )

            if store.isScanning, let cat = store.scanningCategory {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Scanning \(cat.rawValue)…")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var grid: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 220), spacing: 14)
            ],
            spacing: 14
        ) {
            ForEach(Array(CleanupCategory.allCases.enumerated()), id: \.element) { idx, cat in
                CategoryCard(category: cat)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.8).delay(Double(idx) * 0.04),
                        value: store.hasScanned
                    )
            }
        }
    }
}

private struct CategoryCard: View {
    let category: CleanupCategory
    @EnvironmentObject var store: ScanStore
    @State private var hovered = false

    private var size: Int64 { store.size(of: category) }
    private var selected: Int64 { store.selectedSize(of: category) }
    private var totalCount: Int { (store.itemsByCategory[category] ?? []).count }

    var body: some View {
        Button {
            withAnimation(Theme.pop) { store.selection = .category(category) }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(category.accent.opacity(0.22))
                            .frame(width: 36, height: 36)
                        Image(systemName: category.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(category.accent)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .opacity(hovered ? 1 : 0.4)
                        .offset(x: hovered ? 2 : 0, y: hovered ? -2 : 0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                    Text(category.hint)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                HStack(alignment: .firstTextBaseline) {
                    Text(formatBytes(size))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(category.accent)
                        .contentTransition(.numericText())
                        .monospacedDigit()
                    Spacer()
                    Text("\(totalCount) item\(totalCount == 1 ? "" : "s")")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }

                // Mini progress bar for selected vs total in this category
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.08))
                        Capsule()
                            .fill(category.accent)
                            .frame(width: geo.size.width * fraction)
                            .animation(.smooth(duration: 0.5), value: fraction)
                    }
                }
                .frame(height: 4)
            }
            .padding(16)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: hovered
                                ? [category.accent.opacity(0.6), category.accent.opacity(0.15)]
                                : [Color.white.opacity(0.08), Color.white.opacity(0.02)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: hovered ? category.accent.opacity(0.2) : .black.opacity(0.15),
                    radius: hovered ? 14 : 6, x: 0, y: hovered ? 6 : 3)
            .scaleEffect(hovered ? 1.015 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: hovered)
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }

    private var fraction: CGFloat {
        guard size > 0 else { return 0 }
        return CGFloat(Double(selected) / Double(size))
    }
}

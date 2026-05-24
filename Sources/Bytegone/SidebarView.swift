import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var store: ScanStore
    @Namespace private var selection

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 4) {
                    SidebarRow(
                        icon: "square.grid.2x2.fill",
                        title: "Overview",
                        accent: .blue,
                        size: store.totalSelected,
                        showSize: store.hasScanned,
                        scanning: false,
                        isSelected: store.selection == .overview,
                        namespace: selection
                    ) {
                        withAnimation(Theme.pop) { store.selection = .overview }
                    }

                    ForEach(CategoryGroup.allCases, id: \.self) { group in
                        sectionHeader(group.rawValue)
                        ForEach(Array(CleanupCategory.allCases.filter { $0.group == group }.enumerated()), id: \.element) { idx, cat in
                            SidebarRow(
                                icon: cat.icon,
                                title: cat.rawValue,
                                accent: cat.accent,
                                size: store.size(of: cat),
                                showSize: store.hasScanned,
                                scanning: store.scanningCategory == cat,
                                isSelected: store.selection == .category(cat),
                                namespace: selection
                            ) {
                                withAnimation(Theme.pop) { store.selection = .category(cat) }
                            }
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                            .animation(.smooth(duration: 0.4).delay(Double(idx) * 0.04), value: store.hasScanned)
                        }
                    }

                    sectionHeader("TOOLS")
                    DevToolsSidebarRow(
                        isSelected: store.selection == .devTools,
                        namespace: selection
                    ) {
                        withAnimation(Theme.pop) { store.selection = .devTools }
                    }

                    sectionHeader("SYSTEM")
                    ScheduleSidebarRow(
                        isSelected: store.selection == .schedule,
                        namespace: selection
                    ) {
                        withAnimation(Theme.pop) { store.selection = .schedule }
                    }
                    PermissionsSidebarRow(
                        isSelected: store.selection == .permissions,
                        namespace: selection
                    ) {
                        withAnimation(Theme.pop) { store.selection = .permissions }
                    }

                    SupportSidebarRow()
                        .padding(.top, 4)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }

            Divider().opacity(0.4)
            footer
        }
        .background(.ultraThinMaterial)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 4)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 0.36, green: 0.62, blue: 1.00),
                            Color(red: 0.66, green: 0.45, blue: 1.00)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("Bytegone").font(.system(size: 14, weight: .semibold))
                Text("Bytes, bygone.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Text("Items move to Trash — recoverable")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Button {
                Task { await store.scanAll() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .symbolEffect(.pulse, options: .repeating, isActive: store.isScanning)
                    Text(store.isScanning ? "Scanning…" : "Scan disk")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 0.36, green: 0.62, blue: 1.00),
                                Color(red: 0.66, green: 0.45, blue: 1.00)
                            ],
                            startPoint: .leading, endPoint: .trailing
                        ))
                )
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(store.isScanning)
            .opacity(store.isScanning ? 0.7 : 1.0)
        }
        .padding(14)
    }
}

private struct SupportSidebarRow: View {
    @State private var hovered = false
    @State private var pulsed = false

    private let accent = Color(red: 1.00, green: 0.78, blue: 0.20)

    var body: some View {
        Button {
            pulsed.toggle()
            SupportLink.open()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 1.00, green: 0.78, blue: 0.20),
                                Color(red: 0.95, green: 0.55, blue: 0.30),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 26, height: 26)
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: pulsed)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("Buy me a coffee")
                        .font(.system(size: 13, weight: .medium))
                    Text("Support Bytegone")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .opacity(hovered ? 1 : 0.4)
                    .offset(x: hovered ? 1 : 0, y: hovered ? -1 : 0)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if hovered {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(accent.opacity(0.12))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovered)
    }
}

private struct ScheduleSidebarRow: View {
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    @EnvironmentObject var schedule: ScheduleStore
    @State private var hovered = false

    private let accent = Color(red: 0.30, green: 0.79, blue: 0.78)
    private var enabled: Bool { schedule.config.enabled }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(accent.opacity(isSelected ? 0.95 : 0.18))
                        .frame(width: 26, height: 26)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : accent)
                        .symbolEffect(.pulse, options: .repeating, isActive: schedule.isRunning)
                }
                Text("Schedule")
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Spacer(minLength: 4)
                if enabled {
                    Circle()
                        .fill(.green)
                        .frame(width: 7, height: 7)
                        .help("Schedule active")
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(accent.opacity(0.18))
                        .matchedGeometryEffect(id: "selection", in: namespace)
                } else if hovered {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

private struct DevToolsSidebarRow: View {
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    @State private var hovered = false

    private let accent = Color(red: 0.66, green: 0.45, blue: 1.00)

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(accent.opacity(isSelected ? 0.95 : 0.18))
                        .frame(width: 26, height: 26)
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : accent)
                }
                Text("Developer Tools")
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Spacer(minLength: 4)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(accent.opacity(0.18))
                        .matchedGeometryEffect(id: "selection", in: namespace)
                } else if hovered {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

private struct PermissionsSidebarRow: View {
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    @EnvironmentObject var store: ScanStore
    @State private var hovered = false

    private var status: PermissionStatus { store.fullDiskAccess }
    private var accent: Color {
        switch status {
        case .granted: return Color(red: 0.36, green: 0.85, blue: 0.55)
        case .denied:  return Color(red: 0.95, green: 0.55, blue: 0.30)
        case .unknown: return Color(red: 0.55, green: 0.55, blue: 0.55)
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(accent.opacity(isSelected ? 0.95 : 0.18))
                        .frame(width: 26, height: 26)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : accent)
                        .symbolEffect(.pulse, options: .repeating, isActive: status == .denied)
                }

                Text("Permissions")
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))

                Spacer(minLength: 4)

                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                    .help(status.label)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(accent.opacity(0.18))
                        .matchedGeometryEffect(id: "selection", in: namespace)
                } else if hovered {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

private struct SidebarRow: View {
    let icon: String
    let title: String
    let accent: Color
    let size: Int64
    let showSize: Bool
    let scanning: Bool
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(accent.opacity(isSelected ? 0.95 : 0.18))
                        .frame(width: 26, height: 26)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : accent)
                        .symbolEffect(.pulse, options: .repeating, isActive: scanning)
                }

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(.primary)

                Spacer(minLength: 4)

                if scanning {
                    ProgressView().controlSize(.mini).scaleEffect(0.7)
                } else if showSize, size > 0 {
                    Text(formatBytes(size))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(accent.opacity(0.18))
                        .matchedGeometryEffect(id: "selection", in: namespace)
                } else if hovered {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

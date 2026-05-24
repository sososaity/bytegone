import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var store: ScanStore
    @EnvironmentObject var schedule: ScheduleStore
    @State private var hoverScan = false
    @State private var hoverOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            gauge
            if !topCategories.isEmpty { topCategoriesSection }
            if schedule.config.enabled || schedule.lastRun != nil { scheduleStrip }
            actions
        }
        .frame(width: 320)
        .background(backdrop)
    }

    // MARK: - Backdrop

    private var backdrop: some View {
        ZStack {
            Color.black.opacity(0.001) // host
            LinearGradient(
                colors: [
                    Color(red: 0.36, green: 0.62, blue: 1.00).opacity(0.10),
                    Color(red: 0.66, green: 0.45, blue: 1.00).opacity(0.05),
                    .clear
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.36, green: 0.62, blue: 1.00).opacity(0.18),
                    Color(red: 0.66, green: 0.45, blue: 1.00).opacity(0.08),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 0.36, green: 0.62, blue: 1.00),
                                Color(red: 0.66, green: 0.45, blue: 1.00),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 30, height: 30)
                        .shadow(color: Color(red: 0.36, green: 0.62, blue: 1.00).opacity(0.4), radius: 6, x: 0, y: 2)
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, options: .repeating, isActive: store.isScanning)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("Bytegone")
                        .font(.system(size: 14, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .contentTransition(.opacity)
                }
                Spacer()

                if store.fullDiskAccess == .denied {
                    WarningChip(
                        text: "FDA",
                        color: .orange,
                        icon: "exclamationmark.shield.fill"
                    ) {
                        openMainWindow()
                        store.selection = .permissions
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
        }
    }

    private var subtitle: String {
        if store.isScanning, let cat = store.scanningCategory {
            return "Scanning \(cat.rawValue)…"
        }
        if let last = schedule.lastRun {
            return "Last run \(last.date.formatted(.relative(presentation: .named)))"
        }
        return store.hasScanned ? "Ready to clean" : "Click Scan to begin"
    }

    // MARK: - Gauge

    private var gauge: some View {
        HStack(alignment: .center, spacing: 14) {
            MiniGauge(
                progress: gaugeProgress,
                size: 78,
                lineWidth: 8,
                accent: gaugeAccent
            )
            .overlay(
                VStack(spacing: 0) {
                    if store.hasScanned {
                        Text(formatBytes(store.totalSelected))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .foregroundStyle(gaugeAccent)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                            .foregroundStyle(gaugeAccent.opacity(0.7))
                            .symbolEffect(.pulse, options: .repeating)
                    }
                }
            )

            VStack(alignment: .leading, spacing: 6) {
                StatLine(
                    label: "RECLAIMABLE",
                    value: store.hasScanned ? formatBytes(store.totalSelected) : "—",
                    accent: gaugeAccent,
                    bold: true
                )
                StatLine(
                    label: "FOUND",
                    value: store.hasScanned ? formatBytes(store.totalScanned) : "—",
                    accent: .secondary
                )
                if store.hasScanned {
                    StatLine(
                        label: "ITEMS",
                        value: "\(store.selectedCount) of \(store.totalCount)",
                        accent: .secondary
                    )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 14)
    }

    private var gaugeProgress: Double {
        guard store.totalScanned > 0 else { return 0 }
        return min(1, Double(store.totalSelected) / Double(store.totalScanned))
    }

    private var gaugeAccent: Color {
        if store.hasScanned {
            return Color(red: 0.36, green: 0.62, blue: 1.00)
        } else {
            return .secondary
        }
    }

    // MARK: - Top categories

    private var topCategories: [(category: CleanupCategory, size: Int64)] {
        CleanupCategory.allCases
            .map { ($0, store.size(of: $0)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0 }
    }

    private var topCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("TOP CATEGORIES")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary).tracking(0.7)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.top, 4)

            VStack(spacing: 2) {
                ForEach(topCategories, id: \.category) { entry in
                    TopCategoryRow(
                        category: entry.category,
                        size: entry.size,
                        max: topCategories.first?.size ?? 1
                    ) {
                        openMainWindow()
                        store.selection = .category(entry.category)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Schedule strip

    private var scheduleStrip: some View {
        HStack(spacing: 8) {
            Image(systemName: schedule.config.enabled ? "calendar.badge.clock" : "calendar")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(schedule.config.enabled ? Color(red: 0.30, green: 0.79, blue: 0.78) : .secondary)
                .symbolEffect(.pulse, options: .repeating, isActive: schedule.isRunning)

            VStack(alignment: .leading, spacing: 0) {
                if schedule.config.enabled, let next = schedule.nextRun {
                    Text("Next \(next.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 11, weight: .medium))
                } else {
                    Text("Schedule paused")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                if let last = schedule.lastRun {
                    Text("Last freed \(formatBytes(last.freedBytes))")
                        .font(.system(size: 9)).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                openMainWindow()
                store.selection = .schedule
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(
            Rectangle().fill(Color.primary.opacity(0.04))
        )
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 8) {
            Button {
                Task { await store.scanAll() }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .symbolEffect(.pulse, options: .repeating, isActive: store.isScanning)
                    Text(store.isScanning ? "Scanning…" : "Scan now")
                        .font(.system(size: 12, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(LinearGradient(
                            colors: [
                                Color(red: 0.36, green: 0.62, blue: 1.00),
                                Color(red: 0.66, green: 0.45, blue: 1.00),
                            ],
                            startPoint: .leading, endPoint: .trailing
                        ))
                )
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0.36, green: 0.62, blue: 1.00).opacity(hoverScan ? 0.55 : 0.3),
                        radius: hoverScan ? 10 : 4, x: 0, y: 2)
                .scaleEffect(hoverScan ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hoverScan)
            }
            .buttonStyle(.plain)
            .disabled(store.isScanning)
            .onHover { hoverScan = $0 }

            Button {
                openMainWindow()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "macwindow")
                    Text("Open window")
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.primary.opacity(hoverOpen ? 0.12 : 0.07))
                )
                .scaleEffect(hoverOpen ? 1.02 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hoverOpen)
            }
            .buttonStyle(.plain)
            .onHover { hoverOpen = $0 }

            Divider().opacity(0.3).padding(.vertical, 2)

            Button {
                NSApp.terminate(nil)
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "power")
                        .font(.system(size: 11))
                    Text("Quit")
                        .font(.system(size: 11))
                    Spacer()
                    Text("⌘Q")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8).padding(.vertical, 5)
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
        }
        .padding(.horizontal, 12).padding(.vertical, 12)
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
            return
        }
    }
}

// MARK: - Helpers

private struct MiniGauge: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let accent: Color

    @State private var shimmer: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.18))
                .blur(radius: 14)
                .scaleEffect(0.8 + 0.3 * progress)
                .animation(.smooth(duration: 0.6), value: progress)

            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [accent.opacity(0.85), accent, accent.opacity(0.6), accent.opacity(0.85)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.7), value: progress)

            if progress > 0 {
                Circle()
                    .trim(from: 0, to: 0.025)
                    .stroke(.white.opacity(0.7), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(shimmer - 90))
                    .opacity(0.5)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                shimmer = 360
            }
        }
    }
}

private struct StatLine: View {
    let label: String
    let value: String
    let accent: Color
    var bold: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: bold ? 13 : 11, weight: bold ? .bold : .medium, design: .rounded))
                .foregroundStyle(accent)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
    }
}

private struct TopCategoryRow: View {
    let category: CleanupCategory
    let size: Int64
    let max: Int64
    let action: () -> Void
    @State private var hovered = false

    private var fraction: CGFloat {
        guard max > 0 else { return 0 }
        return CGFloat(Double(size) / Double(max))
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(category.accent.opacity(0.18))
                        .frame(width: 20, height: 20)
                    Image(systemName: category.icon)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(category.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(category.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                        Spacer()
                        Text(formatBytes(size))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(category.accent)
                            .contentTransition(.numericText())
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.primary.opacity(0.06))
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [category.accent.opacity(0.85), category.accent.opacity(0.45)],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: geo.size.width * fraction)
                                .animation(.smooth(duration: 0.6), value: fraction)
                        }
                    }
                    .frame(height: 3)
                }
            }
            .padding(.horizontal, 6).padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(hovered ? Color.primary.opacity(0.06) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

private struct WarningChip: View {
    let text: String
    let color: Color
    let icon: String
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .symbolEffect(.pulse, options: .repeating)
                Text(text)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
            }
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(hovered ? 0.3 : 0.18)))
            .foregroundStyle(color)
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .help("Full Disk Access not granted — open Permissions")
    }
}

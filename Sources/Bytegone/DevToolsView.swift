import SwiftUI
import AppKit

struct DevToolsView: View {
    @EnvironmentObject var store: ScanStore
    @StateObject private var tools = DevToolsStore()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header.padding(.top, 28)

                ForEach(DeveloperTool.allCases) { tool in
                    if tool.hasAutomation {
                        AutomatedToolCard(tool: tool)
                            .environmentObject(tools)
                    } else {
                        RecommendationToolCard(tool: tool)
                    }
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await tools.refreshInstallStatus() }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(
                        colors: [
                            Color(red: 0.13, green: 0.50, blue: 0.96),
                            Color(red: 0.66, green: 0.45, blue: 1.00),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Developer Tools")
                    .font(.system(size: 22, weight: .bold))
                Text("Reclaim gigabytes from compilers, package managers, and container runtimes.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await tools.refreshInstallStatus() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(8)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("Re-detect installed tools")
        }
    }
}

// MARK: - Automated tool card (Docker, Homebrew)

private struct AutomatedToolCard: View {
    let tool: DeveloperTool
    @EnvironmentObject var tools: DevToolsStore
    @State private var hovered = false
    @State private var outputExpanded = false

    private var state: ToolState { tools.state(for: tool) }
    private var isInstalled: Bool { state.status != .notInstalled && state.status != .unknown }
    private var isRunning: Bool { state.status == .running || state.status == .checking }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(tool.accent.opacity(0.22))
                        .frame(width: 44, height: 44)
                    Image(systemName: tool.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tool.accent)
                        .symbolEffect(.pulse, options: .repeating, isActive: isRunning)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(tool.name).font(.system(size: 15, weight: .semibold))
                        ToolStatusPill(status: state.status, accent: tool.accent)
                    }
                    Text(tool.summary)
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()

                if let reclaimable = state.lastReclaimable {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ESTIMATE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary).tracking(0.8)
                        Text(reclaimable.replacingOccurrences(of: "Total reclaimable space:", with: "").trimmingCharacters(in: .whitespaces))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(tool.accent)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 160)
                    }
                }
            }

            if let warning = tool.warning {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                    Text(warning)
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Action buttons
            HStack(spacing: 10) {
                if !isInstalled && state.status == .notInstalled {
                    Text("Not installed — nothing to clean.")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                    Spacer()
                } else {
                    Button {
                        Task { await tools.check(tool) }
                    } label: {
                        Label("Check", systemImage: "magnifyingglass")
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(Color.primary.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isRunning || state.status == .notInstalled)

                    Button {
                        Task { await tools.clean(tool) }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "trash.fill")
                                .symbolEffect(.bounce, value: state.status)
                            Text("Run cleanup")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.34, blue: 0.34),
                                        Color(red: 0.96, green: 0.50, blue: 0.30),
                                    ],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                        )
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRunning || state.status == .notInstalled)

                    if let cmd = tool.cleanCommand {
                        CommandLabel(cmd: cmd, accent: tool.accent)
                    }

                    Spacer()

                    if isRunning {
                        ProgressView().controlSize(.small)
                    }
                }
            }

            // Output panel
            if !state.output.isEmpty {
                outputPanel
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: hovered
                            ? [tool.accent.opacity(0.5), tool.accent.opacity(0.1)]
                            : [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: hovered ? tool.accent.opacity(0.18) : .black.opacity(0.15),
                radius: hovered ? 14 : 6, x: 0, y: 4)
        .onHover { hovered = $0 }
        .animation(.smooth(duration: 0.3), value: hovered)
    }

    private var outputPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(Theme.snap) { outputExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: outputExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10))
                    Text("Command output")
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(state.output, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .help("Copy output")
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if outputExpanded {
                ScrollView {
                    Text(state.output)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(10)
                }
                .frame(maxHeight: 200)
                .background(Color.black.opacity(0.25))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Recommendation card (npkill, cargo-sweep)

private struct RecommendationToolCard: View {
    let tool: DeveloperTool
    @State private var hovered = false
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(tool.accent.opacity(0.22))
                        .frame(width: 44, height: 44)
                    Image(systemName: tool.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tool.accent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(tool.name).font(.system(size: 15, weight: .semibold))
                        Text("RECOMMENDED")
                            .font(.system(size: 9, weight: .bold)).tracking(0.8)
                            .foregroundStyle(tool.accent)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(tool.accent.opacity(0.18)))
                    }
                    Text(tool.summary)
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Bytegone doesn't auto-run this — it requires choosing which projects to clean.")
                        .font(.system(size: 11)).foregroundStyle(.secondary.opacity(0.8))
                        .padding(.top, 2)
                }
                Spacer()
            }

            if let cmd = tool.recommendedCommand {
                HStack(spacing: 0) {
                    Text(cmd)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(.horizontal, 12).padding(.vertical, 9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(cmd, forType: .string)
                        withAnimation(Theme.pop) { copied = true }
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            withAnimation(Theme.pop) { copied = false }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .symbolEffect(.bounce, value: copied)
                            Text(copied ? "Copied" : "Copy")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 9)
                        .foregroundStyle(copied ? .green : .primary)
                    }
                    .buttonStyle(.plain)
                    .background(Color.primary.opacity(0.05))
                }
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                .fill(.regularMaterial.opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                .stroke(
                    hovered ? tool.accent.opacity(0.4) : Color.white.opacity(0.05),
                    lineWidth: 1
                )
        )
        .onHover { hovered = $0 }
        .animation(.smooth(duration: 0.3), value: hovered)
    }
}

// MARK: - Helpers

private struct ToolStatusPill: View {
    let status: ToolStatus
    let accent: Color

    private var label: String {
        switch status {
        case .unknown:      return "Unknown"
        case .checking:     return "Checking…"
        case .installed:    return "Installed"
        case .notInstalled: return "Not installed"
        case .running:      return "Running…"
        case .idle:         return "Ready"
        }
    }

    private var color: Color {
        switch status {
        case .unknown, .checking:    return .secondary
        case .installed, .idle:      return accent
        case .notInstalled:          return .orange
        case .running:               return .blue
        }
    }

    var body: some View {
        Text(label.uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(0.6)
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.18)))
            .foregroundStyle(color)
            .contentTransition(.opacity)
    }
}

private struct CommandLabel: View {
    let cmd: String
    let accent: Color
    var body: some View {
        Text(cmd)
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(accent.opacity(0.2), lineWidth: 1)
            )
    }
}

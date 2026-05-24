import SwiftUI
import AppKit

struct PermissionsView: View {
    @EnvironmentObject var store: ScanStore

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                    .padding(.top, 28)

                FDACard()
                InfoCard()
                UsageCard()

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
                    .fill(LinearGradient(
                        colors: [Color.orange.opacity(0.6), Color.pink.opacity(0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 56, height: 56)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Permissions")
                    .font(.system(size: 22, weight: .bold))
                Text("Grant access so Bytegone can find every reclaimable cache.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                store.refreshPermissions()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(8)
                    .background(
                        Circle().fill(Color.primary.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
            .help("Re-check permissions")
        }
    }
}

// MARK: - Full Disk Access card

private struct FDACard: View {
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(accent.opacity(0.22))
                        .frame(width: 44, height: 44)
                    Image(systemName: "externaldrive.fill.badge.checkmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accent)
                        .symbolEffect(.bounce, value: status)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Full Disk Access")
                            .font(.system(size: 15, weight: .semibold))
                        StatusPill(status: status)
                    }
                    Text("Required to scan sandboxed app caches under ~/Library/Containers and other protected locations. Without it, scan results are incomplete.")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            Divider().opacity(0.25)

            HStack(spacing: 10) {
                StepNumber(n: 1)
                Text("Open System Settings → Privacy & Security → Full Disk Access.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                StepNumber(n: 2)
                Text("Toggle Bytegone on. You may need to add it with the **+** button.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 10) {
                StepNumber(n: 3)
                Text("Return here and click Re-check, or scan again.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    PermissionsService.openFullDiskAccessSettings()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "gear")
                        Text("Open System Settings")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(LinearGradient(
                                colors: [accent, accent.opacity(0.7)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                    )
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button {
                    store.refreshPermissions()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-check")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.primary.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                Spacer()
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
                        colors: hovered ? [accent.opacity(0.6), accent.opacity(0.15)]
                                        : [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: status == .denied ? accent.opacity(0.18) : .black.opacity(0.15),
                radius: hovered ? 14 : 6, x: 0, y: 4)
        .onHover { hovered = $0 }
        .animation(.smooth(duration: 0.3), value: hovered)
    }
}

// MARK: - Why card

private struct InfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("What this enables", systemImage: "info.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 6) {
                bullet("Reading sizes of sandboxed app caches under ~/Library/Containers")
                bullet("Discovering simulator and DerivedData remnants from other Xcode users")
                bullet("Reaching protected log directories")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                .fill(.regularMaterial.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle().fill(.blue.opacity(0.7)).frame(width: 5, height: 5)
            Text(text).font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Usage / safety card

private struct UsageCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("How Bytegone uses access", systemImage: "shield.lefthalf.filled")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 6) {
                bullet("Read-only scanning to compute sizes — no file contents are inspected.")
                bullet("Deletion uses Move-to-Trash. Nothing is permanently removed.")
                bullet("Safety guard blocks system paths, your work directories, .git, .env, .ssh, credentials, and node_modules.")
                bullet("No network connections. Nothing leaves your Mac.")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                .fill(.regularMaterial.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.green)
                .frame(width: 12)
            Text(text).font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Helpers

private struct StatusPill: View {
    let status: PermissionStatus

    private var color: Color {
        switch status {
        case .granted: return .green
        case .denied:  return .orange
        case .unknown: return .secondary
        }
    }

    private var icon: String {
        switch status {
        case .granted: return "checkmark.circle.fill"
        case .denied:  return "exclamationmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(status.label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.3)
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(
            Capsule().fill(color.opacity(0.18))
        )
        .foregroundStyle(color)
        .contentTransition(.opacity)
    }
}

private struct StepNumber: View {
    let n: Int
    var body: some View {
        Text("\(n)")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .frame(width: 18, height: 18)
            .background(Circle().fill(Color.primary.opacity(0.1)))
            .foregroundStyle(.primary)
    }
}

// MARK: - Dashboard banner (compact warning)

struct PermissionsBanner: View {
    @EnvironmentObject var store: ScanStore
    @State private var hovered = false

    var body: some View {
        if store.fullDiskAccess == .denied {
            content.transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var content: some View {
        Button {
            withAnimation(Theme.pop) { store.selection = .permissions }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse, options: .repeating)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Full Disk Access not granted")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Some caches won't be detected. Click to fix.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .offset(x: hovered ? 3 : 0)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.orange.opacity(hovered ? 0.5 : 0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hovered)
    }
}

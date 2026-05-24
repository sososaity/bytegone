import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: ScanStore
    @State private var sidebarVisible: NavigationSplitViewVisibility = .all

    private var ambientAccent: Color {
        switch store.selection {
        case .overview: return Color(red: 0.36, green: 0.62, blue: 1.00)
        case .category(let c): return c.accent
        case .devTools: return Color(red: 0.66, green: 0.45, blue: 1.00)
        case .schedule: return Color(red: 0.30, green: 0.79, blue: 0.78)
        case .permissions:
            return store.fullDiskAccess == .granted
                ? Color(red: 0.36, green: 0.85, blue: 0.55)
                : Color(red: 0.95, green: 0.55, blue: 0.30)
        }
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisible) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 320)
        } detail: {
            ZStack {
                AmbientBackground(accent: ambientAccent)

                Group {
                    switch store.selection {
                    case .overview:
                        DashboardView()
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    case .category(let c):
                        CategoryDetailView(category: c)
                            .id(c)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    case .devTools:
                        DevToolsView()
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    case .schedule:
                        ScheduleView()
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    case .permissions:
                        PermissionsView()
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .animation(Theme.pop, value: store.selection)

                if store.showCompletion, let result = store.lastResult {
                    CompletionOverlay(result: result)
                        .zIndex(2)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .overlay(alignment: .bottom) {
                ActionBar()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 18)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 880, minHeight: 600)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.refreshPermissions()
        }
    }
}

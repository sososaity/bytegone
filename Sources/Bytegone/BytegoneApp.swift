import SwiftUI

@main
struct BytegoneApp: App {
    @StateObject private var store = ScanStore()
    @StateObject private var schedule = ScheduleStore()

    var body: some Scene {
        WindowGroup("Bytegone") {
            RootView()
                .environmentObject(store)
                .environmentObject(schedule)
                .preferredColorScheme(.dark)
                .onAppear { schedule.attach(scanStore: store) }
        }
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra {
            MenuBarView()
                .environmentObject(store)
                .environmentObject(schedule)
        } label: {
            Image(systemName: "square.stack.3d.up")
        }
        .menuBarExtraStyle(.window)
    }
}

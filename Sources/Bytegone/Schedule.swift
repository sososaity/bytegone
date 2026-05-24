import Foundation
import SwiftUI
@preconcurrency import UserNotifications

// MARK: - Config

enum ScheduleFrequency: String, Codable, CaseIterable, Identifiable {
    case daily, weekly
    var id: String { rawValue }

    var label: String {
        switch self {
        case .daily:  return "Every day"
        case .weekly: return "Every week"
        }
    }

    var interval: TimeInterval {
        switch self {
        case .daily:  return 24 * 3600
        case .weekly: return 7 * 24 * 3600
        }
    }
}

struct ScheduleConfig: Codable, Equatable {
    var enabled: Bool = false
    var frequency: ScheduleFrequency = .weekly
    var hour: Int = 3
    var minute: Int = 0
    var weekday: Int = 1   // 1 = Sunday … 7 = Saturday (Calendar component convention)
    var includedCategories: Set<String> = []

    static var defaultIncluded: Set<String> {
        // Conservative default: build artifacts and obvious caches.
        Set([
            CleanupCategory.derivedData.rawValue,
            CleanupCategory.userCaches.rawValue,
            CleanupCategory.logs.rawValue,
            CleanupCategory.trash.rawValue,
        ])
    }

    static let storageKey = "cleanup.schedule.config.v1"

    static func load() -> ScheduleConfig {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let cfg = try? JSONDecoder().decode(ScheduleConfig.self, from: data)
        else {
            var cfg = ScheduleConfig()
            cfg.includedCategories = defaultIncluded
            return cfg
        }
        return cfg
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

// MARK: - Run history

struct ScheduleRun: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var freedBytes: Int64
    var deletedCount: Int
    var errorCount: Int
}

// MARK: - Store

@MainActor
final class ScheduleStore: ObservableObject {
    @Published var config: ScheduleConfig
    @Published private(set) var nextRun: Date?
    @Published private(set) var lastRun: ScheduleRun?
    @Published private(set) var isRunning: Bool = false

    private weak var scanStore: ScanStore?
    private var timer: Timer?

    private static let lastRunKey = "cleanup.schedule.lastRun.v1"

    init() {
        self.config = ScheduleConfig.load()
        if let data = UserDefaults.standard.data(forKey: Self.lastRunKey),
           let run = try? JSONDecoder().decode(ScheduleRun.self, from: data) {
            self.lastRun = run
        }
    }

    func attach(scanStore: ScanStore) {
        self.scanStore = scanStore
        rescheduleAndCatchUp()
        requestNotificationsAuthorizationIfNeeded()
    }

    func updateConfig(_ new: ScheduleConfig) {
        config = new
        new.save()
        rescheduleAndCatchUp()
    }

    /// Compute the next fire date strictly after `reference`.
    func computeNextRun(after reference: Date = Date()) -> Date? {
        guard config.enabled else { return nil }
        var components = DateComponents()
        components.hour = config.hour
        components.minute = config.minute
        components.second = 0
        if config.frequency == .weekly { components.weekday = config.weekday }

        let cal = Calendar.current
        return cal.nextDate(
            after: reference,
            matching: components,
            matchingPolicy: .nextTime,
            direction: .forward
        )
    }

    /// (Re)schedule the timer for the next run; if a run was missed, run immediately.
    private func rescheduleAndCatchUp() {
        timer?.invalidate()
        timer = nil

        guard config.enabled else {
            nextRun = nil
            return
        }

        // Catch up: if last run is older than (one full interval ago), run now.
        if let last = lastRun?.date {
            let elapsed = Date().timeIntervalSince(last)
            if elapsed >= config.frequency.interval {
                Task { await runScheduled(reason: "missed run") }
                return
            }
        }

        let next = computeNextRun()
        nextRun = next
        guard let next else { return }
        let delay = max(1, next.timeIntervalSinceNow)

        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.runScheduled(reason: "scheduled fire")
            }
        }
    }

    /// Manual trigger from the UI.
    func runNow() {
        Task { await runScheduled(reason: "manual") }
    }

    private func runScheduled(reason: String) async {
        guard let scanStore else { return }
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        await scanStore.scanAll()

        var totalFreed: Int64 = 0
        var totalDeleted = 0
        var totalErrors = 0

        for cat in CleanupCategory.allCases where config.includedCategories.contains(cat.rawValue) {
            let items = scanStore.itemsByCategory[cat] ?? []
            let result = CleanupService.clean(items)
            totalFreed += result.freedBytes
            totalDeleted += result.deletedCount
            totalErrors += result.errors.count
        }

        // Update view of items so the UI reflects the deletions.
        for cat in CleanupCategory.allCases where config.includedCategories.contains(cat.rawValue) {
            withAnimation(.smooth(duration: 0.4)) {
                scanStore.itemsByCategory[cat]?.removeAll(where: { _ in true })
            }
        }

        let run = ScheduleRun(
            date: Date(),
            freedBytes: totalFreed,
            deletedCount: totalDeleted,
            errorCount: totalErrors
        )
        lastRun = run
        if let data = try? JSONEncoder().encode(run) {
            UserDefaults.standard.set(data, forKey: Self.lastRunKey)
        }

        postNotification(run: run, reason: reason)
        rescheduleAndCatchUp()
    }

    // MARK: Notifications

    private func requestNotificationsAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    private func postNotification(run: ScheduleRun, reason: String) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Bytegone"
        content.body = "Freed \(formatBytes(run.freedBytes)) • \(run.deletedCount) items moved to Trash"
        if run.errorCount > 0 { content.subtitle = "\(run.errorCount) skipped" }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request, withCompletionHandler: nil)
    }
}

// MARK: - Weekday helper

enum Weekday: Int, CaseIterable, Identifiable {
    case sun = 1, mon, tue, wed, thu, fri, sat
    var id: Int { rawValue }
    var short: String {
        switch self {
        case .sun: return "Sun"
        case .mon: return "Mon"
        case .tue: return "Tue"
        case .wed: return "Wed"
        case .thu: return "Thu"
        case .fri: return "Fri"
        case .sat: return "Sat"
        }
    }
}

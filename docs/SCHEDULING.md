# Scheduled Cleanup

Bytegone can run selected categories automatically on a daily or weekly schedule, with macOS notifications on completion.

---

## Schedule configuration

Stored in `UserDefaults` under key `cleanup.schedule.config.v1` as JSON-encoded `ScheduleConfig`:

```swift
struct ScheduleConfig: Codable, Equatable {
    var enabled: Bool = false
    var frequency: ScheduleFrequency = .weekly   // .daily | .weekly
    var hour: Int = 3
    var minute: Int = 0
    var weekday: Int = 1   // Calendar component: 1 = Sunday ... 7 = Saturday
    var includedCategories: Set<String> = []
}
```

### Default included categories (conservative)

- Xcode DerivedData
- User Caches
- User Logs
- Trash

The user can add or remove any category from the schedule.

---

## Frequency options

| Frequency | Interval | UI label |
|---|---|---|
| Daily | 24 hours | "Every day" |
| Weekly | 7 days | "Every week" |

Weekly schedules also require a weekday selection (Sun–Sat chips).

---

## Scheduling mechanism

`ScheduleStore` uses `Timer.scheduledTimer` to fire at the computed next-run date.

### Computing the next run

```swift
func computeNextRun(after reference: Date = Date()) -> Date? {
    guard config.enabled else { return nil }
    var components = DateComponents()
    components.hour = config.hour
    components.minute = config.minute
    components.second = 0
    if config.frequency == .weekly { components.weekday = config.weekday }

    return Calendar.current.nextDate(
        after: reference,
        matching: components,
        matchingPolicy: .nextTime,
        direction: .forward
    )
}
```

### Rescheduling logic

When config changes or the store attaches:

```
1. Invalidate existing timer.
2. If disabled → clear nextRun, return.
3. Catch-up check:
       if lastRun exists and (now - lastRun) >= interval:
           run immediately (async Task)
           return
4. Compute next fire date.
5. Schedule Timer with delay = next - now.
6. On timer fire → runScheduled → reschedule again.
```

### Catch-up behavior

If the Mac was asleep or the app was not running at the scheduled time, the next time the store initializes it checks whether the elapsed time since the last run exceeds the interval. If so, it runs immediately rather than waiting for the next cycle.

**Limitation:** If the app stays running continuously for a long period and the Mac sleeps through the scheduled time, the timer fires upon wake (Timer behavior), but the catch-up only triggers during explicit `rescheduleAndCatchUp()` calls.

---

## What happens during a scheduled run

```swift
private func runScheduled(reason: String) async {
    await scanStore.scanAll()

    for cat in CleanupCategory.allCases
        where config.includedCategories.contains(cat.rawValue) {
        let items = scanStore.itemsByCategory[cat] ?? []
        let result = CleanupService.clean(items)
        totalFreed += result.freedBytes
        totalDeleted += result.deletedCount
        totalErrors += result.errors.count
    }

    // Remove cleaned items from UI
    // Save run history to UserDefaults
    // Post notification
    // Reschedule for next run
}
```

**Important:** Scheduled cleanup does not show the confirmation dialog. It trusts the schedule configuration. The conservative default is intentionally narrow to minimize risk.

---

## Run history

Each completed run is stored as `ScheduleRun` in `UserDefaults` under `cleanup.schedule.lastRun.v1`:

```swift
struct ScheduleRun: Codable, Identifiable, Equatable {
    var id = UUID()
    var date: Date
    var freedBytes: Int64
    var deletedCount: Int
    var errorCount: Int
}
```

Displayed in the **Schedule** view as "Last run" card with date, freed space, item count, and error count.

---

## Notifications

- Authorization requested on first schedule enable (if not already granted).
- After each scheduled run, a local notification is posted:
  - Title: "Bytegone"
  - Body: "Freed X GB • N items moved to Trash"
  - Sound: default alert sound
  - Subtitle (if errors): "Y skipped"

---

## UI controls

### Schedule view

- **Toggle:** Enable / pause schedule.
- **Frequency picker:** Segmented control (Daily / Weekly).
- **Time picker:** macOS `DatePicker` with `.hourAndMinute` style.
- **Weekday chips:** Sun–Sat buttons (visible only when Weekly is selected).
- **Category list:** Every category with toggle-on/off. Shows count of selected categories.
- **Run now button:** Manual trigger, disabled while a run is in progress.
- **Last run card:** History display (only if a run exists).

### Menu bar integration

The schedule strip shows:
- Next relative time ("Next in 2 hours") if enabled.
- "Schedule paused" if disabled.
- Last freed amount if a run exists.
- Tapping opens the main window to the Schedule view.

---

## Edge cases

| Scenario | Behavior |
|---|---|
| App not running at scheduled time | Catch-up runs on next launch if interval elapsed. |
| Mac asleep during scheduled time | Timer fires on wake; catch-up logic handles long sleeps. |
| User manually runs cleanup before schedule | Last-run timestamp updates; next schedule shifts accordingly. |
| FDA denied during scheduled run | Scan is incomplete; some paths silently skipped. Cleanup proceeds with what was found. |
| No items found in included categories | Run completes with 0 freed bytes. Notification still posted. |

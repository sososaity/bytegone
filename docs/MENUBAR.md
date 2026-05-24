# Menu Bar Experience

Bytegone is a dual-interface app: a full main window and a compact menu-bar panel. The menu bar is the primary daily-use surface.

---

## Registration

```swift
MenuBarExtra {
    MenuBarView()
        .environmentObject(store)
        .environmentObject(schedule)
} label: {
    Image(systemName: "square.stack.3d.up")
}
.menuBarExtraStyle(.window)
```

The `.window` style renders the menu bar as a floating panel rather than a traditional dropdown menu, enabling rich SwiftUI content.

---

## Layout

The menu bar panel is 320 pt wide and stacks vertically:

```
┌─────────────────────────┐
│ Header (icon + title    │
│        + FDA warning)   │
├─────────────────────────┤
│ Gauge (mini ring +      │
│        stats)           │
├─────────────────────────┤
│ Top 3 categories        │
│ (bar charts)            │
├─────────────────────────┤
│ Schedule strip          │
│ (if enabled or history) │
├─────────────────────────┤
│ [ Scan now ]            │
│ [ Open window ]         │
│ ───────────             │
│ [ Quit ⌘Q ]             │
└─────────────────────────┘
```

---

## Header

- App icon with gradient background + shadow.
- Title "Bytegone" + dynamic subtitle:
  - Scanning: "Scanning {Category}…"
  - Post-scan: "Ready to clean"
  - With history: "Last run {relative time}"
- FDA warning chip (orange "FDA") if Full Disk Access is denied. Tapping opens the main window to Permissions.

## Gauge

A compact circular progress ring (78 pt) showing:
- **Reclaimable:** Selected total (or "—" if unscanned).
- **Found:** Total scanned.
- **Items:** Selected count vs total count.

The ring fill fraction = `selected / total`. Uses the same angular-gradient stroke as the main HeroGauge with a subtle shimmer rotation.

## Top categories

After scanning, the top 3 categories by size are listed with:
- Category icon in accent color.
- Category name + formatted size.
- Proportional horizontal bar (relative to the largest of the three).

Tapping a row opens the main window to that category's detail view.

## Schedule strip

- If schedule is enabled: shows relative next-run time ("Next in 2 hours").
- If schedule is paused: shows "Schedule paused".
- If last run exists: shows "Last freed X GB" below the schedule status.
- Tapping opens the main window to Schedule view.

## Actions

- **Scan now:** Full-width gradient button. Disabled while scanning. Icon pulses during scan.
- **Open window:** Opens the main app window (activates app, brings window to front).
- **Quit:** Plain row with ⌘Q shortcut.

---

## Interactions

### Opening the main window

```swift
private func openMainWindow() {
    NSApp.activate(ignoringOtherApps: true)
    for window in NSApp.windows where window.canBecomeMain {
        window.makeKeyAndOrderFront(nil)
        return
    }
}
```

Used throughout the menu bar for:
- Opening a specific category.
- Opening Permissions view (via FDA chip).
- Opening Schedule view (via schedule strip).
- General "Open window" button.

### Window behavior

- The main window is a `WindowGroup` with `.windowResizability(.contentMinSize)` and `.windowStyle(.hiddenTitleBar)`.
- Minimum size: 880 × 600.
- Closing the main window does **not** quit the app — the menu bar remains active.
- Re-opening via menu bar or Dock restores the window.

---

## Design notes

- The panel uses a subtle gradient backdrop (blue-to-purple at low opacity) for depth.
- All buttons have hover scale + shadow lift.
- The gauge uses numeric content transitions so values animate smoothly as the scan progresses.
- The menu bar is designed to be glanceable: a user can see reclaimable space, top offenders, and schedule status in under 2 seconds.

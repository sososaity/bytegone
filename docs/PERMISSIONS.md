# Permissions & Full Disk Access

Bytegone can operate without elevated permissions, but granting **Full Disk Access (FDA)** significantly improves scan completeness.

---

## What Full Disk Access enables

Without FDA, macOS TCC restricts access to:

- `~/Library/Containers/*/Data/Library/Caches` (sandboxed app caches)
- Some Xcode and simulator directories
- Certain protected log paths

With FDA, the scanner can enumerate and size every reclaimable path in the known category roots.

**Without FDA, the app is still fully functional.** It simply reports less reclaimable space because some directories return permission errors during enumeration.

---

## Detection

`PermissionsService.checkFullDiskAccess()` uses a heuristic: it attempts to open `/Library/Application Support/com.apple.TCC/TCC.db` for reading.

```swift
static func checkFullDiskAccess() -> PermissionStatus {
    let path = "/Library/Application Support/com.apple.TCC/TCC.db"
    guard FileManager.default.fileExists(atPath: path) else { return .unknown }
    do {
        let handle = try FileHandle(forReadingFrom: url)
        try handle.close()
        return .granted
    } catch {
        return .denied
    }
}
```

This works because TCC protects its own database; a successful read proves FDA is active.

A secondary check, `canReadAppContainers()`, enumerates `~/Library/Containers` as a fallback signal.

---

## Permission states

| State | Meaning | UI indicator |
|---|---|---|
| `granted` | FDA active | Green dot in sidebar |
| `denied` | FDA not granted | Orange dot + pulsing shield icon + dashboard banner |
| `unknown` | Cannot determine (rare) | Gray dot |

---

## User flow for granting FDA

### 1. Discovery

- Dashboard shows an orange **PermissionsBanner** when FDA is denied.
- Menu bar shows an orange **FDA** chip that opens Permissions view.
- Sidebar **Permissions** row has an orange dot.

### 2. Deep-link

Clicking **Open System Settings** navigates directly to:

```
x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles
```

This skips manual navigation through System Settings panes.

### 3. Re-check

After the user toggles FDA in System Settings, clicking **Re-check** in the Permissions view re-runs the heuristic. The status updates with a smooth animation.

### 4. Auto-refresh

The app listens for `NSApplication.didBecomeActiveNotification` and re-checks FDA every time the app becomes frontmost. This means the status updates automatically when the user returns from System Settings without manual interaction.

---

## Permissions view

The Permissions view contains three cards:

### 1. Full Disk Access card
- Status icon + pill.
- Step-by-step instructions (numbered 1–3).
- **Open System Settings** button (accent-colored).
- **Re-check** button.

### 2. What this enables
- Bullet list: sandboxed app caches, simulator/DerivedData from other users, protected logs.

### 3. How Bytegone uses access
- Read-only scanning (no content inspection).
- Move-to-Trash deletion (nothing permanently removed).
- SafetyGuard blocks system paths, work dirs, `.git`, `.env`, credentials, `node_modules`.
- No network connections.

---

## Privacy principles

- **No data leaves the device.** Bytegone has no network code.
- **Read-only scanning.** Only file sizes and modification dates are read. File contents are never opened or inspected.
- **No analytics or telemetry.** No crash reporter, no usage metrics.
- **Minimal permission surface.** The app only requests FDA. It does not request location, camera, microphone, contacts, or calendar.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| App Container Caches shows 0 items | FDA denied | Grant FDA in System Settings |
| Some categories show smaller totals than expected | Partial enumeration due to TCC | Grant FDA |
| Status stays "Unknown" | TCC.db not present (rare system config) | Manual verification; app still usable |

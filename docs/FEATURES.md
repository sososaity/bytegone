# Features

## App at a glance

Bytegone is a macOS menu-bar utility that finds reclaimable disk space and moves it to Trash with your confirmation. It is built around a simple loop: **scan, review, clean**.

| Feature | File | Description |
|---|---|---|
| Disk scanning | `DiskScanner.swift` | 13 categories, async actor-isolated |
| Safety guard | `SafetyGuard.swift` | Hard-coded blocklist for system / work / sensitive paths |
| Trash-only cleanup | `CleanupService.swift` | `FileManager.trashItem` — never `rm` |
| Scheduled cleanup | `Schedule.swift` | Daily or weekly, with notifications |
| Developer tools | `DevTools.swift` / `DevToolsView.swift` | Docker, Homebrew automation + recommendations |
| Full Disk Access | `PermissionsService.swift` | Detection, deep-link to System Settings |
| Menu bar | `MenuBarView.swift` | Live gauge, top categories, quick scan, schedule strip |
| Main window | `RootView.swift` | Navigation split view with ambient accent background |

---

## Feature matrix

### Scanning categories (13 total)

| Category | Group | Path roots | Safe to delete? |
|---|---|---|---|
| User Caches | Maintenance | `~/Library/Caches`, `~/.cache`, `~/.npm/_cacache`, `~/.yarn/cache`, `~/.pnpm-store`, `~/.bun/install/cache`, `~/.gradle/caches` | Yes — app caches rebuild |
| Xcode DerivedData | Maintenance | `~/Library/Developer/Xcode/DerivedData` | Yes — rebuilds on next compile |
| iOS Simulator Caches | Maintenance | `~/Library/Developer/CoreSimulator/Caches` | Yes — simulators remain |
| App Container Caches | Maintenance | `~/Library/Containers/*/Data/Library/Caches` | Yes — sandboxed app caches |
| User Logs | Maintenance | `~/Library/Logs` | Yes — logs are append-only |
| Trash | Maintenance | `~/.Trash` | Already deleted by user |
| Old Downloads | Maintenance | `~/Downloads` | Items older than 30 days |
| CocoaPods Cache | Developer | `~/Library/Caches/CocoaPods` | Re-fetched on `pod install` |
| pip Cache | Developer | `~/Library/Caches/pip`, `~/.cache/pip` | Re-downloaded as needed |
| Hugging Face Cache | Developer | `~/.cache/huggingface`, `~/Library/Caches/huggingface` | Re-downloaded |
| Ollama Models | Developer | `~/.ollama/models` | Must re-pull |
| VS Code Storage | Developer | `~/Library/Application Support/Code/...` | Extensions re-install |
| JetBrains Caches | Developer | `~/Library/Caches/JetBrains`, `~/Library/Logs/JetBrains` | Rebuilt by IDE |

**Exclusion logic:** Maintenance categories skip any subdirectory that belongs to a Developer category to avoid double-counting.

---

## User flows

### 1. First launch
1. Open app — main window appears + menu bar icon registers.
2. Dashboard shows empty state with a **Scan disk** CTA.
3. Permissions banner appears if Full Disk Access is denied.

### 2. Scanning
1. Click **Scan disk** (sidebar) or **Scan now** (menu bar).
2. Scanner iterates categories sequentially, pushing partial results to UI after each.
3. Sidebar fills progressively; dashboard hero gauge animates as totals update.
4. Top 3 categories appear in menu bar.

### 3. Review & select
1. Click any category card to open **Category Detail**.
2. Toggle individual items or use **Select all / Deselect all**.
3. Each row shows a proportional size bar and a **Reveal in Finder** button.
4. Selected total appears in the floating **Action Bar** at the bottom.

### 4. Clean
1. Click **Move to Trash** in the Action Bar (Return key shortcut).
2. `CleanupService` verifies `SafetyGuard.isSafe()` again at deletion time.
3. Items are moved to Trash via `FileManager.trashItem`.
4. Completion overlay appears with freed size and item count.
5. If freed >= 5 GB, a **Buy me a coffee** prompt appears.

### 5. Schedule
1. Open **Schedule** in sidebar.
2. Toggle **Schedule active** on.
3. Choose daily or weekly frequency, time, and weekday (if weekly).
4. Pick included categories (conservative default: DerivedData, User Caches, Logs, Trash).
5. App reschedules a timer; next run time shown in UI and menu bar.
6. Missed-run catch-up fires immediately if the interval has elapsed since last run.
7. Notification posted after scheduled run completes.

### 6. Developer Tools
1. Open **Developer Tools** in sidebar.
2. Docker / Homebrew: auto-detected via `command -v`.
3. Click **Check** to run `docker system df` or `brew cleanup -n`.
4. Click **Run cleanup** to execute the clean command.
5. Output panel expands to show command stdout/stderr, copyable to pasteboard.
6. npkill / cargo-sweep: recommendation cards with a copyable install/run command.

---

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| `Return` | Move selected items to Trash (when Action Bar visible) |
| `⌘Q` | Quit app (menu bar) |

---

## Notifications

- **Schedule completion:** "Freed X GB • N items moved to Trash" (alert + sound).
- **Request authorization** on first schedule enable.

---

## Data & privacy

- No network connections. Nothing leaves the Mac.
- Scan results are in-memory only; not persisted to disk.
- Schedule config and last-run history stored in `UserDefaults` under `com.pakorn.bytegone`.
- Only file sizes and modification dates are read — file contents are never inspected.

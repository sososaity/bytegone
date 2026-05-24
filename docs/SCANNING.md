# Scanning Engine

The scanning engine discovers reclaimable files and computes their sizes. It is actor-isolated, async, and streams partial results to the UI.

---

## Architecture

```
ScanStore (MainActor)
    └─ DiskScanner (actor)
           └─ FileManager
```

- `ScanStore` owns the UI-visible state (`itemsByCategory`, `isScanning`).
- `DiskScanner` is an `actor` so all scanning happens off the main thread.
- `ScanStore.scanAll()` iterates categories and awaits each scan sequentially.

---

## Category roots

Each `CleanupCategory` defines one or more filesystem roots. See `Models.swift` for the full list. Examples:

```swift
case .userCaches:
    return [
        home.appending(path: "Library/Caches"),
        home.appending(path: ".cache"),
        home.appending(path: ".npm/_cacache"),
        home.appending(path: ".yarn/cache"),
        // ...
    ]
```

Roots that do not exist on disk are silently skipped.

---

## Scanning algorithm

### Per-category flow

```
for root in category.roots where exists(root):
    if category == .oldDownloads:
        scanOldFiles(root, olderThanDays: downloadAgeDays)
    else if category == .appContainerCaches:
        for container in contents(root):
            scanChildren(container/Data/Library/Caches)
    else:
        scanChildren(root)
```

### `scanChildren`

1. List immediate children of the root.
2. Skip any child blocked by `SafetyGuard.isSafe()`.
3. Skip any child whose path is in `CleanupCategory.specializedRootPaths` (prevents double-counting between maintenance and developer categories).
4. Compute `sizeOnDisk(of: entry)`.
5. Emit a `ScanItem` for every entry with `size > 0`.
6. Sort descending by size.

### `scanOldFiles`

Same as `scanChildren`, but additionally filters by modification date:

```swift
let cutoff = Date().addingTimeInterval(-Double(days) * 86_400)
// Only include items where modified < cutoff
```

Default `downloadAgeDays` is 30 (configurable in `ScanStore`).

---

## Size calculation

`sizeOnDisk(of:)` handles both files and directories:

- **File:** reads `URLResourceKey.fileSize`.
- **Directory:** enumerates all regular files recursively, summing their sizes.
- Uses `errorHandler: { _, _ in true }` to silently skip unreadable files (e.g., sandboxed paths when FDA is denied).
- Returns `0` if the path does not exist.

**Note:** This is a logical-size sum, not physical blocks-on-disk. Sparse files and filesystem compression may cause the actual reclaimed space to differ slightly.

---

## Double-counting prevention

The `specializedRootPaths` set contains every root from every `.developer` category. When `scanChildren` runs for a `.maintenance` category, any child whose path matches a specialized root is skipped.

Example:
- `userCaches` scans `~/Library/Caches`.
- `cocoapodsCache` also lives under `~/Library/Caches/CocoaPods`.
- When `userCaches` encounters `CocoaPods/`, it skips it because that path is in `specializedRootPaths`.
- Result: `CocoaPods` appears only under the **CocoaPods Cache** category.

---

## Progressive UI updates

`ScanStore.scanAll()` pushes partial state after every category:

```swift
for category in CleanupCategory.allCases {
    scanningCategory = category
    fresh[category] = await scanner.scan(category: category, downloadAgeDays: days)
    withAnimation(.smooth(duration: 0.4)) {
        itemsByCategory = fresh
    }
}
```

This means:
- The sidebar populates category-by-category.
- The hero gauge updates live as new totals arrive.
- The user can start reviewing while the scan is still running.

---

## Performance characteristics

- **Time complexity:** O(total files in known cache roots). Bounded to known directories; never scans the full disk.
- **Memory:** All `ScanItem`s are held in `itemsByCategory` dictionaries. For extremely large caches (e.g., Hugging Face with 100 GB of model files), this can grow. The category detail view caps display at 200 items with an "…and N more not shown" footer.
- **I/O:** Heavy. Scanning enumerates every file under large roots like DerivedData or Containers. Runs on a background actor to keep UI responsive.

---

## Permissions impact

| FDA status | Effect on scanning |
|---|---|
| **Granted** | Can read sandboxed containers, all cache directories, and protected logs. Full accuracy. |
| **Denied** | Some directories under `~/Library/Containers` return permission errors. `sizeOnDisk` silently skips them. Totals may be under-reported. |

A banner in the dashboard warns the user when FDA is denied and offers a deep-link to System Settings.

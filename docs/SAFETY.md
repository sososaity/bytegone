# Safety

Bytegone treats safety as a first-class feature. Every deletion path must pass two independent checks: once at scan time and once again at cleanup time.

---

## Core rule

> **Items are moved to Trash, never deleted directly.**

The app uses `FileManager.trashItem(at:resultingItemURL:)` exclusively. This means:
- Every removal is recoverable via Trash / Time Machine.
- The user can inspect items in Finder before emptying Trash.
- Bytegone never invokes `rm`, `rmdir`, `shred`, or any destructive command.

---

## SafetyGuard

`SafetyGuard` (`Sources/Bytegone/SafetyGuard.swift`) is the single chokepoint for path validation. It rejects any path matching three independent blocklists.

### 1. System paths (absolute prefix match)

```
/System
/Library
/private
/usr
/bin
/sbin
/Applications
/cores
/Volumes
```

These are matched with `hasPrefix`, so `/System/Library/...` is blocked just as `/System` is.

### 2. Work directories (absolute prefix match)

Customize this list with your own protected directories in `SafetyGuard.workPaths`:

```
~/Documents/Workspace
~/Documents/Projects
~/Desktop/Projects
~/Desktop/Work
```

### 3. Sensitive patterns (substring match)

Any path containing these substrings is rejected:

```
/.git/
/.git
/.env
/.envrc
/.ssh/
/.aws/credentials
/.aws/config
/.gnupg/
/.config/gh/hosts.yml
id_rsa
id_ed25519
id_ecdsa
.keychain
.keychain-db
node_modules
```

### 4. Structural guards

- Rejects root `/` and the user's home directory `~`.
- Rejects empty paths.

### Runtime behavior

```swift
// Scan time
for entry in entries where SafetyGuard.isSafe(entry) { ... }

// Cleanup time (redundant check)
guard SafetyGuard.isSafe(item.url) else {
    result.errors.append("BLOCKED by SafetyGuard: \(item.url.path)")
    continue
}
```

The second check at cleanup time protects against:
- Race conditions (path changed between scan and delete).
- Future bugs where scan-time validation is accidentally bypassed.
- Malformed items injected into the store.

---

## What Bytegone never touches

| Category | Examples |
|---|---|
| macOS system files | `/System`, `/Library`, `/usr`, `/private` |
| Installed applications | `/Applications/*.app` |
| User projects & documents | `~/Documents/Workspace`, `~/Desktop/Projects` |
| Source control | Any `.git` directory |
| Secrets | `.env`, `.ssh`, AWS credentials, GPG keys, keychains |
| Installed packages | `node_modules` inside any path |

---

## Scan scope

Bytegone only enumerates **known cache and artifact directories**.

- It does not walk the entire filesystem.
- It does not recurse into arbitrary user folders.
- It does not follow symlinks outside the known roots.
- The deepest recursion happens inside specific roots like `~/Library/Caches/*`.

This bounded scope means even a catastrophic `SafetyGuard` bug has limited blast radius — the scanner will not wander into `~/Documents` unless that path is explicitly listed as a root (it is not).

---

## Developer tools safety

Automated developer tools (Docker, Homebrew) run their own safe commands:

| Tool | Check command | Clean command |
|---|---|---|
| Docker | `docker system df` | `docker system prune -a --volumes -f` |
| Homebrew | `brew cleanup -n` | `brew cleanup -s` |

These are industry-standard cleanup commands. Bytegone does not craft custom `rm` sequences. It simply invokes the tool's own reclaim logic.

Recommended tools (npkill, cargo-sweep) are **not automated** — the app only provides a copyable command. The user decides whether and where to run it.

---

## Audit trail

Every blocked path and every error is recorded in the cleanup result:

```swift
struct CleanupResult {
    var deletedCount: Int
    var freedBytes: Int64
    var errors: [String]
}
```

Blocked items appear in the completion overlay as "X item(s) skipped" with a tooltip listing up to 8 blocked paths.

---

## Trust model

- Bytegone is ad-hoc signed, not notarized by Apple.
- No network access. No analytics. No update checker.
- Source code is plain Swift/SwiftUI — no obfuscated logic.
- The entire `SafetyGuard` enum is ~60 lines and trivial to audit.

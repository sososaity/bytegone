# Bytegone

> Bytes, bygone.

A SwiftUI menu-bar app for reclaiming disk space on macOS — without ever touching system files or your work.

![Tech](https://img.shields.io/badge/Platform-macOS_14+-blue)
![Lang](https://img.shields.io/badge/Swift-5.9+-orange)

## What it does

Scans 13 well-known reclaimable locations on your Mac, surfaces what's reclaimable, and moves the items you confirm to the Trash (never `rm`). Built specifically with developer machines in mind: Xcode DerivedData, simulator caches, CocoaPods, npm/yarn/pnpm/bun, Docker, Homebrew, Hugging Face, Ollama, VS Code, JetBrains, and more.

| Feature | Summary |
|---|---|
| 13 cleanup categories | Maintenance + developer-focused |
| Developer tools | Docker prune, Homebrew cleanup, recommended commands for `npkill` and `cargo-sweep` |
| Schedule | Daily / weekly auto-cleanup with notifications |
| Permissions | Full Disk Access detection + deep-link to System Settings |
| Menu bar | Live gauge, top categories, schedule strip, quick scan |
| Safety guard | Hard-coded blocklist for system paths, your work, and credentials |

## Quick start

```sh
./build.sh
open dist/Bytegone.app
```

To install:
```sh
cp -R dist/Bytegone.app /Applications/
```

To package for distribution (DMG + zip):
```sh
./package.sh
```

Requirements: **macOS 14+**, Xcode Command Line Tools (`xcode-select --install`).

## Documentation

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — code layout, data flow, view hierarchy
- [docs/CATEGORIES.md](docs/CATEGORIES.md) — every cleanup category, paths scanned, accent colors
- [docs/SAFETY.md](docs/SAFETY.md) — safety guard rules, what's protected, how to audit
- [docs/FEATURES.md](docs/FEATURES.md) — Schedule, Permissions, Developer Tools details
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) — building, debugging, regenerating the icon

## Safety in one sentence

**Items are moved to Trash, never deleted directly** — and the [`SafetyGuard`](Sources/Bytegone/SafetyGuard.swift) rejects anything under `/System`, `/Library`, `/usr`, `/Applications`, your work directories listed in `CLAUDE.md`, and any path containing `.git`, `.env`, `.ssh`, credentials, or `node_modules`.

## License / use

Personal project. No warranty — review [docs/SAFETY.md](docs/SAFETY.md) before using on machines with irreplaceable work.

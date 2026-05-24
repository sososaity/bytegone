# Bytegone

> **Bytes, bygone.**

A **free, open-source macOS disk cleaner** built with SwiftUI. Bytegone safely scans your Mac for reclaimable cache files, build artifacts, logs, and downloads — then moves them to Trash with your confirmation. It never touches system files or your work.

![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-blue)
![Language](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## What is Bytegone?

**Bytegone** is a lightweight **macOS menu-bar app** that helps you **reclaim disk space** by cleaning up 13 well-known reclaimable locations on your Mac. Built specifically for developers, it targets Xcode DerivedData, iOS Simulator caches, npm/yarn/pnpm caches, Docker artifacts, Homebrew, VS Code storage, JetBrains caches, and more.

Unlike command-line tools that use `rm`, Bytegone **only moves items to Trash** — everything is recoverable. It also includes a built-in [`SafetyGuard`](Sources/Bytegone/SafetyGuard.swift) that blocks system directories, your work folders, and any path containing secrets like `.git`, `.env`, `.ssh`, or credentials.

### Key Features

| Feature | Description |
|---|---|
| **13 Cleanup Categories** | User caches, Xcode DerivedData, simulator caches, app containers, logs, trash, old downloads, CocoaPods, pip, Hugging Face, Ollama, VS Code, JetBrains |
| **Developer Tools** | One-click Docker prune, Homebrew cleanup, plus recommended commands for `npkill` and `cargo-sweep` |
| **Scheduled Cleanup** | Daily or weekly auto-cleanup with native macOS notifications |
| **Full Disk Access** | Detects missing permissions and deep-links to System Settings |
| **Menu Bar Integration** | Live gauge, top categories, schedule strip, and quick scan from the menu bar |
| **Safety First** | Hard-coded blocklist for system paths, work directories, and sensitive files |

## Quick Start

Build from source:

```sh
./build.sh
open dist/Bytegone.app
```

Install to Applications:

```sh
cp -R dist/Bytegone.app /Applications/
```

Package for distribution (DMG + zip):

```sh
./package.sh
```

**Requirements:** macOS 14+ (Sonoma), Xcode Command Line Tools (`xcode-select --install`).

## Why Bytegone?

- **Free & Open Source** — No subscriptions, no ads, no data collection.
- **Trash-Only Cleanup** — Everything goes to Trash. Nothing is permanently deleted.
- **Developer-Focused** — Knows about Xcode, npm, Docker, Homebrew, and more.
- **Privacy-First** — No network connections. No analytics. Your data never leaves your Mac.
- **Menu Bar Native** — Lives in your menu bar, ready when you need it.

## Documentation

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Code layout, data flow, view hierarchy
- [docs/CATEGORIES.md](docs/CATEGORIES.md) — Every cleanup category, paths scanned, accent colors
- [docs/SAFETY.md](docs/SAFETY.md) — Safety guard rules, what's protected, how to audit
- [docs/FEATURES.md](docs/FEATURES.md) — Schedule, Permissions, Developer Tools details
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) — Building, debugging, regenerating the icon

## Safety in One Sentence

> **Items are moved to Trash, never deleted directly** — and the `SafetyGuard` rejects anything under `/System`, `/Library`, `/usr`, `/Applications`, your work directories, and any path containing `.git`, `.env`, `.ssh`, credentials, or `node_modules`.

## Support

If Bytegone saved you some disk space, consider [buying me a coffee](https://buymeacoffee.com/pakortra).

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT License](LICENSE) — see [LICENSE](LICENSE) for details.

# Developer Tools

Bytegone includes a dedicated view for reclaiming space from developer-specific toolchains and runtimes. It distinguishes between **automated** tools (integrated check + clean) and **recommended** tools (command-only guidance).

---

## Tool types

| Tool | Type | Automation | Binary |
|---|---|---|---|
| Docker | Automated | Check + Clean | `docker` |
| Homebrew | Automated | Check + Clean | `brew` |
| npkill | Recommended | Command only | — |
| cargo-sweep | Recommended | Command only | — |

---

## Automated tools

### Shell runner

`ShellRunner.run` executes commands through the user's login shell (`/bin/zsh -l`) so that Homebrew and other PATH additions are available:

```swift
process.arguments = [
    "-l", "-c",
    "export PATH=\"/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH\"; \(command)"
]
```

This ensures `docker` and `brew` are found regardless of whether the user uses Apple Silicon or Intel Homebrew paths.

### Detection

On view appear, `DevToolsStore.refreshInstallStatus()` checks each automated tool:

```swift
await ShellRunner.isInstalled("docker")  // command -v docker
await ShellRunner.isInstalled("brew")    // command -v brew
```

Status is reflected as a pill: **Installed**, **Not installed**, or **Checking…**.

### Check (size estimate)

| Tool | Command | Parsed output |
|---|---|---|
| Docker | `docker system df` | Looks for "Total reclaimable" line |
| Homebrew | `brew cleanup -n` | Looks for "would free" or "removed" line |

The parsed estimate is shown as a badge on the card.

### Clean

| Tool | Command | Timeout |
|---|---|---|
| Docker | `docker system prune -a --volumes -f` | 600s |
| Homebrew | `brew cleanup -s` | 90s |

Output is captured into an expandable panel. The user can copy the full output to the pasteboard.

### Warning text

Each automated tool shows a contextual warning:

- **Docker:** "Removes ALL data not attached to a running container. Make sure your stack is running before cleanup if you depend on a volume."
- **Homebrew:** "Safe — only deletes downloads and outdated versions Homebrew already considers reclaimable."

---

## Recommended tools

These tools require project-level judgment (which directories to clean), so Bytegone does not run them automatically. Instead, it surfaces a copyable command.

### npkill — node_modules cleanup

```
npx npkill
```

Interactive TUI that finds `node_modules` folders across the filesystem and lets the user choose which to delete.

### cargo-sweep — Rust target cleanup

```
cargo install cargo-sweep && cargo sweep -r -t 30 ~
```

Recursively removes Rust `target/` directories older than 30 days.

### UX pattern

- Card shows **RECOMMENDED** badge.
- Command is displayed in a monospace text block with **Copy** button.
- Copy feedback: checkmark icon + "Copied" text for 1.5 seconds.

---

## State machine

Each tool has a `ToolState` with status:

```
unknown → checking → installed / notInstalled
installed → running → idle
idle → running → idle
```

The `DevToolsStore` holds a dictionary of `[DeveloperTool: ToolState]`.

---

## UI

- **Header:** Icon + title + summary + refresh button.
- **Automated cards:** Status pill, summary, warning, Check button, Run cleanup button, command label, progress indicator, expandable output panel.
- **Recommendation cards:** Icon, summary, rationale for not auto-running, copyable command block.
- **Hover:** Cards lift with accent-colored glow and shadow.

---

## Known limitations

- **Shell timeout ignored:** `ShellRunner.run` accepts a `timeout` parameter but does not enforce it. A hung Docker daemon could block the app indefinitely. This is a known issue tracked for fix.
- **No `sudo` tools:** Bytegone never elevates privileges. Tools requiring `sudo` (e.g., `brew cleanup` under some configurations) may fail silently.
- **PATH assumptions:** The injected PATH covers `/opt/homebrew` and `/usr/local`. Non-standard installations may not be detected.

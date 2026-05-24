# Install Bytegone

> Bytes, bygone.

## Requirements
- macOS **14** (Sonoma) or later
- About 10 MB of disk space

## Install — choose either

### From the DMG (recommended)
1. Double-click `Bytegone.dmg`.
2. Drag `Bytegone` onto the **Applications** shortcut in the window.
3. Eject the DMG.

### From the zip
1. Unzip `Bytegone.zip`.
2. Move `Bytegone.app` into `/Applications` (or anywhere you like).

## First launch — bypass Gatekeeper

This build is **ad-hoc signed** (not notarized by Apple), so the first time you open it macOS will refuse with:

> "Bytegone can't be opened because Apple cannot check it for malicious software."

Get past this once with either method:

**A. One-time right-click**
1. In Finder, right-click `Bytegone.app`.
2. Choose **Open**.
3. Click **Open** in the warning dialog.

macOS remembers and won't ask again.

**B. Terminal**
```sh
xattr -dr com.apple.quarantine /Applications/Bytegone.app
```

## Grant Full Disk Access (optional but recommended)

Some app caches live in protected directories. To detect them all:

1. Open Bytegone and click **Permissions** in the sidebar.
2. Click **Open System Settings** — it deep-links straight to the right pane.
3. Toggle **Bytegone** on in *Privacy & Security → Full Disk Access*.
4. Return to Bytegone. The status updates automatically.

Without FDA the app still works, you'll just see less under "App Container Caches".

## Safety in brief

- Every removal is **Move to Trash** — recoverable. Nothing is `rm`-ed.
- The app refuses to touch system directories (`/System`, `/Library`, `/usr`, `/Applications`, etc.).
- Any path containing `.git`, `.env`, `.ssh`, `.aws/credentials`, `id_rsa`, `node_modules`, or `*.keychain` is blocked.
- The scanner only ever enters known cache / build-artifact directories — never your project folders.

## Note for first-time use

Click **Schedule** in the sidebar if you want it to clean up automatically on a daily/weekly cadence.

## Uninstall

Drag `Bytegone.app` from `/Applications` to the Trash. To remove its preferences and schedule history too:
```sh
defaults delete com.pakorn.bytegone
```

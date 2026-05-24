#!/usr/bin/env bash
# Build Bytegone.app bundle from the SPM target.
set -euo pipefail

APP_NAME="Bytegone"
BUNDLE_ID="com.example.bytegone"
DIST_DIR="dist"
APP_DIR="${DIST_DIR}/${APP_NAME}.app"

cd "$(dirname "$0")"

echo "▸ Compiling release binary…"
if ! swift build -c release --arch arm64 --arch x86_64 >/dev/null 2>&1; then
    swift build -c release
    BIN_PATH="$(swift build -c release --show-bin-path)/${APP_NAME}"
else
    BIN_PATH=".build/apple/Products/Release/${APP_NAME}"
fi

if [[ ! -f "$BIN_PATH" ]]; then
    BIN_PATH="$(swift build -c release --show-bin-path)/${APP_NAME}"
fi

[[ -f "$BIN_PATH" ]] || { echo "❌ Could not locate built binary"; exit 1; }

# Generate the icon if it's missing.
if [[ ! -f Resources/AppIcon.icns && -f Tools/make-icon.sh ]]; then
    echo "▸ Generating app icon…"
    ./Tools/make-icon.sh
fi

echo "▸ Assembling app bundle…"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp Info.plist "$APP_DIR/Contents/Info.plist"

if [[ -f Resources/AppIcon.icns ]]; then
    cp Resources/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

# Ad-hoc sign so Gatekeeper lets it run from outside the build tree.
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || true

# Bust the icon cache for this bundle so Finder picks up the new icon.
touch "$APP_DIR"

echo "✓ Built: $APP_DIR"
echo "  Run:  open \"$APP_DIR\""
echo "  Install:  cp -R \"$APP_DIR\" /Applications/"

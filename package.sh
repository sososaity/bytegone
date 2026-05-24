#!/usr/bin/env bash
# Package Bytegone.app for distribution: produces dist/Bytegone.dmg and dist/Bytegone.zip
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Bytegone"
DIST_DIR="dist"
APP_DIR="${DIST_DIR}/${APP_NAME}.app"
STAGING="${DIST_DIR}/.staging"
DMG_OUT="${DIST_DIR}/${APP_NAME}.dmg"
ZIP_OUT="${DIST_DIR}/${APP_NAME}.zip"

echo "▸ Building app…"
./build.sh >/dev/null

[[ -d "$APP_DIR" ]] || { echo "❌ Build did not produce $APP_DIR"; exit 1; }

echo "▸ Stripping extended attributes…"
xattr -cr "$APP_DIR" 2>/dev/null || true

echo "▸ Staging DMG layout…"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP_DIR" "$STAGING/"
ln -sf /Applications "$STAGING/Applications"
cp INSTALL.md "$STAGING/INSTALL.md"

echo "▸ Creating DMG…"
rm -f "$DMG_OUT"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG_OUT" >/dev/null

echo "▸ Creating zip…"
rm -f "$ZIP_OUT"
(cd "$DIST_DIR" && zip -qr "${APP_NAME}.zip" "${APP_NAME}.app")

cp INSTALL.md "${DIST_DIR}/INSTALL.md"
rm -rf "$STAGING"

echo
echo "✓ Done — share either of these:"
printf "    %-40s %s\n" "$DMG_OUT"  "($(du -h "$DMG_OUT"  | cut -f1))"
printf "    %-40s %s\n" "$ZIP_OUT"  "($(du -h "$ZIP_OUT"  | cut -f1))"
printf "    %-40s %s\n" "$DIST_DIR/INSTALL.md" "(send with the zip)"
echo
echo "Tip: AirDrop the DMG — single file, double-click experience for your friend."

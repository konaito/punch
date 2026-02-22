#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "==> Building Punch (release)..."
swift build -c release

echo "==> Creating Punch.app bundle..."
APP_DIR="Punch.app/Contents/MacOS"
RESOURCES_DIR="Punch.app/Contents/Resources"
mkdir -p "$APP_DIR" "$RESOURCES_DIR"
cp .build/release/Punch "$APP_DIR/Punch"
cp Resources/Info.plist Punch.app/Contents/Info.plist

# Ad-hoc sign (recipients: right-click > Open, or xattr -cr Punch.app)
echo "==> Signing (ad-hoc)..."
codesign --force --sign - Punch.app

# Create DMG for distribution
echo "==> Creating DMG..."
DMG_NAME="Punch-Installer.dmg"
DMG_TEMP="dmg_tmp"

rm -rf "$DMG_TEMP" "$DMG_NAME"
mkdir -p "$DMG_TEMP"
cp -R Punch.app "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

hdiutil create -volname "Punch" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_NAME" \
    -quiet

rm -rf "$DMG_TEMP"

echo ""
echo "==> Done!"
echo "  App:  Punch.app"
echo "  DMG:  $DMG_NAME ($(du -h "$DMG_NAME" | cut -f1))"
echo ""
echo "配布方法:"
echo "  DMGを共有 → 受け取った人は右クリック→「開く」で起動"
echo "  またはターミナルで: xattr -cr Punch.app && open Punch.app"

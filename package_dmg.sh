#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=== Step 1: Building Release App Bundle ==="
./build.sh

APP_SRC=".build/app_bundle/ArjunClipper.app"
DMG_STAGING=".build/dmg_staging"
DMG_NAME="ArjunClipper"
FINAL_DMG="ArjunClipper.dmg"

echo "=== Step 2: Preparing DMG Staging Directory ==="
rm -rf "$DMG_STAGING" "$FINAL_DMG"
mkdir -p "$DMG_STAGING"

# Copy the app bundle
cp -R "$APP_SRC" "$DMG_STAGING/ArjunClipper.app"

# Create symlink to /Applications for standard drag-and-drop install
ln -s /Applications "$DMG_STAGING/Applications"

# Add a simple, clear instruction file for users downloading the DMG
cat << 'README_EOF' > "$DMG_STAGING/HOW_TO_INSTALL.txt"
======================================================
              ArjunClipper - Installation
======================================================

1. Drag 'ArjunClipper.app' into the 'Applications' shortcut.
2. Open ArjunClipper from your Applications folder.

* First-Time Opening Tip (macOS Gatekeeper):
  Because this app is independently distributed without
  an Apple Developer ID:
  - If macOS displays "Unidentified Developer", simply
    Right-Click (or Control-Click) ArjunClipper.app in
    Applications and select "Open", then click "Open".
  - Alternatively: Go to System Settings -> Privacy &
    Security and click "Open Anyway".
  (You only need to do this once; macOS remembers forever!)

3. Global Shortcut:
    Press ⌘ + ⇧ + V (Command + Shift + V) anywhere to open
    your clipboard history!

4. Run Forever at Login:
    Click the 'A' icon in the top menu bar -> Preferences ->
    toggle "Launch at Login".

Enjoy using ArjunClipper!
======================================================
README_EOF

echo "=== Step 3: Creating Compressed Read-Only DMG ==="
hdiutil create \
    -volname "$DMG_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$FINAL_DMG"

# Cleanup staging
rm -rf "$DMG_STAGING"

echo "=== Step 4: Verifying DMG Integrity ==="
hdiutil verify "$FINAL_DMG"

DMG_SIZE=$(du -h "$FINAL_DMG" | cut -f1)
DMG_SHA256=$(shasum -a 256 "$FINAL_DMG" | cut -d ' ' -f1)

echo ""
echo "=========================================================="
echo "  🎉 ArjunClipper.dmg successfully packaged!"
echo "  - File:      $DIR/$FINAL_DMG"
echo "  - Size:      $DMG_SIZE"
echo "  - SHA256:    $DMG_SHA256"
echo "=========================================================="
echo "You can now upload $FINAL_DMG to GitHub Releases, Google Drive,"
echo "Dropbox, or your website for anyone to download and use forever."
echo "=========================================================="

#!/usr/bin/env bash
set -euo pipefail

echo "=== Building ArjunClipper in Release Mode (Universal Binary: arm64 + x86_64) ==="
swift build -c release --arch arm64 --arch x86_64

if [ -f ".build/out/Products/Release/ArjunClipper" ]; then
    BIN_PATH=".build/out/Products/Release/ArjunClipper"
else
    BIN_PATH="$(swift build -c release --show-bin-path)/ArjunClipper"
fi
TEMP_DIR=".build/app_bundle/ArjunClipper.app"
CONTENTS_DIR="$TEMP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "=== Creating App Bundle in temporary build directory ==="
rm -rf "$TEMP_DIR" "dist"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BIN_PATH" "$MACOS_DIR/ArjunClipper"

if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ArjunClipper</string>
    <key>CFBundleIdentifier</key>
    <string>com.arjun.arjunclipper</string>
    <key>CFBundleName</key>
    <string>ArjunClipper</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <string>1</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>ArjunClipper needs permission to paste clippings into active applications.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>ArjunClipper uses accessibility features to detect hotkeys and simulate paste commands.</string>
</dict>
</plist>
EOF

codesign -s - --force -r='designated => identifier "com.arjun.arjunclipper"' "$TEMP_DIR"

echo "=== App bundle built successfully at $TEMP_DIR ==="

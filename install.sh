#!/usr/bin/env bash
set -euo pipefail

DEST_APP="/Applications/ArjunClipper.app"
SOURCE_APP=".build/app_bundle/ArjunClipper.app"
PLIST_PATH="$HOME/Library/LaunchAgents/com.arjun.arjunclipper.plist"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

echo "=== Terminating and Cleaning Up Old Instances ==="
# Terminate old ArjunCopy and Flycut services
launchctl unload "$HOME/Library/LaunchAgents/com.arjun.arjuncopy.plist" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.arjun.arjuncopy.plist"
killall ArjunCopy 2>/dev/null || true
rm -rf "/Applications/ArjunCopy.app"

launchctl unload "$HOME/Library/LaunchAgents/com.generalarcade.flycutx.plist" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.generalarcade.flycutx.plist"
killall FlycutX 2>/dev/null || true
killall Flycut 2>/dev/null || true

# Terminate running ArjunClipper before updating
launchctl unload "$PLIST_PATH" 2>/dev/null || true
killall ArjunClipper 2>/dev/null || true

# Unregister ghost / duplicate bundles from LaunchServices
if [ -x "$LSREGISTER" ]; then
    "$LSREGISTER" -u "/Applications/ArjunCopy.app" 2>/dev/null || true
    "$LSREGISTER" -u "/Applications/FlycutX.app" 2>/dev/null || true
fi

echo "=== Installing ArjunClipper to $DEST_APP ==="
rm -rf "$DEST_APP"
cp -R "$SOURCE_APP" "$DEST_APP"

# Codesign in-place in /Applications with stable designated requirement
codesign -s - --force -r='designated => identifier "com.arjun.arjunclipper"' "$DEST_APP"

# Update touch timestamp so Finder and LaunchServices see modification
touch "$DEST_APP"

# Register the installed app in LaunchServices
if [ -x "$LSREGISTER" ]; then
    echo "=== Registering App & Icon in LaunchServices ==="
    "$LSREGISTER" -f "$DEST_APP"
fi

echo "=== Configuring Autostart (LaunchAgent) ==="
mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.arjun.arjunclipper</string>
    <key>ProgramArguments</key>
    <array>
        <string>$DEST_APP/Contents/MacOS/ArjunClipper</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardOutPath</key>
    <string>/tmp/arjunclipper.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/arjunclipper.log</string>
</dict>
</plist>
EOF

# Start service
launchctl load -w "$PLIST_PATH"

# Refresh Dock / Launchpad cache
killall Dock 2>/dev/null || true

echo ""
echo "=========================================================="
echo "  ArjunClipper is now installed with its custom logo icon!"
echo "  - Installed at: $DEST_APP"
echo "  - Embedded Icon: $DEST_APP/Contents/Resources/AppIcon.icns"
echo "  - Ghost/duplicate app registrations removed"
echo "  - Launchpad & Dock icon cache refreshed"
echo "  - Global Shortcut: ⌘ + ⇧ + V"
echo "=========================================================="

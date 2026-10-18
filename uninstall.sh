#!/usr/bin/env bash
set -euo pipefail

DEST_APP="/Applications/ArjunClipper.app"
PLIST_PATH="$HOME/Library/LaunchAgents/com.arjun.arjunclipper.plist"

echo "=== Removing ArjunClipper ==="
launchctl unload "$PLIST_PATH" 2>/dev/null || true
rm -f "$PLIST_PATH"
rm -rf "$DEST_APP"
killall ArjunClipper 2>/dev/null || true

# Also cleanup legacy ArjunCopy if present
launchctl unload "$HOME/Library/LaunchAgents/com.arjun.arjuncopy.plist" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.arjun.arjuncopy.plist"
rm -rf "/Applications/ArjunCopy.app"
killall ArjunCopy 2>/dev/null || true

echo "ArjunClipper has been uninstalled."

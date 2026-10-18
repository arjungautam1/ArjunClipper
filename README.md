# ArjunClipper 📋✨

A modern, high-performance clipboard manager for macOS with intelligent privacy filtering, HUD bezel preview, and persistent background execution. Reverse engineered and completely rebuilt from Flycut with modern Swift, SwiftUI, and AppKit.

---

## Download & Distribution

The distributable macOS Disk Image (`.dmg`) is ready for sharing and downloading:

- **File**: `ArjunClipper.dmg`
- **Location**: `ArjunClipper.dmg` (in repository root)
- **Size**: ~3.0 MB (Compressed UDZO read-only image)

### How to Install from DMG:
1. Double-click `ArjunClipper.dmg` to open it.
2. Drag **ArjunClipper.app** into the **Applications** folder shortcut.
3. Launch ArjunClipper from Applications or Spotlight.
4. Press **⌘ + ⇧ + V** (Command + Shift + V) anywhere to open your clipboard history.

---

## Features

- **Global Hotkey (⌘ + ⇧ + V)**: Quick bezel overlay HUD for browsing and cycling through previous clippings.
- **Auto-Paste**: Select a clipping and hit `Enter` (or click) to paste directly into your active application.
- **Status Bar Icon**: Clean, native Apple **A** sign icon in the macOS menu bar.
- **Smart Privacy & Security Filtering**:
  - Automatically ignores transient/concealed pasteboard types from password managers (1Password, Bitwarden, KeePassXC).
  - Blocks sensitive patterns: Private keys (PEM/RSA/OpenSSH), credit card numbers, JWT tokens, and API keys.
  - Skips empty and whitespace-only clippings.
- **Application Exclusion List**: Ignore clipboard copies from specific apps (e.g., Terminal, Keychain).
- **Persistent Background Execution**: Runs via LaunchAgent (`~/Library/LaunchAgents/com.arjun.arjunclipper.plist`) so it stays active across reboots.

---

## Development Scripts

- `./build.sh` — Compiles the release binary and packages `.build/app_bundle/ArjunClipper.app`.
- `./install.sh` — Installs to `/Applications/ArjunClipper.app`, registers LaunchServices, and configures the background LaunchAgent.
- `./package_dmg.sh` — Rebuilds and packages a fresh `ArjunClipper.dmg` with drag-and-drop installer.
- `swift test` — Executes the 5/5 unit test suite.

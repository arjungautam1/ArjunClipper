# Reverse Engineering Report: Flycut for macOS (v1.9.6)
**Analyzed with REA (Reverse Engineer Anything) & Hopper Disassembler**  
**Target:** `/Applications/Flycut.app/Contents/MacOS/Flycut`  
**Architecture:** Universal Mach-O (ARM64 / x86_64) | Thin ARM64 Slice (235,600 bytes)  
**Evidence Bundle:** `flycut_rea_evidence.json`

---

## 1. Executive Summary & Binary Identification
Flycut is a popular open-source clipboard management utility for macOS, descended from Jumpcut. Using REA's inspection and decompilation engines, we examined the native Mach-O binary, its Objective-C class hierarchy, internal state machines, pasteboard monitoring loop, filtering criteria, and preference structures.

### Key Binary Metadata
- **Bundle ID:** `com.generalarcade.flycut`
- **Version:** `1.9.6` (Build `9`)
- **App Type:** `LSUIElement = 1` (Agent/Status bar application without a Dock icon)
- **Principal Class:** `NSApplication`
- **Main Nib:** `MainMenu`
- **Permission String:** `NSAppleEventsUsageDescription` ("Flycut needs this permission to be able to paste text into other applications")

---

## 2. Core Architecture & Component Map

Through Hopper and REA procedure and class scanning (`get_objc_classes`, `search_procedures`), we recovered the 4 primary components:

```
┌────────────────────────────────────────────────────────────────────────┐
│                             AppController                              │
│  - NSStatusItem (Menu Bar)                                             │
│  - NSTimer (Pasteboard Polling at 0x100005b34)                         │
│  - Global HotKey / ShortcutRecorder                                    │
│  - Bezel Window (HUD display)                                          │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │ delegates
┌──────────────────────────────────▼─────────────────────────────────────┐
│                            FlycutOperator                              │
│  - Clipping filter engine (shouldSkip:ofType: at 0x10000e7e0)          │
│  - Stack position pointer & traversal navigation                       │
│  - Primary Store & Favorites Store coordination                        │
│  - CloudKit / iCloud sync logic (MJCloudKitUserDefaultsSync)           │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │ manages
┌──────────────────────────────────▼─────────────────────────────────────┐
│                             FlycutStore                                │
│  - NSMutableArray of FlycutClipping objects                            │
│  - FIFO pruning based on `jcRememberNum`                               │
│  - Menu display formatting based on `jcDisplayNum` & `displayLen`      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Reverse-Engineered Mechanics

### 3.1 Pasteboard Polling Mechanism (`-[AppController pollPB:]`)
*Decompiled from `0x100005b34`:*
- Uses an `NSTimer` scheduled on `NSRunLoopCommonModes`.
- At each tick, queries `[[NSPasteboard generalPasteboard] changeCount]`.
- Compares against stored `_lastChangeCount`.
- **App Detection:** Scans `[[NSWorkspace sharedWorkspace] runningApplications]` looking for `isActive == YES` to record the bundle ID and localized app name of the source.
- **Hardcoded Workaround:** Contains a hardcoded string comparison ignoring pastes from `"Remote Desktop Connection"`.

### 3.2 Filtering & Skip Logic (`-[FlycutOperator shouldSkip:ofType:]`)
*Decompiled from `0x10000e7e0`:*
- Checks `skipPasswordFields` boolean from `NSUserDefaults`.
- Checks `skipPboardTypesList` (comma-separated string parsed into array).
- Checks `skipPasswordLengths` and tests `[content length]` against `skipPasswordLengthsList`.
- **Critical Vulnerability / Limitations:**
  1. No application-based blacklist/ignore list (e.g., 1Password, Bitwarden, Keychain, Terminal).
  2. No regex pattern matching (e.g. credit cards, auth tokens, AWS credentials).
  3. No maximum byte size ceiling (large multi-megabyte copies can degrade memory).
  4. Only checks `NSStringPboardType`, ignoring rich metadata or selective MIME handling.

### 3.3 Storage & Show Limits (`FlycutStore` & `AppController`)
- **`rememberNum` (`jcRememberNum`):** Maximum items preserved in memory/plist (default range 10–100 via slider).
- **`displayNum` (`jcDisplayNum`):** Maximum items rendered in the status menu (capped at 40 in standard preferences).
- **`displayLen`:** Maximum character length displayed before truncation with ellipses.

---

## 4. Modern Improvements Designed for "FlycutX"
Based on our reverse engineering analysis, we address Flycut's limitations with modern enhancements:

| Feature Area | Legacy Flycut (Decompiled) | Modern FlycutX (Our Implementation) |
| :--- | :--- | :--- |
| **App Exclusions** | Hardcoded only for "Remote Desktop Connection" | Configurable blacklist (1Password, Terminal, Keychain, etc.) |
| **Sensitive Data** | Length-check heuristic only | High-accuracy Regex filters (API keys, Credit Cards, JWTs, Private Keys) |
| **Transient Clips** | Basic check on `skipPboardTypesList` | Full compliance with macOS `TransientType`, `ConcealedType`, `AutoGeneratedType` |
| **History Capacity** | Slider bounded to 10–100 items | Configurable up to 2,000 items with memory-efficient indexing |
| **Show Control** | Limited to 40 items in flat list | Dynamic show limit (5 to 100+), submenus, live search filter |
| **Size Ceilings** | Unbounded (causes memory pressure) | Configurable min length (e.g., ignore 1 char) & max length (e.g., ignore > 500KB) |
| **Favorites / Pin** | Separate second store | Native pinned items that stay anchored and never get evicted |
| **Modern UI** | 10-year old Cocoa nibs | Modern Swift, macOS design, Glassmorphic Bezel HUD, and live settings |

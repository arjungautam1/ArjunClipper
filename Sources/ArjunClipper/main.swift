import AppKit
import ApplicationServices
import ArjunClipperLib

// Ensure immediate unbuffered file logging
freopen("/tmp/arjunclipper.log", "a", stdout)
freopen("/tmp/arjunclipper.log", "a", stderr)
setbuf(stdout, nil)
setbuf(stderr, nil)

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check Accessibility permission and prompt if needed
        let promptDict = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let isAccessibilityTrusted = AXIsProcessTrustedWithOptions(promptDict)
        print("[ArjunClipper] Accessibility permissions trusted: \(isAccessibilityTrusted)")
        
        if !isAccessibilityTrusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "ArjunClipper needs Accessibility permission to automatically paste clippings into other applications (Chrome, Xcode, Terminal, etc.) when you press ⌘+⇧+V.\n\nPlease enable ArjunClipper in System Settings."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Later")
                
                NSApp.activate(ignoringOtherApps: true)
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        
        // Monitor local key down events when Bezel is visible
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard BezelWindowController.shared.isWindowVisible else {
                return event
            }
            
            if event.keyCode == 53 { // Escape
                BezelWindowController.shared.dismiss()
                return nil
            } else if event.keyCode == 36 || event.keyCode == 76 || event.keyCode == 49 { // Return, Enter, Space
                BezelWindowController.shared.pasteCurrent()
                return nil
            } else if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "v" {
                BezelWindowController.shared.pasteCurrent()
                return nil
            } else if event.keyCode == 126 || event.keyCode == 123 { // Up or Left arrow
                BezelWindowController.shared.showPrevious()
                return nil
            } else if event.keyCode == 125 || event.keyCode == 124 { // Down or Right arrow
                BezelWindowController.shared.showNext()
                return nil
            }
            return event
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        PasteboardMonitor.shared.stop()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Equivalent to LSUIElement=1

// Initialize core services immediately on startup
MenuBarController.shared.setup()
PasteboardMonitor.shared.start()
GlobalHotkeyManager.shared.registerDefaultHotkey(
    onPress: {
        BezelWindowController.shared.handleHotkeyPress()
    },
    onRelease: {
        BezelWindowController.shared.handleHotkeyRelease()
    }
)

print("[ArjunClipper] Initialized services with Press & Release hotkey listeners. Running main loop.")
app.run()


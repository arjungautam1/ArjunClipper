import Foundation
import AppKit

public final class MenuBarController: NSObject, NSMenuDelegate {
    public static let shared = MenuBarController()
    
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    
    public override init() {
        super.init()
    }
    
    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusButton()
        menu.delegate = self
        statusItem.menu = menu
    }
    
    public func updateStatusButton() {
        guard let button = statusItem?.button else { return }
        
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 15.5, weight: .bold)
        if let aImage = NSImage(systemSymbolName: "a", accessibilityDescription: "ArjunClipper")?.withSymbolConfiguration(symbolConfig) {
            aImage.isTemplate = true
            button.image = aImage
        } else {
            button.image = createASignFallbackIcon()
        }
        
        if PreferencesManager.shared.showMenuBarTitle {
            button.imagePosition = .imageLeading
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12.0, weight: .semibold)
            ]
            button.attributedTitle = NSAttributedString(string: " Arjun", attributes: attrs)
        } else {
            button.imagePosition = .imageOnly
            button.attributedTitle = NSAttributedString(string: "")
            button.title = ""
        }
    }
    
    private func createASignFallbackIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let font = NSFont.systemFont(ofSize: 15.0, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black
            ]
            let str = NSAttributedString(string: "A", attributes: attrs)
            let strSize = str.size()
            let pt = NSPoint(x: (rect.width - strSize.width) / 2.0, y: (rect.height - strSize.height) / 2.0 - 0.5)
            str.draw(at: pt)
            return true
        }
        image.isTemplate = true
        return image
    }
    
    public func menuWillOpen(_ menu: NSMenu) {
        if let front = NSWorkspace.shared.frontmostApplication,
           front.bundleIdentifier != Bundle.main.bundleIdentifier {
            BezelWindowController.shared.setPreviousApp(front)
        }
        PasteboardMonitor.shared.checkPasteboard()
        updateMenu()
    }
    
    public func updateMenu() {
        menu.removeAllItems()
        
        let store = ClippingStore.shared
        let prefs = PreferencesManager.shared
        let allClippings = store.clippings
        let displayCount = prefs.displayLimit
        let previewLen = prefs.previewLength
        
        // Accessibility Permission Notice (if needed)
        if !AXIsProcessTrusted() {
            let warnItem = NSMenuItem(
                title: "⚠️ Enable Accessibility to Auto-Paste...",
                action: #selector(openAccessibilitySettings),
                keyEquivalent: ""
            )
            warnItem.target = self
            menu.addItem(warnItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Pinned Section
        let pinned = allClippings.filter { $0.isPinned }
        if !pinned.isEmpty {
            let pinnedHeader = NSMenuItem(title: "📌 Pinned Items (\(pinned.count))", action: nil, keyEquivalent: "")
            pinnedHeader.isEnabled = false
            menu.addItem(pinnedHeader)
            
            for clip in pinned {
                let item = makeClippingMenuItem(clipping: clip, maxLength: previewLen, isPinnedSection: true)
                menu.addItem(item)
            }
            menu.addItem(NSMenuItem.separator())
        }
        
        // Recent Clippings Section
        let recentHeader = NSMenuItem(title: "Recent History (Showing \(min(displayCount, allClippings.count)) of \(allClippings.count))", action: nil, keyEquivalent: "")
        recentHeader.isEnabled = false
        menu.addItem(recentHeader)
        
        if allClippings.isEmpty {
            let emptyItem = NSMenuItem(title: "Clipboard history is empty", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            let displayed = allClippings.prefix(displayCount)
            for (index, clip) in displayed.enumerated() {
                let item = makeClippingMenuItem(clipping: clip, maxLength: previewLen, index: index + 1)
                menu.addItem(item)
            }
            
            // If total clippings > displayLimit, offer a "More History" submenu
            if allClippings.count > displayCount {
                let moreMenu = NSMenu()
                let remaining = allClippings.dropFirst(displayCount)
                for (subIndex, clip) in remaining.prefix(100).enumerated() {
                    let subItem = makeClippingMenuItem(clipping: clip, maxLength: previewLen, index: displayCount + subIndex + 1)
                    moreMenu.addItem(subItem)
                }
                let moreItem = NSMenuItem(title: "Older Clippings (\(allClippings.count - displayCount) more)...", action: nil, keyEquivalent: "")
                moreItem.submenu = moreMenu
                menu.addItem(moreItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Actions
        let bezelItem = NSMenuItem(title: "Show Bezel HUD", action: #selector(showBezelHUD), keyEquivalent: "V")
        bezelItem.keyEquivalentModifierMask = [.command, .shift]
        bezelItem.target = self
        menu.addItem(bezelItem)
        
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)
        
        let clearItem = NSMenuItem(title: "Clear Unpinned History", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        menu.addItem(clearItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit ArjunClipper", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    private func makeClippingMenuItem(clipping: Clipping, maxLength: Int, index: Int? = nil, isPinnedSection: Bool = false) -> NSMenuItem {
        let prefix = index != nil ? "\(index!). " : ""
        let preview = clipping.preview(maxLength: maxLength)
        let title = "\(prefix)\(preview)"
        
        let item = NSMenuItem(title: title, action: #selector(clippingSelected(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = clipping
        
        // Submenu for extra actions on each clipping (Pin / Delete / Copy)
        let sub = NSMenu()
        
        let copySub = NSMenuItem(title: "Copy to Clipboard", action: #selector(clippingSelected(_:)), keyEquivalent: "")
        copySub.target = self
        copySub.representedObject = clipping
        sub.addItem(copySub)
        
        let pinTitle = clipping.isPinned ? "Unpin Clipping" : "Pin to Top"
        let pinItem = NSMenuItem(title: pinTitle, action: #selector(togglePin(_:)), keyEquivalent: "")
        pinItem.target = self
        pinItem.representedObject = clipping
        sub.addItem(pinItem)
        
        let delItem = NSMenuItem(title: "Delete from History", action: #selector(deleteClipping(_:)), keyEquivalent: "")
        delItem.target = self
        delItem.representedObject = clipping
        sub.addItem(delItem)
        
        if let app = clipping.sourceAppName {
            sub.addItem(NSMenuItem.separator())
            let appItem = NSMenuItem(title: "Source: \(app)", action: nil, keyEquivalent: "")
            appItem.isEnabled = false
            sub.addItem(appItem)
        }
        
        item.submenu = sub
        return item
    }
    
    @objc private func clippingSelected(_ sender: NSMenuItem) {
        guard let clipping = sender.representedObject as? Clipping else { return }
        PasteboardMonitor.shared.copyToClipboard(clipping: clipping)
        BezelWindowController.shared.pasteFromExternal()
    }
    
    @objc private func togglePin(_ sender: NSMenuItem) {
        guard let clipping = sender.representedObject as? Clipping else { return }
        ClippingStore.shared.togglePin(id: clipping.id)
    }
    
    @objc private func deleteClipping(_ sender: NSMenuItem) {
        guard let clipping = sender.representedObject as? Clipping else { return }
        ClippingStore.shared.delete(id: clipping.id)
    }
    
    @objc private func showBezelHUD() {
        BezelWindowController.shared.triggerHotkey()
    }
    
    @objc private func openPreferences() {
        PreferencesWindowController.shared.show()
    }
    
    @objc private func checkForUpdates() {
        UpdateManager.shared.checkForUpdates(silent: false)
    }
    
    @objc private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func clearHistory() {
        ClippingStore.shared.clearAllUnpinned()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

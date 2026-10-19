import Foundation
import AppKit

final class KeyableHUDPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.keyCode == 53 { // Esc
            BezelWindowController.shared.dismiss()
            return true
        } else if event.keyCode == 36 || event.keyCode == 76 { // Return or Enter
            BezelWindowController.shared.pasteCurrent()
            return true
        } else if event.keyCode == 49 { // Space
            BezelWindowController.shared.pasteCurrent()
            return true
        } else if event.keyCode == 126 || event.keyCode == 123 { // Up or Left arrow
            BezelWindowController.shared.showPrevious()
            return true
        } else if event.keyCode == 125 || event.keyCode == 124 { // Down or Right arrow
            BezelWindowController.shared.showNext()
            return true
        } else if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "v" {
            BezelWindowController.shared.pasteCurrent()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Esc
            BezelWindowController.shared.dismiss()
        } else if event.keyCode == 36 || event.keyCode == 76 || event.keyCode == 49 { // Enter, Keypad Enter, Space
            BezelWindowController.shared.pasteCurrent()
        } else if event.keyCode == 126 || event.keyCode == 123 { // Up or Left arrow
            BezelWindowController.shared.showPrevious()
        } else if event.keyCode == 125 || event.keyCode == 124 { // Down or Right arrow
            BezelWindowController.shared.showNext()
        } else if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "v" {
            BezelWindowController.shared.pasteCurrent()
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        BezelWindowController.shared.pasteCurrent()
    }
}

public final class BezelWindowController: NSWindowController {
    public static let shared = BezelWindowController()
    
    private var currentIndex = 0
    private var previousApp: NSRunningApplication?
    private let titleLabel = NSTextField(labelWithString: "")
    private let metaLabel = NSTextField(labelWithString: "")
    private var contentTextView: NSTextView!
    private let scrollView = NSScrollView()
    private var dismissTimer: Timer?
    
    public var isWindowVisible: Bool {
        return window?.isVisible == true
    }
    
    private init() {
        let window = KeyableHUDPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 360),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.appearance = NSAppearance(named: .darkAqua) ?? NSAppearance(named: .vibrantDark)
        
        super.init(window: window)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        guard let window = window else { return }
        
        let visualEffect = NSVisualEffectView(frame: window.contentView!.bounds)
        visualEffect.autoresizingMask = [.width, .height]
        visualEffect.material = .popover
        visualEffect.state = .active
        visualEffect.appearance = NSAppearance(named: .vibrantDark)
        visualEffect.wantsLayer = true
        // 96% dark charcoal slate so white backgrounds (Google Docs, Word, Safari) NEVER wash it out
        visualEffect.layer?.backgroundColor = NSColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 0.96).cgColor
        visualEffect.layer?.cornerRadius = 18
        visualEffect.layer?.masksToBounds = true
        // Crisp, refined glass border for razor-sharp definition against pure white backgrounds
        visualEffect.layer?.borderWidth = 1.0
        visualEffect.layer?.borderColor = NSColor(white: 1.0, alpha: 0.20).cgColor
        
        // Header: Index & Source App
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.frame = NSRect(x: 24, y: 316, width: 260, height: 24)
        visualEffect.addSubview(titleLabel)
        
        metaLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        metaLabel.textColor = NSColor(red: 0.60, green: 0.80, blue: 1.0, alpha: 1.0)
        metaLabel.alignment = .right
        metaLabel.frame = NSRect(x: 284, y: 318, width: 212, height: 20)
        visualEffect.addSubview(metaLabel)
        
        // Dedicated dark contrast well for clipping content
        let contentWell = NSView(frame: NSRect(x: 20, y: 56, width: 480, height: 246))
        contentWell.wantsLayer = true
        contentWell.layer?.backgroundColor = NSColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 0.90).cgColor
        contentWell.layer?.cornerRadius = 10
        contentWell.layer?.masksToBounds = true
        contentWell.layer?.borderWidth = 0.5
        contentWell.layer?.borderColor = NSColor(white: 1.0, alpha: 0.12).cgColor
        visualEffect.addSubview(contentWell)
        
        // ScrollView Content Area inside the well
        let scrollFrame = NSRect(x: 10, y: 8, width: 460, height: 230)
        scrollView.frame = scrollFrame
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autoresizingMask = [.width, .height]
        scrollView.drawsBackground = false
        
        let contentSize = scrollView.contentSize
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(containerSize: NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        
        contentTextView = NSTextView(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
        contentTextView.minSize = NSSize(width: 0.0, height: contentSize.height)
        contentTextView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        contentTextView.isVerticallyResizable = true
        contentTextView.isHorizontallyResizable = false
        contentTextView.autoresizingMask = [.width]
        contentTextView.isEditable = false
        contentTextView.isSelectable = true
        contentTextView.backgroundColor = .clear
        contentTextView.drawsBackground = false
        contentTextView.textColor = NSColor(white: 0.98, alpha: 1.0)
        contentTextView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        
        // Allow clicking on content to paste immediately
        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(pasteButtonClicked))
        contentTextView.addGestureRecognizer(clickRecognizer)
        
        scrollView.documentView = contentTextView
        contentWell.addSubview(scrollView)
        
        // Footer: Action button & shortcut hints
        let pasteButton = NSButton(title: "↵ Paste to Active App", target: self, action: #selector(pasteButtonClicked))
        pasteButton.bezelStyle = .rounded
        pasteButton.bezelColor = NSColor.systemBlue
        pasteButton.contentTintColor = .white
        pasteButton.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        pasteButton.frame = NSRect(x: 20, y: 14, width: 175, height: 30)
        visualEffect.addSubview(pasteButton)
        
        let hintLabel = NSTextField(labelWithString: "↑/↓ Cycle   •   Enter Paste   •   Esc Close")
        hintLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        hintLabel.textColor = NSColor(white: 0.85, alpha: 1.0)
        hintLabel.alignment = .right
        hintLabel.frame = NSRect(x: 200, y: 18, width: 300, height: 20)
        visualEffect.addSubview(hintLabel)
        
        window.contentView = visualEffect
    }
    
    @objc private func pasteButtonClicked() {
        pasteCurrent()
    }
    
    public func setPreviousApp(_ app: NSRunningApplication) {
        if app.bundleIdentifier != Bundle.main.bundleIdentifier {
            self.previousApp = app
        }
    }
    
    public func handleHotkeyPress() {
        if let front = NSWorkspace.shared.frontmostApplication,
           front.bundleIdentifier != Bundle.main.bundleIdentifier {
            self.previousApp = front
        }
        
        PasteboardMonitor.shared.checkPasteboard()
        let count = ClippingStore.shared.clippings.count
        guard count > 0 else {
            print("[ArjunClipper] No clippings available to show")
            return
        }
        
        if window?.isVisible == true {
            print("[ArjunClipper] Hotkey pressed while HUD visible -> Cycling to next clipping")
            showNext()
        } else {
            print("[ArjunClipper] Hotkey pressed -> Presenting Bezel HUD")
            currentIndex = 0
            updateContent()
            present()
        }
    }
    
    public func handleHotkeyRelease() {
        // No-op: Keep bezel HUD visible on screen ("sticky bezel") so the user can see, read, and choose.
        // User pastes with Enter, Space, Cmd+V, or clicking.
    }
    
    public func triggerHotkey() {
        handleHotkeyPress()
    }
    
    public func showNext() {
        let count = ClippingStore.shared.clippings.count
        guard count > 0 else { return }
        currentIndex = (currentIndex + 1) % count
        updateContent()
        present()
        resetDismissTimer()
    }
    
    public func showPrevious() {
        let count = ClippingStore.shared.clippings.count
        guard count > 0 else { return }
        currentIndex = (currentIndex - 1 + count) % count
        updateContent()
        present()
        resetDismissTimer()
    }
    
    private var isPasting = false
    
    public func pasteCurrent() {
        guard !isPasting else { return }
        isPasting = true
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        let clippings = ClippingStore.shared.clippings
        guard currentIndex < clippings.count else {
            dismiss()
            isPasting = false
            return
        }
        let current = clippings[currentIndex]
        
        print("[ArjunClipper] pasteCurrent() executing for: '\(current.content.prefix(30))...'")
        
        // 1. Put clipping onto system general pasteboard
        PasteboardMonitor.shared.copyToClipboard(clipping: current)
        
        // 2. Hide HUD and reset alpha for next display
        window?.orderOut(nil)
        window?.alphaValue = 1.0
        
        // 3. Reactivate previous app
        let targetApp = previousApp ?? NSWorkspace.shared.runningApplications.first(where: {
            $0.isActive && $0.bundleIdentifier != Bundle.main.bundleIdentifier
        })
        if let target = targetApp {
            print("[ArjunClipper] Activating target: \(target.localizedName ?? "unknown") (PID: \(target.processIdentifier))")
            target.activate()
        }
        
        // 4. Synthesize Cmd+V into the target application after focus switch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.simulatePasteKeystroke()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.isPasting = false
            }
        }
    }
    
    public func pasteFromExternal() {
        guard !isPasting else { return }
        isPasting = true
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        let targetApp = previousApp ?? NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier != Bundle.main.bundleIdentifier && $0.activationPolicy == .regular
        })
        if let target = targetApp {
            print("[ArjunClipper] pasteFromExternal: Activating target: \(target.localizedName ?? "unknown") (PID: \(target.processIdentifier))")
            target.activate()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.simulatePasteKeystroke()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.isPasting = false
            }
        }
    }
    
    private func simulatePasteKeystroke() {
        print("[ArjunClipper] Dispatching single Cmd+V paste...")
        
        let src = CGEventSource(stateID: .privateState)
        let vKeyCode: CGKeyCode = 9 // ANSI 'V'
        
        if let keyDown = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: true),
           let keyUp = CGEvent(keyboardEventSource: src, virtualKey: vKeyCode, keyDown: false) {
            
            keyDown.flags = .maskCommand
            keyUp.flags = .maskCommand
            
            // Single, clean post to system HID tap
            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)
            print("[ArjunClipper] Single Cmd+V posted successfully to cghidEventTap")
        }
    }
    
    private func updateContent() {
        let clippings = ClippingStore.shared.clippings
        guard currentIndex < clippings.count else { return }
        let item = clippings[currentIndex]
        
        titleLabel.stringValue = "Clipping #\(currentIndex + 1) of \(clippings.count)"
        if let app = item.sourceAppName {
            metaLabel.stringValue = "From \(app)"
        } else {
            metaLabel.stringValue = "\(item.characterCount) chars"
        }
        
        // High-contrast, bright white text styling
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3.0
        
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedContent = NSAttributedString(string: item.content, attributes: attrs)
        contentTextView.textStorage?.setAttributedString(attributedContent)
        contentTextView.scrollToBeginningOfDocument(nil)
    }
    
    private func present() {
        guard let window = window else { return }
        
        // Remember frontmost application before showing HUD
        let frontApp = NSWorkspace.shared.frontmostApplication
        if frontApp?.bundleIdentifier != Bundle.main.bundleIdentifier {
            self.previousApp = frontApp
        }
        
        if !window.isVisible {
            window.center()
            window.alphaValue = 0
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                window.animator().alphaValue = 1.0
            }
        } else {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
        resetDismissTimer()
    }
    
    private func resetDismissTimer() {
        dismissTimer?.invalidate()
        // Sticky bezel: stays visible for 6 seconds of idle time, or until Enter/Click/Esc
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }
    
    public func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        guard let window = window, window.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            window.animator().alphaValue = 0.0
        }, completionHandler: {
            window.orderOut(nil)
            window.alphaValue = 1.0
        })
    }
}

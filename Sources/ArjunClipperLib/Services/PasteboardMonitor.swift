import Foundation
import AppKit

public final class PasteboardMonitor {
    public static let shared = PasteboardMonitor()
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var dispatchTimer: DispatchSourceTimer?
    private var lastCopiedContent: String?
    
    public var lastRejectedReason: CopyFilter.RejectionReason?
    
    private init() {
        self.lastChangeCount = pasteboard.changeCount
    }
    
    public func start() {
        guard dispatchTimer == nil else { return }
        lastChangeCount = pasteboard.changeCount
        
        // DispatchSourceTimer on main queue fires reliably even during window tracking & menus
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        timer.schedule(deadline: .now() + 0.1, repeating: .milliseconds(250))
        timer.setEventHandler { [weak self] in
            self?.checkPasteboard()
        }
        timer.resume()
        self.dispatchTimer = timer
        
        print("[ArjunClipper] PasteboardMonitor started with changeCount \(lastChangeCount)")
    }
    
    public func stop() {
        dispatchTimer?.cancel()
        dispatchTimer = nil
    }
    
    public func copyToClipboard(clipping: Clipping) {
        self.lastCopiedContent = clipping.content
        pasteboard.clearContents()
        pasteboard.setString(clipping.content, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }
    
    public func checkPasteboard() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        guard let content = extractPasteboardString() else {
            return
        }
        
        // If this string was placed by ArjunClipper during a paste action, skip re-adding it
        if let last = lastCopiedContent, last == content {
            lastCopiedContent = nil
            return
        }
        lastCopiedContent = nil
        
        let frontApp = NSWorkspace.shared.frontmostApplication
        let appName = frontApp?.localizedName
        let bundleId = frontApp?.bundleIdentifier
        let types = pasteboard.types ?? []
        
        let filter = PreferencesManager.shared.filter
        let result = filter.shouldCopy(
            content: content,
            sourceBundleId: bundleId,
            sourceAppName: appName,
            pasteboardTypes: types
        )
        
        switch result {
        case .allowed:
            lastRejectedReason = nil
            ClippingStore.shared.add(
                content: content,
                sourceAppName: appName,
                sourceBundleId: bundleId
            )
            print("[ArjunClipper] Saved clipping (\(content.count) chars) from \(appName ?? "unknown")")
        case .rejected(let reason):
            lastRejectedReason = reason
            print("[ArjunClipper Filter] Rejected clipping from \(appName ?? "unknown"): \(reason.rawValue)")
        }
    }
    
    private func extractPasteboardString() -> String? {
        if let str = pasteboard.string(forType: .string), !str.isEmpty {
            return str
        }
        if let str = pasteboard.string(forType: NSPasteboard.PasteboardType("public.utf8-plain-text")), !str.isEmpty {
            return str
        }
        if let str = pasteboard.string(forType: NSPasteboard.PasteboardType("NSStringPboardType")), !str.isEmpty {
            return str
        }
        if let objects = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String],
           let first = objects.first, !first.isEmpty {
            return first
        }
        return nil
    }
}

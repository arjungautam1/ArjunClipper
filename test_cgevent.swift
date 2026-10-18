import ApplicationServices
import AppKit

let isTrusted = AXIsProcessTrusted()
print("AXIsProcessTrusted: \(isTrusted)")

let src = CGEventSource(stateID: .combinedSessionState)
if let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true) {
    keyDown.flags = .maskCommand
    keyDown.post(tap: .cghidEventTap)
    print("CGEventPost returned")
}

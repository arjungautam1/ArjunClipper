import Carbon
import AppKit

public final class GlobalHotkeyManager {
    public static let shared = GlobalHotkeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var onPress: (() -> Void)?
    private var onRelease: (() -> Void)?
    
    private init() {}
    
    public func registerDefaultHotkey(
        onPress: @escaping () -> Void,
        onRelease: @escaping () -> Void
    ) {
        self.onPress = onPress
        self.onRelease = onRelease
        
        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        // Critical: Must use GetEventDispatcherTarget() for system-wide dispatch when other apps are active!
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                guard let userData = userData, let theEvent = theEvent else { return noErr }
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                let kind = GetEventKind(theEvent)
                DispatchQueue.main.async {
                    if kind == kEventHotKeyPressed {
                        manager.onPress?()
                    } else if kind == kEventHotKeyReleased {
                        manager.onRelease?()
                    }
                }
                return noErr
            },
            2,
            &eventTypes,
            selfPtr,
            &eventHandlerRef
        )
        
        guard status == noErr else {
            print("[ArjunClipper] Failed to install event handler on GetEventDispatcherTarget: \(status)")
            return
        }
        
        // Key code for 'V' on ANSI keyboards is 9
        // Modifiers: cmdKey (0x0100) + shiftKey (0x0200)
        let keyCode: UInt32 = 9 // 'V'
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let hotKeyID = EventHotKeyID(signature: OSType(0x41524A43), id: 1) // 'ARJC'
        
        let regStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if regStatus == noErr {
            print("[ArjunClipper] Global shortcut ⌘+⇧+V successfully registered with Press & Release listeners.")
        } else {
            print("[ArjunClipper] RegisterEventHotKey returned error code: \(regStatus)")
        }
    }
    
    public func registerDefaultHotkey(action: @escaping () -> Void) {
        registerDefaultHotkey(onPress: action, onRelease: {})
    }
    
    public func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
}

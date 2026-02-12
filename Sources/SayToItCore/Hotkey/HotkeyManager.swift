import Carbon
import Cocoa
import Foundation

/// Protocol for hotkey management.
public protocol HotkeyManagerProtocol: AnyObject, Sendable {
    /// Register a callback for the global hotkey.
    func onHotkeyPressed(_ handler: @escaping @Sendable () -> Void)
    /// Start listening for the hotkey.
    func start() throws
    /// Stop listening for the hotkey.
    func stop()
}

/// Manages a global keyboard shortcut using Carbon Event APIs.
public final class HotkeyManager: HotkeyManagerProtocol, @unchecked Sendable {
    public struct Shortcut: Sendable, Equatable {
        public let keyCode: UInt32
        public let modifiers: UInt32

        public init(keyCode: UInt32, modifiers: UInt32) {
            self.keyCode = keyCode
            self.modifiers = modifiers
        }

        /// Default: ⌘⇧S
        public static let `default` = Shortcut(
            keyCode: UInt32(kVK_ANSI_S),
            modifiers: UInt32(cmdKey | shiftKey)
        )
    }

    private var shortcut: Shortcut
    private var handler: (@Sendable () -> Void)?
    private var hotkeyRef: EventHotKeyRef?
    fileprivate static var instance: HotkeyManager?

    public init(shortcut: Shortcut = .default) {
        self.shortcut = shortcut
    }

    public func onHotkeyPressed(_ handler: @escaping @Sendable () -> Void) {
        self.handler = handler
    }

    public func start() throws {
        HotkeyManager.instance = self

        var hotkeyID = EventHotKeyID()
        hotkeyID.signature = OSType(0x5354_4F49) // "STOI" — SayToIt
        hotkeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyCallback,
            1,
            &eventType,
            nil,
            nil
        )

        guard status == noErr else {
            throw HotkeyError.registrationFailed(status)
        }

        let registerStatus = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        guard registerStatus == noErr else {
            throw HotkeyError.registrationFailed(registerStatus)
        }
    }

    public func stop() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        HotkeyManager.instance = nil
    }

    public func updateShortcut(_ shortcut: Shortcut) throws {
        stop()
        self.shortcut = shortcut
        try start()
    }

    fileprivate func triggerHandler() {
        handler?()
    }
}

/// Errors from hotkey operations.
public enum HotkeyError: Error, LocalizedError {
    case registrationFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .registrationFailed(let status):
            return "Failed to register hotkey: \(status)"
        }
    }
}

// Carbon event callback — must be a free function
private func hotkeyCallback(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    HotkeyManager.instance?.triggerHandler()
    return noErr
}

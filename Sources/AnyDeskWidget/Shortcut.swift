import AppKit
import Carbon
import SwiftUI

struct Shortcut: Codable, Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
    let key: String

    static let defaultShortcut = Shortcut(
        keyCode: UInt32(kVK_ANSI_A),
        modifiers: UInt32(cmdKey | optionKey),
        key: "A"
    )

    var displayValue: String {
        var value = ""
        if modifiers & UInt32(controlKey) != 0 { value += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { value += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { value += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { value += "⌘" }
        return value + key
    }
}

@MainActor
final class ShortcutSettingsModel: ObservableObject {
    @Published private(set) var shortcut: Shortcut
    @Published private(set) var error: String?
    var onTrigger: (() -> Void)?

    private let manager = GlobalHotKeyManager()
    private let defaultsKey = "globalShortcut"

    init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let saved = try? JSONDecoder().decode(Shortcut.self, from: data) {
            shortcut = saved
        } else {
            shortcut = .defaultShortcut
        }
    }

    func start() {
        manager.onTrigger = { [weak self] in self?.onTrigger?() }
        register(shortcut)
    }

    func update(_ newShortcut: Shortcut) {
        guard manager.register(newShortcut) else {
            error = Copy.shortcutUnavailable
            return
        }
        shortcut = newShortcut
        error = nil
        if let data = try? JSONEncoder().encode(newShortcut) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    func reset() { update(.defaultShortcut) }

    private func register(_ shortcut: Shortcut) {
        error = manager.register(shortcut) ? nil : Copy.shortcutUnavailable
    }
}

private final class GlobalHotKeyManager: @unchecked Sendable {
    var onTrigger: (() -> Void)?
    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    init() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in manager.onTrigger?() }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }

    func register(_ shortcut: Shortcut) -> Bool {
        var reference: EventHotKeyRef?
        let identifier = EventHotKeyID(signature: 0x41445747, id: 1) // ADWG
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, identifier, GetApplicationEventTarget(), 0, &reference)
        guard status == noErr, let reference else { return false }
        if let hotKey { UnregisterEventHotKey(hotKey) }
        hotKey = reference
        return true
    }
}

struct ShortcutRecorder: NSViewRepresentable {
    let shortcut: Shortcut
    let onChange: (Shortcut) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderButton {
        let button = ShortcutRecorderButton()
        button.onChange = onChange
        button.shortcut = shortcut
        return button
    }

    func updateNSView(_ button: ShortcutRecorderButton, context: Context) {
        button.onChange = onChange
        if !button.isRecording { button.shortcut = shortcut }
    }
}

final class ShortcutRecorderButton: NSButton {
    var onChange: ((Shortcut) -> Void)?
    var isRecording = false
    var shortcut: Shortcut = .defaultShortcut {
        didSet { if !isRecording { title = shortcut.displayValue } }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        bezelStyle = .rounded
        target = self
        action = #selector(beginRecording)
        title = shortcut.displayValue
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var acceptsFirstResponder: Bool { true }

    @objc private func beginRecording() {
        isRecording = true
        title = Copy.recordShortcut
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) { finishRecording(); return }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let carbonModifiers = Self.carbonModifiers(from: flags)
        guard carbonModifiers != 0 else { NSSound.beep(); return }

        let recorded = Shortcut(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers, key: Self.keyName(for: event))
        shortcut = recorded
        onChange?(recorded)
        finishRecording()
    }

    override func resignFirstResponder() -> Bool {
        finishRecording()
        return super.resignFirstResponder()
    }

    private func finishRecording() {
        isRecording = false
        title = shortcut.displayValue
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        return modifiers
    }

    private static func keyName(for event: NSEvent) -> String {
        let specialKeys: [UInt16: String] = [
            UInt16(kVK_Space): "Space", UInt16(kVK_Tab): "⇥", UInt16(kVK_Return): "↩",
            UInt16(kVK_Delete): "⌫", UInt16(kVK_ForwardDelete): "⌦", UInt16(kVK_LeftArrow): "←",
            UInt16(kVK_RightArrow): "→", UInt16(kVK_UpArrow): "↑", UInt16(kVK_DownArrow): "↓"
        ]
        if let special = specialKeys[event.keyCode] { return special }
        let functionKeys: [UInt16: String] = [
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7",
            100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12", 105: "F13",
            107: "F14", 113: "F15", 106: "F16", 64: "F17", 79: "F18", 80: "F19", 90: "F20"
        ]
        if let function = functionKeys[event.keyCode] { return function }
        return event.charactersIgnoringModifiers?.uppercased() ?? "?"
    }
}

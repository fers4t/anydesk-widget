import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private let shortcutModel = ShortcutSettingsModel()
    private let connectionModel = ConnectionModel()
    private let clipboardMonitor = ClipboardMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "rectangle.connected.to.line.below", accessibilityDescription: Copy.menuTitle)
        button.toolTip = Copy.menuTitle
        button.target = self
        button.action = #selector(togglePopover)

        shortcutModel.onTrigger = { [weak self] in self?.togglePopover() }
        shortcutModel.start()

        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 320, height: 235)
        popover.contentViewController = NSHostingController(
            rootView: RootView(shortcutModel: shortcutModel, connectionModel: connectionModel)
        )

        clipboardMonitor.isEnabled = { [weak self] in
            self?.shortcutModel.autoOpenFromClipboard ?? false
        }
        clipboardMonitor.onAddressDetected = { [weak self] address in
            guard let self, self.shortcutModel.autoOpenFromClipboard else { return }
            self.connectionModel.prepare(address: address)
            self.showPopover()
        }
        clipboardMonitor.start()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        NSApplication.shared.activate(ignoringOtherApps: true)
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}

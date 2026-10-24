import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private let shortcutModel = ShortcutSettingsModel()

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
        popover.contentSize = NSSize(width: 320, height: 190)
        popover.contentViewController = NSHostingController(rootView: RootView(shortcutModel: shortcutModel))
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            NSApplication.shared.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}

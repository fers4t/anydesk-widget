import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()
    private let shortcutModel = ShortcutSettingsModel()
    private let connectionModel = ConnectionModel()
    private let updateModel = UpdateModel()
    private let launchAtLoginModel = LaunchAtLoginModel()
    private let clipboardMonitor = ClipboardMonitor()
    private var statusDropTarget: StatusItemDropTarget?
    private var pasteMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "rectangle.connected.to.line.below", accessibilityDescription: Copy.menuTitle)
        button.toolTip = Copy.menuTitle
        let dropTarget = StatusItemDropTarget(frame: button.bounds)
        dropTarget.autoresizingMask = [.width, .height]
        dropTarget.toolTip = Copy.menuTitle
        dropTarget.onClick = { [weak self] in self?.togglePopover() }
        dropTarget.onDragEntered = { [weak self] in self?.showPopover(activate: false) }
        dropTarget.onImageDropped = { [weak self] image in self?.recognize(image: image) }
        button.addSubview(dropTarget)
        statusDropTarget = dropTarget

        shortcutModel.onTrigger = { [weak self] in self?.togglePopover() }
        shortcutModel.start()

        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 320, height: 350)
        popover.contentViewController = NSHostingController(
            rootView: RootView(
                shortcutModel: shortcutModel,
                connectionModel: connectionModel,
                updateModel: updateModel,
                launchAtLoginModel: launchAtLoginModel
            )
        )

        updateModel.onStateChange = { [weak self] state in
            guard let button = self?.statusItem.button else { return }
            switch state {
            case let .downloading(version):
                button.toolTip = String(format: Copy.updateDownloading, version)
                self?.statusDropTarget?.toolTip = button.toolTip
            case let .ready(update):
                button.image = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: Copy.updateReady)
                button.toolTip = String(format: Copy.updateReadyVersion, update.version)
                self?.statusDropTarget?.toolTip = button.toolTip
            default:
                button.toolTip = Copy.menuTitle
                self?.statusDropTarget?.toolTip = button.toolTip
            }
        }
        updateModel.onUpdateReady = { [weak self] in
            self?.popover.contentSize = NSSize(width: 320, height: 305)
            self?.showPopover()
        }
        updateModel.start()
        launchAtLoginModel.start()

        clipboardMonitor.isEnabled = { [weak self] in
            self?.shortcutModel.autoOpenFromClipboard ?? false
        }
        clipboardMonitor.onAddressDetected = { [weak self] address in
            guard let self, self.shortcutModel.autoOpenFromClipboard else { return }
            self.connectionModel.prepare(address: address)
            self.showPopover()
        }
        clipboardMonitor.start()
        NSApplication.shared.servicesProvider = self
        NSUpdateDynamicServices()

        pasteMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
                  event.charactersIgnoringModifiers?.lowercased() == "v",
                  let image = StatusItemDropTarget.image(from: .general) else { return event }
            self?.connectionModel.showNotice(Copy.imageReading)
            self?.recognize(image: image)
            return nil
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let pasteMonitor { NSEvent.removeMonitor(pasteMonitor) }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover(activate: Bool = true) {
        guard let button = statusItem.button else { return }
        if activate { NSApplication.shared.activate(ignoringOtherApps: true) }
        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc func readAnyDeskID(
        _ pasteboard: NSPasteboard,
        userData: String,
        error errorPointer: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        guard let image = StatusItemDropTarget.image(from: pasteboard) else {
            errorPointer.pointee = Copy.imageUnreadable as NSString
            return
        }
        recognize(image: image)
    }

    private func recognize(image: NSImage) {
        Task {
            do {
                guard let address = try await ImageIDRecognizer.numericID(in: image) else {
                    connectionModel.showNotice(Copy.imageIDNotFound)
                    showPopover()
                    return
                }
                connectionModel.prepare(address: address)
                showPopover()
            } catch {
                connectionModel.showNotice(Copy.imageUnreadable)
                showPopover()
            }
        }
    }
}

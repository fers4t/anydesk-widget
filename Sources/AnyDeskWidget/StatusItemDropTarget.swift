import AppKit
import UniformTypeIdentifiers

@MainActor
final class StatusItemDropTarget: NSView {
    var onClick: (() -> Void)?
    var onDragEntered: (() -> Void)?
    var onImageDropped: ((NSImage) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL, .png, .tiff, NSPasteboard.PasteboardType(UTType.image.identifier)])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL, .png, .tiff, NSPasteboard.PasteboardType(UTType.image.identifier)])
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard Self.image(from: sender.draggingPasteboard) != nil else { return [] }
        onDragEntered?()
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        Self.image(from: sender.draggingPasteboard) == nil ? [] : .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let image = Self.image(from: sender.draggingPasteboard) else { return false }
        onImageDropped?(image)
        return true
    }

    static func image(from pasteboard: NSPasteboard) -> NSImage? {
        let directImageTypes: [NSPasteboard.PasteboardType] = [
            .png, .tiff, NSPasteboard.PasteboardType(UTType.image.identifier)
        ]
        if pasteboard.availableType(from: directImageTypes) != nil,
           let image = NSImage(pasteboard: pasteboard) {
            return image
        }

        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        guard let url = (pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL])?.first,
              let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType,
              contentType.conforms(to: .image) else { return nil }
        return NSImage(contentsOf: url)
    }
}

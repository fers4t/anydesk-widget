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
        // Finder places both the copied file URL and a TIFF preview of its file
        // icon on the pasteboard. Resolve an actual image file first so OCR sees
        // the photograph rather than the generic JPEG/PNG icon.
        if let value = pasteboard.string(forType: .fileURL),
           let url = URL(string: value), isImageFile(url),
           let image = NSImage(contentsOf: url) {
            return image
        }

        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL] {
            for url in urls where isImageFile(url) {
                if let image = NSImage(contentsOf: url) { return image }
            }
        }

        let directImageTypes: [NSPasteboard.PasteboardType] = [
            .png, .tiff, NSPasteboard.PasteboardType(UTType.image.identifier)
        ]
        for type in directImageTypes {
            if let data = pasteboard.data(forType: type), let image = NSImage(data: data) {
                return image
            }
        }

        // Some applications expose JPEG, HEIC, WebP, or another concrete image
        // UTI without also publishing PNG/TIFF.
        for type in pasteboard.types ?? [] {
            guard let contentType = UTType(type.rawValue), contentType.conforms(to: .image),
                  contentType != .icns,
                  let data = pasteboard.data(forType: type),
                  let image = NSImage(data: data) else { continue }
            return image
        }
        return nil
    }

    private static func isImageFile(_ url: URL) -> Bool {
        guard url.isFileURL,
              let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
            return false
        }
        return contentType.conforms(to: .image)
    }
}

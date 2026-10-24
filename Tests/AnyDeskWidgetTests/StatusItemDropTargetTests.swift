import AppKit
import XCTest
@testable import AnyDeskWidget

@MainActor
final class StatusItemDropTargetTests: XCTestCase {
    func testCopiedFinderImageUsesFileInsteadOfIconTIFF() throws {
        let imageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("anydesk-widget-paste-test-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: imageURL) }

        let actualImage = try makeImage(width: 40, height: 20, color: .systemBlue)
        try actualImage.write(to: imageURL)
        let iconImage = try makeImage(width: 512, height: 512, color: .systemGray)

        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        pasteboard.declareTypes([.fileURL, .tiff], owner: nil)
        pasteboard.setString(imageURL.absoluteString, forType: .fileURL)
        pasteboard.setData(iconImage, forType: .tiff)

        let result = try XCTUnwrap(StatusItemDropTarget.image(from: pasteboard))
        let representation = try XCTUnwrap(result.representations.first)
        XCTAssertEqual(representation.pixelsWide, 40)
        XCTAssertEqual(representation.pixelsHigh, 20)
    }

    private func makeImage(width: Int, height: Int, color: NSColor) throws -> Data {
        let representation = try XCTUnwrap(
            NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: width,
                pixelsHigh: height,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        )
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)
        color.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        NSGraphicsContext.restoreGraphicsState()
        return try XCTUnwrap(representation.representation(using: .png, properties: [:]))
    }
}

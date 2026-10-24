import XCTest
@testable import AnyDeskWidget

final class AnyDeskAddressDetectorTests: XCTestCase {
    func testRecognizesSupportedIDFormats() {
        XCTAssertEqual(AnyDeskAddressDetector.numericID(from: "123456789"), "123456789")
        XCTAssertEqual(AnyDeskAddressDetector.numericID(from: "123 456 789"), "123456789")
        XCTAssertEqual(AnyDeskAddressDetector.numericID(from: "1234567890"), "1234567890")
        XCTAssertEqual(AnyDeskAddressDetector.numericID(from: "1 234 567 890"), "1234567890")
        XCTAssertEqual(AnyDeskAddressDetector.numericID(from: "  123456789\n"), "123456789")
    }

    func testRejectsUnrelatedClipboardText() {
        XCTAssertNil(AnyDeskAddressDetector.numericID(from: "12345678"))
        XCTAssertNil(AnyDeskAddressDetector.numericID(from: "12345678901"))
        XCTAssertNil(AnyDeskAddressDetector.numericID(from: "+90 555 123 4567"))
        XCTAssertNil(AnyDeskAddressDetector.numericID(from: "AnyDesk: 123456789"))
        XCTAssertNil(AnyDeskAddressDetector.numericID(from: "user@example.com"))
        XCTAssertNil(AnyDeskAddressDetector.numericID(from: "123-456-789"))
    }
}

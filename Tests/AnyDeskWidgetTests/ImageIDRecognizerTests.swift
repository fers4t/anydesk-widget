import XCTest
@testable import AnyDeskWidget

final class ImageIDRecognizerTests: XCTestCase {
    func testExtractsGroupedAnyDeskIDsFromOCRText() {
        XCTAssertEqual(ImageIDRecognizer.firstID(in: "Your Address 1 770 679 479"), "1770679479")
        XCTAssertEqual(ImageIDRecognizer.firstID(in: "ID: 123 456 789"), "123456789")
        XCTAssertEqual(ImageIDRecognizer.firstID(in: "9876543210"), "9876543210")
    }

    func testRejectsUnrelatedNumbers() {
        XCTAssertNil(ImageIDRecognizer.firstID(in: "24.10.2026"))
        XCTAssertNil(ImageIDRecognizer.firstID(in: "Order 123456"))
    }
}

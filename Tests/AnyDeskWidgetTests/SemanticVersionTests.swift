import XCTest
@testable import AnyDeskWidget

final class SemanticVersionTests: XCTestCase {
    func testParsesReleaseTagsAndComparesNumericComponents() {
        XCTAssertEqual(SemanticVersion("v1.3.0"), SemanticVersion("1.3"))
        XCTAssertLessThan(SemanticVersion("1.9.9")!, SemanticVersion("1.10.0")!)
        XCTAssertGreaterThan(SemanticVersion("v2.0.0")!, SemanticVersion("1.99.99")!)
    }

    func testIgnoresPrereleaseSuffixForReleaseComparison() {
        XCTAssertEqual(SemanticVersion("v1.3.0-beta.1"), SemanticVersion("1.3.0"))
    }

    func testRejectsMalformedVersions() {
        XCTAssertNil(SemanticVersion("release-1.3"))
        XCTAssertNil(SemanticVersion("1..3"))
        XCTAssertNil(SemanticVersion(""))
    }
}

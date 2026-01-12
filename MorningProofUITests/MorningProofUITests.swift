import XCTest

final class MorningProofUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeScreenDisplaysStreak() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify main UI elements exist
        XCTAssertTrue(app.staticTexts["MorningProof"].exists)
        XCTAssertTrue(app.staticTexts["Current Streak"].exists)
    }
}

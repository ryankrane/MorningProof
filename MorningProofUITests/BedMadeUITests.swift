import XCTest

final class BedMadeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeScreenDisplaysStreak() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify main UI elements exist
        XCTAssertTrue(app.staticTexts["BedMade"].exists)
        XCTAssertTrue(app.staticTexts["Current Streak"].exists)
    }
}

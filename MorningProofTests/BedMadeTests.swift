import XCTest
@testable import BedMade

final class BedMadeTests: XCTestCase {

    func testStreakDataInitialization() {
        let streakData = StreakData()
        XCTAssertEqual(streakData.currentStreak, 0)
        XCTAssertEqual(streakData.longestStreak, 0)
        XCTAssertEqual(streakData.totalCompletions, 0)
        XCTAssertNil(streakData.lastCompletionDate)
    }

    func testStreakRecordFirstCompletion() {
        var streakData = StreakData()
        streakData.recordCompletion()
        XCTAssertEqual(streakData.currentStreak, 1)
        XCTAssertEqual(streakData.longestStreak, 1)
        XCTAssertEqual(streakData.totalCompletions, 1)
        XCTAssertTrue(streakData.hasCompletedToday)
    }

    func testVerificationResultParsing() throws {
        let json = """
        {"is_made": true, "score": 8, "feedback": "Great job!"}
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(VerificationResult.self, from: json)
        XCTAssertTrue(result.isMade)
        XCTAssertEqual(result.score, 8)
        XCTAssertEqual(result.feedback, "Great job!")
    }
}

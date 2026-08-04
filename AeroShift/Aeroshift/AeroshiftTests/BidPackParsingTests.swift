import XCTest
@testable import Aeroshift

final class BidPackParsingTests: XCTestCase {
    func testParserReturnsValidLegsAndActionableIssues() async {
        let parser = BidPackParsingActor()
        let referenceDate = makeDate(year: 2026, month: 8, day: 4, hour: 12, minute: 0)
        let result = await parser.parse(
            rawText: """
            demo123 aaa bbb 2300 0130 flight
            incomplete row
            demo123 aaa bbb 2300 0130 flight
            demo124 bbb ccc 2500 0300 flight
            """,
            referenceDate: referenceDate
        )

        XCTAssertEqual(result.drafts.count, 1)
        XCTAssertEqual(result.issues.count, 3)
        guard let draft = result.drafts.first else {
            return XCTFail("Expected one valid draft")
        }

        XCTAssertEqual(draft.flightNumber, "DEMO123")
        XCTAssertEqual(draft.origin, "AAA")
        XCTAssertEqual(draft.destination, "BBB")
        XCTAssertEqual(draft.type, .flight)
        XCTAssertEqual(draft.arrival.timeIntervalSince(draft.departure), 2.5 * 60 * 60, accuracy: 0.1)
    }

    func testBlankLinesCreateSeparateDutyGroups() async {
        let parser = BidPackParsingActor()
        let result = await parser.parse(rawText: """
        DEMO123 AAA BBB 0800 0900 flight
        DEMO124 BBB CCC 1000 1100 flight

        DEMO125 DDD EEE 1200 1300 deadhead
        """)

        XCTAssertEqual(result.drafts.count, 3)
        XCTAssertEqual(result.groups.count, 2)
        XCTAssertEqual(result.groups.first?.drafts.count, 2)
        XCTAssertEqual(result.groups.last?.drafts.count, 1)
    }

    func testWhitespaceOnlyLinesDoNotCreatePhantomDutyGroups() async {
        let parser = BidPackParsingActor()
        let result = await parser.parse(rawText: """

        DEMO123 AAA BBB 0800 0900 flight
        \t

        DEMO124 BBB CCC 1000 1100 flight

        """)

        XCTAssertEqual(result.drafts.count, 2)
        XCTAssertEqual(result.groups.count, 2)
        XCTAssertEqual(result.groups.map(\.drafts.count), [1, 1])
    }

    func testInvalidLegTypesAreReportedWithoutDroppingOtherValidLegs() async {
        let parser = BidPackParsingActor()
        let result = await parser.parse(rawText: """
        DEMO123 AAA BBB 0800 0900 flight
        DEMO124 BBB CCC 1000 1100 taxi
        """)

        XCTAssertEqual(result.drafts.count, 1)
        XCTAssertEqual(result.issues.count, 1)
        XCTAssertTrue(result.issues[0].message.contains("Unknown leg type"))
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date()
    }
}

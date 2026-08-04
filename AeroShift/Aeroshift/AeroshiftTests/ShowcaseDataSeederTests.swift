import XCTest
import SwiftData
@testable import Aeroshift

@MainActor
final class ShowcaseDataSeederTests: XCTestCase {
    func testSeederCreatesActiveAndUpcomingSyntheticDuties() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: RosterMonth.self,
            DutyPeriod.self,
            FlightLeg.self,
            ImportBatch.self,
            configurations: configuration
        )
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

        XCTAssertTrue(try ShowcaseDataSeeder.seed(into: container.mainContext, now: now))
        XCTAssertFalse(try ShowcaseDataSeeder.seed(into: container.mainContext, now: now))

        let duties = try container.mainContext.fetch(FetchDescriptor<DutyPeriod>())
        let legs = try container.mainContext.fetch(FetchDescriptor<FlightLeg>())
        let batches = try container.mainContext.fetch(FetchDescriptor<ImportBatch>())

        XCTAssertEqual(duties.count, 2)
        XCTAssertEqual(legs.count, 4)
        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches.first?.title, "Showcase demo roster")
        XCTAssertEqual(batches.first?.dutyCount, 2)
        XCTAssertEqual(batches.first?.legCount, 4)
    }
}

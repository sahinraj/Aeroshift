import XCTest
import SwiftData
@testable import Aeroshift

@MainActor
final class DashboardViewModelTests: XCTestCase {
    func testDashboardSkipsPastDutiesAndCompletedLegs() {
        let container = try! makeContainer()
        let context = container.mainContext
        let now = Date()
        let oldDuty = makeDuty(start: now.addingTimeInterval(-4 * 60 * 60), end: now.addingTimeInterval(-2 * 60 * 60))
        let upcomingDuty = makeDuty(start: now.addingTimeInterval(30 * 60), end: now.addingTimeInterval(4 * 60 * 60))
        context.insert(oldDuty)
        context.insert(upcomingDuty)
        let viewModel = DashboardViewModel()

        XCTAssertEqual(viewModel.activeDuty(in: [oldDuty, upcomingDuty], now: now)?.id, upcomingDuty.id)
        XCTAssertNil(viewModel.nextLeg(in: oldDuty, now: now))
    }

    func testDashboardChoosesTheLegCurrentlyInProgress() {
        let container = try! makeContainer()
        let context = container.mainContext
        let now = Date()
        let duty = DutyPeriod(
            startDate: now.addingTimeInterval(-2 * 60 * 60),
            endDate: now.addingTimeInterval(3 * 60 * 60),
            totalBlockMinutes: 240
        )
        let completedLeg = FlightLeg(
            flightNumber: "DEMO100",
            origin: "AAA",
            destination: "BBB",
            scheduledDeparture: now.addingTimeInterval(-2 * 60 * 60),
            scheduledArrival: now.addingTimeInterval(-60 * 60),
            dutyPeriod: duty
        )
        let activeLeg = FlightLeg(
            flightNumber: "DEMO101",
            origin: "BBB",
            destination: "CCC",
            scheduledDeparture: now.addingTimeInterval(-15 * 60),
            scheduledArrival: now.addingTimeInterval(75 * 60),
            dutyPeriod: duty
        )
        duty.flightLegs = [completedLeg, activeLeg]
        context.insert(duty)
        context.insert(completedLeg)
        context.insert(activeLeg)
        let viewModel = DashboardViewModel()

        XCTAssertEqual(viewModel.nextLeg(in: duty, now: now)?.flightNumber, "DEMO101")
    }

    func testDashboardPresentationStateDistinguishesActiveUpcomingAndEmpty() {
        let container = try! makeContainer()
        let context = container.mainContext
        let now = Date()
        let activeDuty = makeDuty(start: now.addingTimeInterval(-30 * 60), end: now.addingTimeInterval(60 * 60))
        let upcomingDuty = makeDuty(start: now.addingTimeInterval(2 * 60 * 60), end: now.addingTimeInterval(4 * 60 * 60))
        context.insert(activeDuty)
        context.insert(upcomingDuty)
        let viewModel = DashboardViewModel()

        XCTAssertEqual(viewModel.presentationState(for: activeDuty, now: now), .active)
        XCTAssertEqual(viewModel.presentationState(for: upcomingDuty, now: now), .upcoming)
        XCTAssertEqual(viewModel.presentationState(for: nil, now: now), .none)
    }

    private func makeDuty(start: Date, end: Date) -> DutyPeriod {
        DutyPeriod(startDate: start, endDate: end, totalBlockMinutes: 60)
    }

    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: RosterMonth.self,
            DutyPeriod.self,
            FlightLeg.self,
            ImportBatch.self,
            configurations: configuration
        )
    }
}

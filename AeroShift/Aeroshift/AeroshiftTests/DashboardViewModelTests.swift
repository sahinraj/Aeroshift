import XCTest
@testable import Aeroshift

final class DashboardViewModelTests: XCTestCase {
    func testDashboardSkipsPastDutiesAndCompletedLegs() {
        let now = Date()
        let periods = [
            DashboardDutyTiming(
                startDate: now.addingTimeInterval(-4 * 60 * 60),
                endDate: now.addingTimeInterval(-2 * 60 * 60)
            ),
            DashboardDutyTiming(
                startDate: now.addingTimeInterval(30 * 60),
                endDate: now.addingTimeInterval(4 * 60 * 60)
            )
        ]

        XCTAssertEqual(DashboardSelectionLogic.activeDutyIndex(in: periods, now: now), 1)
    }

    func testDashboardChoosesTheLegCurrentlyInProgress() {
        let now = Date()
        let legs = [
            DashboardLegTiming(
                scheduledDeparture: now.addingTimeInterval(-2 * 60 * 60),
                scheduledArrival: now.addingTimeInterval(-60 * 60)
            ),
            DashboardLegTiming(
                scheduledDeparture: now.addingTimeInterval(-15 * 60),
                scheduledArrival: now.addingTimeInterval(75 * 60)
            )
        ]

        XCTAssertEqual(DashboardSelectionLogic.nextLegIndex(in: legs, now: now), 1)
    }

    func testDashboardPresentationStateDistinguishesActiveUpcomingAndEmpty() {
        let now = Date()
        let activeDuty = DashboardDutyTiming(
            startDate: now.addingTimeInterval(-30 * 60),
            endDate: now.addingTimeInterval(60 * 60)
        )
        let upcomingDuty = DashboardDutyTiming(
            startDate: now.addingTimeInterval(2 * 60 * 60),
            endDate: now.addingTimeInterval(4 * 60 * 60)
        )

        XCTAssertEqual(DashboardSelectionLogic.presentationState(for: activeDuty, now: now), .active)
        XCTAssertEqual(DashboardSelectionLogic.presentationState(for: upcomingDuty, now: now), .upcoming)
        XCTAssertEqual(DashboardSelectionLogic.presentationState(for: nil, now: now), .none)
    }
}

import Foundation
import SwiftData

/// Creates a repeatable, synthetic roster that demonstrates the core product flow.
///
/// The relative schedule keeps one duty active and another upcoming at load time while
/// the identifiers, routes, and relationships remain stable for screenshots and demos.
@MainActor
enum ShowcaseDataSeeder {
    static func seed(into modelContext: ModelContext, now: Date = .now) throws -> Bool {
        let existingDemoLegs = try modelContext.fetch(
            FetchDescriptor<FlightLeg>(predicate: #Predicate { $0.flightNumber == "DEMO123" })
        )
        guard existingDemoLegs.isEmpty else { return false }

        let calendar = Calendar.current
        let rosterMonth = RosterMonth(
            month: calendar.component(.month, from: now),
            year: calendar.component(.year, from: now)
        )
        let importBatch = ImportBatch(
            importedAt: now,
            title: "Showcase demo roster",
            legCount: 4,
            dutyCount: 2
        )

        let activeFirstDeparture = now.addingTimeInterval(-30 * 60)
        let activeFirstArrival = now.addingTimeInterval(60 * 60)
        let activeSecondDeparture = now.addingTimeInterval(90 * 60)
        let activeSecondArrival = now.addingTimeInterval(180 * 60)
        let activeDuty = DutyPeriod(
            startDate: activeFirstDeparture,
            endDate: activeSecondArrival,
            totalBlockMinutes: 150,
            rosterMonth: rosterMonth,
            importBatch: importBatch
        )
        let activeFirstLeg = FlightLeg(
            flightNumber: "DEMO123",
            origin: "AAA",
            destination: "BBB",
            scheduledDeparture: activeFirstDeparture,
            scheduledArrival: activeFirstArrival,
            dutyPeriod: activeDuty
        )
        let activeSecondLeg = FlightLeg(
            flightNumber: "DEMO124",
            origin: "BBB",
            destination: "CCC",
            scheduledDeparture: activeSecondDeparture,
            scheduledArrival: activeSecondArrival,
            dutyPeriod: activeDuty
        )

        let upcomingFirstDeparture = now.addingTimeInterval(5 * 60 * 60)
        let upcomingFirstArrival = now.addingTimeInterval(6 * 60 * 60)
        let upcomingSecondDeparture = now.addingTimeInterval(6.5 * 60 * 60)
        let upcomingSecondArrival = now.addingTimeInterval(8 * 60 * 60)
        let upcomingDuty = DutyPeriod(
            startDate: upcomingFirstDeparture,
            endDate: upcomingSecondArrival,
            totalBlockMinutes: 150,
            rosterMonth: rosterMonth,
            importBatch: importBatch
        )
        let upcomingFirstLeg = FlightLeg(
            flightNumber: "DEMO125",
            origin: "CCC",
            destination: "DDD",
            scheduledDeparture: upcomingFirstDeparture,
            scheduledArrival: upcomingFirstArrival,
            dutyPeriod: upcomingDuty
        )
        let upcomingSecondLeg = FlightLeg(
            flightNumber: "DEMO126",
            origin: "DDD",
            destination: "EEE",
            scheduledDeparture: upcomingSecondDeparture,
            scheduledArrival: upcomingSecondArrival,
            dutyPeriod: upcomingDuty
        )

        activeDuty.flightLegs = [activeFirstLeg, activeSecondLeg]
        upcomingDuty.flightLegs = [upcomingFirstLeg, upcomingSecondLeg]
        rosterMonth.dutyPeriods = [activeDuty, upcomingDuty]
        importBatch.dutyPeriods = [activeDuty, upcomingDuty]

        modelContext.insert(rosterMonth)
        modelContext.insert(importBatch)
        modelContext.insert(activeDuty)
        modelContext.insert(upcomingDuty)
        modelContext.insert(activeFirstLeg)
        modelContext.insert(activeSecondLeg)
        modelContext.insert(upcomingFirstLeg)
        modelContext.insert(upcomingSecondLeg)
        try modelContext.save()
        return true
    }
}

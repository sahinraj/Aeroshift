import Foundation
import SwiftData

@Model
final class ImportBatch {
    var importedAt: Date
    var title: String
    var legCount: Int
    var dutyCount: Int

    @Relationship(deleteRule: .cascade, inverse: \DutyPeriod.importBatch)
    var dutyPeriods: [DutyPeriod]

    init(
        importedAt: Date = .now,
        title: String,
        legCount: Int,
        dutyCount: Int,
        dutyPeriods: [DutyPeriod] = []
    ) {
        self.importedAt = importedAt
        self.title = title
        self.legCount = legCount
        self.dutyCount = dutyCount
        self.dutyPeriods = dutyPeriods
    }
}

@Model
final class RosterMonth {
    var month: Int
    var year: Int

    @Relationship(deleteRule: .cascade, inverse: \DutyPeriod.rosterMonth)
    var dutyPeriods: [DutyPeriod]

    init(month: Int, year: Int, dutyPeriods: [DutyPeriod] = []) {
        self.month = month
        self.year = year
        self.dutyPeriods = dutyPeriods
    }
}

@Model
final class DutyPeriod {
    var startDate: Date
    var endDate: Date
    /// Total block time in minutes to simplify arithmetic and sorting.
    var totalBlockMinutes: Int

    @Relationship(deleteRule: .cascade, inverse: \FlightLeg.dutyPeriod)
    var flightLegs: [FlightLeg]

    var rosterMonth: RosterMonth?
    var importBatch: ImportBatch?

    init(
        startDate: Date,
        endDate: Date,
        totalBlockMinutes: Int,
        flightLegs: [FlightLeg] = [],
        rosterMonth: RosterMonth? = nil,
        importBatch: ImportBatch? = nil
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.totalBlockMinutes = totalBlockMinutes
        self.flightLegs = flightLegs
        self.rosterMonth = rosterMonth
        self.importBatch = importBatch
    }
}

@Model
final class FlightLeg {
    enum LegType: String, Codable, CaseIterable, Sendable {
        case flight
        case deadhead
        case layover
    }

    var flightNumber: String
    var origin: String
    var destination: String
    var scheduledDeparture: Date
    var scheduledArrival: Date
    var legTypeRawValue: String

    var dutyPeriod: DutyPeriod?

    var legType: LegType {
        get { LegType(rawValue: legTypeRawValue) ?? .flight }
        set { legTypeRawValue = newValue.rawValue }
    }

    /// Stable local identity used to avoid importing the same leg more than once.
    var dedupeKey: String {
        [
            flightNumber.uppercased(),
            origin.uppercased(),
            destination.uppercased(),
            String(scheduledDeparture.timeIntervalSinceReferenceDate),
            String(scheduledArrival.timeIntervalSinceReferenceDate),
            legTypeRawValue.lowercased()
        ].joined(separator: "|")
    }

    init(
        flightNumber: String,
        origin: String,
        destination: String,
        scheduledDeparture: Date,
        scheduledArrival: Date,
        legType: LegType = .flight,
        dutyPeriod: DutyPeriod? = nil
    ) {
        self.flightNumber = flightNumber
        self.origin = origin
        self.destination = destination
        self.scheduledDeparture = scheduledDeparture
        self.scheduledArrival = scheduledArrival
        self.legTypeRawValue = legType.rawValue
        self.dutyPeriod = dutyPeriod
    }
}

import Foundation
import SwiftData

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

    init(
        startDate: Date,
        endDate: Date,
        totalBlockMinutes: Int,
        flightLegs: [FlightLeg] = [],
        rosterMonth: RosterMonth? = nil
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.totalBlockMinutes = totalBlockMinutes
        self.flightLegs = flightLegs
        self.rosterMonth = rosterMonth
    }
}

@Model
final class FlightLeg {
    enum LegType: String, Codable, CaseIterable {
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

import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    func activeDuty(in periods: [DutyPeriod], now: Date = .now) -> DutyPeriod? {
        periods.first(where: { $0.startDate <= now && $0.endDate >= now }) ?? periods.first
    }

    func nextLeg(in duty: DutyPeriod?, now: Date = .now) -> FlightLeg? {
        guard let duty else { return nil }
        let sorted = duty.flightLegs.sorted(by: { $0.scheduledDeparture < $1.scheduledDeparture })
        return sorted.first(where: { $0.scheduledArrival > now }) ?? sorted.first
    }

    func itinerary(for duty: DutyPeriod?) -> [FlightLeg] {
        duty?.flightLegs.sorted(by: { $0.scheduledDeparture < $1.scheduledDeparture }) ?? []
    }

    func progress(for leg: FlightLeg?, now: Date = .now) -> Double {
        guard let leg else { return 0 }
        let total = leg.scheduledArrival.timeIntervalSince(leg.scheduledDeparture)
        guard total > 0 else { return 0 }
        let elapsed = now.timeIntervalSince(leg.scheduledDeparture)
        return min(max(elapsed / total, 0), 1)
    }

    func blockTimeRemaining(for leg: FlightLeg?, now: Date = .now) -> String {
        guard let leg else { return "--" }
        let remainingMinutes = max(Int(leg.scheduledArrival.timeIntervalSince(now) / 60), 0)
        return "\(remainingMinutes / 60)h \(remainingMinutes % 60)m"
    }
}

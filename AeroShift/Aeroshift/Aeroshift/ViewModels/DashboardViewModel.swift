import Foundation
import Combine
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
final class DashboardViewModel: ObservableObject {
    
    #if canImport(ActivityKit)
    private var dutyActivity: Activity<ActiveDutyActivityAttributes>?
    #endif

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

    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    func startLiveActivity(for leg: FlightLeg?) async {
        guard let leg = leg else { return }
        let route = "\(leg.origin) → \(leg.destination)"
        let totalMinutes = max(Int(leg.scheduledArrival.timeIntervalSince(leg.scheduledDeparture) / 60), 1)
        self.dutyActivity = await LiveActivityManager.shared.startDutyActivity(
            flightNumber: leg.flightNumber,
            route: route,
            totalBlockMinutes: totalMinutes
        )
    }
    @available(iOS 16.1, *)
    func refreshLiveActivity(for leg: FlightLeg?) async {
        guard let leg = leg, let activity = dutyActivity else { return }
        await LiveActivityManager.shared.updateForLeg(
            activity: activity,
            departure: leg.scheduledDeparture,
            arrival: leg.scheduledArrival
        )
    }

    @available(iOS 16.1, *)
    func endLiveActivity() async {
        guard let activity = dutyActivity else { return }
        await LiveActivityManager.shared.end(activity: activity)
        dutyActivity = nil
    }
    #endif
}


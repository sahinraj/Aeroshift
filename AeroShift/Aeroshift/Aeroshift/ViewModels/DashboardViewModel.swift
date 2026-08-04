import Foundation
import Combine
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

enum DutyPresentationState: Equatable {
    case active
    case upcoming
    case none
}

struct DashboardDutyTiming: Equatable {
    let startDate: Date
    let endDate: Date
}

struct DashboardLegTiming: Equatable {
    let scheduledDeparture: Date
    let scheduledArrival: Date
}

enum DashboardSelectionLogic {
    static func presentationState(
        for duty: DashboardDutyTiming?,
        now: Date
    ) -> DutyPresentationState {
        guard let duty else { return .none }
        return duty.startDate <= now && duty.endDate >= now ? .active : .upcoming
    }

    static func activeDutyIndex(in periods: [DashboardDutyTiming], now: Date) -> Int? {
        let sortedPeriods = periods.enumerated().sorted { $0.element.startDate < $1.element.startDate }
        return sortedPeriods.first(where: { $0.element.startDate <= now && $0.element.endDate >= now })?.offset
            ?? sortedPeriods.first(where: { $0.element.startDate > now })?.offset
    }

    static func nextLegIndex(in legs: [DashboardLegTiming], now: Date) -> Int? {
        let sortedLegs = legs.enumerated().sorted { $0.element.scheduledDeparture < $1.element.scheduledDeparture }
        return sortedLegs.first(where: {
            $0.element.scheduledDeparture <= now && $0.element.scheduledArrival > now
        })?.offset
            ?? sortedLegs.first(where: { $0.element.scheduledDeparture > now })?.offset
    }
}

@MainActor
final class DashboardViewModel: ObservableObject {
    
    #if canImport(ActivityKit)
    private var dutyActivity: Activity<ActiveDutyActivityAttributes>?
    #endif

    func activeDuty(in periods: [DutyPeriod], now: Date = .now) -> DutyPeriod? {
        let timings = periods.map { DashboardDutyTiming(startDate: $0.startDate, endDate: $0.endDate) }
        guard let selectedIndex = DashboardSelectionLogic.activeDutyIndex(in: timings, now: now) else {
            return nil
        }

        let sortedPeriods = periods.enumerated().sorted { $0.element.startDate < $1.element.startDate }
        return sortedPeriods.first(where: { $0.offset == selectedIndex })?.element
    }

    func presentationState(for duty: DutyPeriod?, now: Date = .now) -> DutyPresentationState {
        let timing = duty.map { DashboardDutyTiming(startDate: $0.startDate, endDate: $0.endDate) }
        return DashboardSelectionLogic.presentationState(for: timing, now: now)
    }

    func nextLeg(in duty: DutyPeriod?, now: Date = .now) -> FlightLeg? {
        guard let duty else { return nil }
        let timings = duty.flightLegs.map {
            DashboardLegTiming(
                scheduledDeparture: $0.scheduledDeparture,
                scheduledArrival: $0.scheduledArrival
            )
        }
        guard let selectedIndex = DashboardSelectionLogic.nextLegIndex(in: timings, now: now) else {
            return nil
        }

        let sortedLegs = duty.flightLegs.enumerated().sorted { $0.element.scheduledDeparture < $1.element.scheduledDeparture }
        return sortedLegs.first(where: { $0.offset == selectedIndex })?.element
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

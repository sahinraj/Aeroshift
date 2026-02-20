// DashboardLiveActivityBridge.swift
// Small bridge to call DashboardViewModel's Live Activity helpers from the toolbar without view ref wiring.

import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

final class DashboardLiveActivityBridge {
    static let shared = DashboardLiveActivityBridge()

    private init() {}

    // Store a weak reference to avoid retain cycles if ever linked to UI; here we manage it internally.
    private var viewModel = DashboardViewModel()

    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    func start() async {
        await viewModel.startLiveActivity(for: mockLeg())
    }

    @available(iOS 16.1, *)
    func update() async {
        await viewModel.refreshLiveActivity(for: mockLeg())
    }

    @available(iOS 16.1, *)
    func end() async {
        await viewModel.endLiveActivity()
    }
    #endif

    // Mock leg for demo; replace with selected/next leg in production.
    private func mockLeg() -> FlightLeg? {
        let now = Date()
        let dep = now
        let arr = Calendar.current.date(byAdding: .minute, value: 90, to: now) ?? now
        return FlightLeg(
            flightNumber: "AS123",
            origin: "SEA",
            destination: "SFO",
            scheduledDeparture: dep,
            scheduledArrival: arr,
            legType: .flight
        )
    }
}


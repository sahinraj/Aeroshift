// LiveActivityManager.swift
// Helper for starting/updating/ending Active Duty Live Activities

import Foundation
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    func startDutyActivity(flightNumber: String, route: String, totalBlockMinutes: Int) async -> Activity<ActiveDutyActivityAttributes>? {
        let attributes = ActiveDutyActivityAttributes(flightNumber: flightNumber)
        let state = ActiveDutyActivityAttributes.ContentState(route: route, blockMinutesRemaining: totalBlockMinutes, progress: 0)
        do {
            let activity = try Activity<ActiveDutyActivityAttributes>.request(attributes: attributes, content: .init(state: state, staleDate: nil))
            return activity
        } catch {
            // Intentionally swallow to keep UI responsive; caller can inspect nil
            return nil
        }
    }

    @available(iOS 16.1, *)
    func update(activity: Activity<ActiveDutyActivityAttributes>, remainingMinutes: Int, progress: Double) async {
        let clamped = max(0, min(1, progress))
        let content = ActiveDutyActivityAttributes.ContentState(
            route: activity.content.state.route,
            blockMinutesRemaining: max(0, remainingMinutes),
            progress: clamped
        )
        await activity.update(.init(state: content, staleDate: nil))
    }

    @available(iOS 16.1, *)
    func updateForLeg(activity: Activity<ActiveDutyActivityAttributes>, departure: Date, arrival: Date, now: Date = .now) async {
        let total = max(arrival.timeIntervalSince(departure), 1)
        let elapsed = min(max(now.timeIntervalSince(departure), 0), total)
        let progress = elapsed / total
        let remainingMinutes = Int((total - elapsed) / 60)
        await update(activity: activity, remainingMinutes: remainingMinutes, progress: progress)
    }

    @available(iOS 16.1, *)
    func end(activity: Activity<ActiveDutyActivityAttributes>, dismissImmediately: Bool = true) async {
        await activity.end(nil, dismissalPolicy: dismissImmediately ? .immediate : .after(Date().addingTimeInterval(5)))
    }

    @available(iOS 16.1, *)
    func endAll() async {
        for activity in Activity<ActiveDutyActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
    #endif
}


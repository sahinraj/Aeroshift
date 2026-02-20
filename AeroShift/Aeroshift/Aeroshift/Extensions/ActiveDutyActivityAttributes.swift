import Foundation

#if canImport(ActivityKit)
import ActivityKit

struct ActiveDutyActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var route: String
        var blockMinutesRemaining: Int
        var progress: Double
    }

    var flightNumber: String
}
#endif

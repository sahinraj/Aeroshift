import SwiftUI
import SwiftData

@main
struct AeroShiftApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: RosterMonth.self, DutyPeriod.self, FlightLeg.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootSplitView(modelContainer: modelContainer)
        }
        .modelContainer(modelContainer)
    }
}

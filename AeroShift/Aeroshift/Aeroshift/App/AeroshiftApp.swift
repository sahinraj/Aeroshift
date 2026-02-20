//
//  AeroshiftApp.swift
//  Aeroshift
//
//  Created by sahin raj on 2/19/26.
//

import SwiftUI
import SwiftData

@main
struct AeroshiftApp: App {
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

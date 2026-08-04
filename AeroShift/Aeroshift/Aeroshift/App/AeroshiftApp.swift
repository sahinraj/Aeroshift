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

    private static var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["AEROSHIFT_IN_MEMORY_STORE"] == "1"
            || environment["XCTestConfigurationFilePath"] != nil
    }
    
    init() {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: Self.isRunningTests)
            modelContainer = try ModelContainer(
                for: RosterMonth.self,
                DutyPeriod.self,
                FlightLeg.self,
                ImportBatch.self,
                configurations: configuration
            )
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

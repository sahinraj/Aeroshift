import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var importBatches: [ImportBatch]
    @Query private var rosterMonths: [RosterMonth]
    @Query private var dutyPeriods: [DutyPeriod]
    @Query private var flightLegs: [FlightLeg]

    @State private var showingDeleteConfirmation = false
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section("Privacy") {
                Label("Local-only storage", systemImage: "lock.shield")
                    .foregroundStyle(Color.PrimaryBrand)

                Text("AeroShift does not require an account, network connection, analytics, or employer service. Use synthetic or personally owned data while developing.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Local Data") {
                LabeledContent("Import batches", value: "\(importBatches.count)")
                LabeledContent("Roster months", value: "\(rosterMonths.count)")
                LabeledContent("Duty periods", value: "\(dutyPeriods.count)")
                LabeledContent("Flight legs", value: "\(flightLegs.count)")

                Button("Load Synthetic Sample") {
                    loadSyntheticSample()
                }

                Button("Delete All Local Data", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }

            Section("Development Boundary") {
                Text("This is a standalone personal project. Do not add employer confidential information, proprietary code, credentials, internal APIs, or operational data.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Delete all local roster data?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                deleteAllLocalData()
            }
        } message: {
            Text("This removes imported and synthetic roster data from this device.")
        }
        .alert(
            "Local Data",
            isPresented: Binding(
                get: { statusMessage != nil },
                set: { isPresented in
                    if !isPresented { statusMessage = nil }
                }
            )
        ) {
            Button("OK") { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
    }

    private func loadSyntheticSample() {
        guard !flightLegs.contains(where: { $0.flightNumber == "DEMO123" }) else {
            statusMessage = "The synthetic sample is already loaded."
            return
        }

        let now = Date()
        let calendar = Calendar.current
        let rosterMonth = RosterMonth(
            month: calendar.component(.month, from: now),
            year: calendar.component(.year, from: now)
        )
        let firstDeparture = now.addingTimeInterval(-30 * 60)
        let firstArrival = now.addingTimeInterval(60 * 60)
        let secondDeparture = now.addingTimeInterval(90 * 60)
        let secondArrival = now.addingTimeInterval(180 * 60)
        let duty = DutyPeriod(
            startDate: firstDeparture,
            endDate: secondArrival,
            totalBlockMinutes: 150,
            rosterMonth: rosterMonth
        )
        let firstLeg = FlightLeg(
            flightNumber: "DEMO123",
            origin: "AAA",
            destination: "BBB",
            scheduledDeparture: firstDeparture,
            scheduledArrival: firstArrival,
            dutyPeriod: duty
        )
        let secondLeg = FlightLeg(
            flightNumber: "DEMO124",
            origin: "BBB",
            destination: "CCC",
            scheduledDeparture: secondDeparture,
            scheduledArrival: secondArrival,
            dutyPeriod: duty
        )

        duty.flightLegs = [firstLeg, secondLeg]
        rosterMonth.dutyPeriods = [duty]
        modelContext.insert(rosterMonth)
        modelContext.insert(duty)
        modelContext.insert(firstLeg)
        modelContext.insert(secondLeg)

        do {
            try modelContext.save()
            statusMessage = "Synthetic sample data was added locally."
        } catch {
            statusMessage = "Could not save the synthetic sample: \(error.localizedDescription)"
        }
    }

    private func deleteAllLocalData() {
        for flightLeg in flightLegs {
            modelContext.delete(flightLeg)
        }
        for dutyPeriod in dutyPeriods {
            modelContext.delete(dutyPeriod)
        }
        for importBatch in importBatches {
            modelContext.delete(importBatch)
        }
        for rosterMonth in rosterMonths {
            modelContext.delete(rosterMonth)
        }

        do {
            try modelContext.save()
            statusMessage = "All local roster data was deleted from this device."
        } catch {
            statusMessage = "Could not delete local data: \(error.localizedDescription)"
        }
    }
}

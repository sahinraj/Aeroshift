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

                Button("Load Showcase Demo") {
                    loadShowcaseDemo()
                }
                Text("Adds one active duty, one upcoming rotation, and local import history using synthetic data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

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

    private func loadShowcaseDemo() {
        do {
            if try ShowcaseDataSeeder.seed(into: modelContext) {
                statusMessage = "Showcase demo data was added locally."
            } else {
                statusMessage = "The showcase demo is already loaded."
            }
        } catch {
            statusMessage = "Could not save the showcase demo: \(error.localizedDescription)"
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

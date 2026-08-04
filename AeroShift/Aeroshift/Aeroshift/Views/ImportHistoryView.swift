import SwiftUI
import SwiftData

struct ImportHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\ImportBatch.importedAt, order: .reverse)])
    private var importBatches: [ImportBatch]

    @State private var errorMessage: String?
    @State private var batchPendingDeletion: ImportBatch?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Import History")
                .font(.title3.weight(.semibold))

            if importBatches.isEmpty {
                Text("Confirmed imports will appear here.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(importBatches, id: \.id) { batch in
                    HStack(spacing: 12) {
                        Image(systemName: "tray.and.arrow.down")
                            .foregroundStyle(Color.PrimaryBrand)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(batch.title)
                                .font(.headline)
                            Text(batch.importedAt, format: .dateTime.month(.abbreviated).day().year().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(batch.dutyCount) \(batch.dutyCount == 1 ? "duty" : "duties") · \(batch.legCount) \(batch.legCount == 1 ? "leg" : "legs")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            batchPendingDeletion = batch
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.red)
                        .accessibilityLabel("Delete import")
                    }
                    .padding(.vertical, 6)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .confirmationDialog(
            "Delete this import and its associated duties?",
            isPresented: Binding(
                get: { batchPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        batchPendingDeletion = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete Import", role: .destructive) {
                guard let batch = batchPendingDeletion else { return }
                batchPendingDeletion = nil
                delete(batch)
            }
        } message: {
            Text("This removes the imported duties and legs from local storage.")
        }
    }

    private func delete(_ batch: ImportBatch) {
        modelContext.delete(batch)

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Could not delete the import: \(error.localizedDescription)"
        }
    }
}

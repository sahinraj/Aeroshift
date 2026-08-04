import SwiftUI
import SwiftData

struct ParsingEngineView: View {
    @StateObject private var viewModel: ParsingEngineViewModel

    init(modelContainer: ModelContainer) {
        _viewModel = StateObject(wrappedValue: ParsingEngineViewModel(modelContainer: modelContainer))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Bid Pack Parser")
                    .font(.title2.weight(.semibold))

                TextEditor(text: $viewModel.rawText)
                    .font(.body.monospaced())
                    .padding(8)
                    .frame(minHeight: 300)
                    .background(Color.adaptiveCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.OceanBlue.opacity(0.35), lineWidth: 1)
                    }
                    .disabled(viewModel.isParsing || viewModel.parseResult != nil)

                HStack(spacing: 12) {
                    Button(action: viewModel.reviewImport) {
                        Label("Review Import", systemImage: "checklist")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.PrimaryBrand)
                    .disabled(viewModel.isParsing || viewModel.parseResult != nil)

                    if viewModel.isParsing || viewModel.isImporting {
                        ProgressView()
                    }
                }

                if let parseResult = viewModel.parseResult {
                    ImportReviewCard(
                        result: parseResult,
                        isImporting: viewModel.isImporting,
                        onCancel: viewModel.cancelReview,
                        onConfirm: viewModel.confirmImport
                    )
                }

                if let summary = viewModel.lastImportSummary {
                    Text(importSummary(summary))
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = viewModel.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Bid Pack Archive")
        .background(Color.adaptiveCanvasBackground as Color?)
    }

    private func importSummary(_ summary: IngestSummary) -> String {
        if summary.duplicateCount == 0 {
            return "Imported \(summary.insertedCount) leg(s) into local storage."
        }

        return "Imported \(summary.insertedCount) new leg(s); skipped \(summary.duplicateCount) duplicate(s)."
    }
}

private struct ImportReviewCard: View {
    let result: ParseResult
    let isImporting: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Import Review", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)
                Spacer()
                Text("\(result.drafts.count) valid")
                    .foregroundStyle(Color.PrimaryBrand)
            }

            if result.drafts.isEmpty {
                Text("No valid legs were found. Correct the input and review it again.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(result.drafts) { draft in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(draft.flightNumber) · \(draft.origin) → \(draft.destination)")
                            .font(.headline)
                        Text("\(draft.departure, format: .dateTime.month(.abbreviated).day().hour().minute()) → \(draft.arrival, format: .dateTime.hour().minute())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(draft.type.rawValue.capitalized)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primaryBrand.opacity(0.12), in: Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }

            if !result.issues.isEmpty {
                DisclosureGroup("Skipped \(result.issues.count) line(s)") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(result.issues) { issue in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Line \(issue.lineNumber): \(issue.message)")
                                    .font(.callout.weight(.medium))
                                Text(issue.rawLine)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.bordered)
                    .disabled(isImporting)

                Button("Confirm Import", action: onConfirm)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.PrimaryBrand)
                    .disabled(!result.hasImportableLegs || isImporting)
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

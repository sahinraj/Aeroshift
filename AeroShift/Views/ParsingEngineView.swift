import SwiftUI
import SwiftData

struct ParsingEngineView: View {
    @StateObject private var viewModel: ParsingEngineViewModel

    init(modelContainer: ModelContainer) {
        _viewModel = StateObject(wrappedValue: ParsingEngineViewModel(modelContainer: modelContainer))
    }

    var body: some View {
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
                        .stroke(.oceanBlue.opacity(0.35), lineWidth: 1)
                }

            HStack(spacing: 12) {
                Button(action: viewModel.importText) {
                    Label("Import", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primaryBrand)
                .disabled(viewModel.isImporting)

                if viewModel.isImporting {
                    ProgressView()
                }
            }

            if let lastImportCount = viewModel.lastImportCount {
                Text("Imported \(lastImportCount) leg(s) into local storage.")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Bid Pack Archive")
        .background(Color.adaptiveCanvasBackground)
    }
}

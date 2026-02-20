import SwiftUI
import SwiftData

enum SidebarDestination: String, CaseIterable, Hashable, Identifiable {
    case activeDuty = "Active Duty"
    case upcomingRotations = "Upcoming Rotations"
    case bidPackArchive = "Bid Pack Archive"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .activeDuty: "calendar.badge.clock"
        case .upcomingRotations: "calendar"
        case .bidPackArchive: "archivebox"
        case .settings: "gearshape"
        }
    }
}

struct RootSplitView: View {
    let modelContainer: ModelContainer

    @State private var selectedDestination: SidebarDestination? = .activeDuty

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedDestination) {
                ForEach(SidebarDestination.allCases) { destination in
                    NavigationLink(value: destination) {
                        Label(destination.rawValue, systemImage: destination.systemImage)
                            .font(.headline)
                    }
                    .tag(destination)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("AeroShift")
        } detail: {
            switch selectedDestination ?? .activeDuty {
            case .activeDuty:
                DashboardView()
            case .upcomingRotations:
                PlaceholderView(title: "Upcoming Rotations")
            case .bidPackArchive:
                ParsingEngineView(modelContainer: modelContainer)
            case .settings:
                PlaceholderView(title: "Settings")
            }
        }
        .navigationDestination(for: SidebarDestination.self) { destination in
            switch destination {
            case .activeDuty:
                DashboardView()
            case .upcomingRotations:
                PlaceholderView(title: "Upcoming Rotations")
            case .bidPackArchive:
                ParsingEngineView(modelContainer: modelContainer)
            case .settings:
                PlaceholderView(title: "Settings")
            }
        }
        .toolbar {
            if selectedDestination == .activeDuty {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Start Activity") {
                        Task { await DashboardLiveActivityBridge.shared.start() }
                    }
                    Button("Update") {
                        Task { await DashboardLiveActivityBridge.shared.update() }
                    }
                    Button("End") {
                        Task { await DashboardLiveActivityBridge.shared.end() }
                    }
                }
            }
        }
        .tint(Color.PrimaryBrand)
        .background(Color.adaptiveCanvasBackground as Color?)
    }
}

private struct PlaceholderView: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "airplane")
                .font(.largeTitle)
                .foregroundStyle(Color.OceanBlue)
            Text(title)
                .font(.title2.weight(.semibold))
            Text("Offline mode ready.")
                .foregroundStyle(.secondary)
        }
    }
}

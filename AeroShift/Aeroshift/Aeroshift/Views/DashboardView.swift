import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: [SortDescriptor(\DutyPeriod.startDate, order: .forward)])
    private var dutyPeriods: [DutyPeriod]

    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        let duty = viewModel.activeDuty(in: dutyPeriods)
        let nextLeg = viewModel.nextLeg(in: duty)
        let state = viewModel.presentationState(for: duty)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let duty {
                    CurrentFlightReleaseCard(
                        state: state,
                        leg: nextLeg,
                        progress: viewModel.progress(for: nextLeg),
                        remainingText: viewModel.blockTimeRemaining(for: nextLeg),
                        scheduledDeparture: nextLeg?.scheduledDeparture
                    )

                    DailyItineraryStrip(legs: viewModel.itinerary(for: duty))
                } else {
                    ContentUnavailableView(
                        "No Active or Upcoming Duty",
                        systemImage: "tray",
                        description: Text("Import a roster or load synthetic sample data to populate the dashboard.")
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Active Duty")
        .background(Color.adaptiveCanvasBackground as Color?)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Start Activity") {
                    Task { await viewModel.startLiveActivity(for: nextLeg) }
                }
                .disabled(nextLeg == nil)

                Button("Update Activity") {
                    Task { await viewModel.refreshLiveActivity(for: nextLeg) }
                }
                .disabled(nextLeg == nil)

                Button("End Activity") {
                    Task { await viewModel.endLiveActivity() }
                }
            }
        }
    }
}

private struct CurrentFlightReleaseCard: View {
    let state: DutyPresentationState
    let leg: FlightLeg?
    let progress: Double
    let remainingText: String
    let scheduledDeparture: Date?

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dept")
                            .foregroundStyle(.secondary)
                        Text(leg?.origin ?? "---")
                            .font(.title.weight(.bold))
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Arr")
                            .foregroundStyle(.secondary)
                        Text(leg?.destination ?? "---")
                            .font(.title.weight(.bold))
                    }
                }

                if state == .active {
                    Text("Block Time Remaining: \(remainingText)")
                        .font(.headline)

                    ProgressView(value: progress)
                        .tint(Color.PrimaryBrand)
                } else if let scheduledDeparture {
                    HStack {
                        Text("Scheduled Departure")
                            .font(.headline)
                        Spacer()
                        Text(scheduledDeparture, style: .time)
                            .font(.headline)
                            .foregroundStyle(Color.PrimaryBrand)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text(state == .active ? "Current Flight Release" : "Upcoming Flight Release")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.PrimaryBrand)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    LinearGradient(
                        colors: [Color.oceanBlue, Color.primaryBrand],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct DailyItineraryStrip: View {
    let legs: [FlightLeg]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(legs, id: \.id) { leg in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(leg.flightNumber)
                            .font(.headline)
                        Text("\(leg.origin) → \(leg.destination)")
                            .font(.title3.weight(.semibold))
                        Text(leg.scheduledDeparture, style: .time)
                            .foregroundStyle(.secondary)
                        Text(leg.legType.rawValue.capitalized)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primaryBrand.opacity(0.12), in: Capsule())
                    }
                    .frame(width: 180, alignment: .leading)
                    .padding()
                    .background(Color.adaptiveCardBackground, in: RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.oceanBlue.opacity(0.4), lineWidth: 1)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

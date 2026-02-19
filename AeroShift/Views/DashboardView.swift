import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: [SortDescriptor(\DutyPeriod.startDate, order: .forward)])
    private var dutyPeriods: [DutyPeriod]

    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        let duty = viewModel.activeDuty(in: dutyPeriods)
        let nextLeg = viewModel.nextLeg(in: duty)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CurrentFlightReleaseCard(
                    leg: nextLeg,
                    progress: viewModel.progress(for: nextLeg),
                    remainingText: viewModel.blockTimeRemaining(for: nextLeg)
                )

                if duty != nil {
                    DailyItineraryStrip(legs: viewModel.itinerary(for: duty))
                } else {
                    ContentUnavailableView(
                        "No Duty Loaded",
                        systemImage: "tray",
                        description: Text("Import a bid pack to populate active duty data.")
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Active Duty")
        .background(Color.adaptiveCanvasBackground)
    }
}

private struct CurrentFlightReleaseCard: View {
    let leg: FlightLeg?
    let progress: Double
    let remainingText: String

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

                Text("Block Time Remaining: \(remainingText)")
                    .font(.headline)

                ProgressView(value: progress)
                    .tint(.primaryBrand)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text("Current Flight Release")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(
                    LinearGradient(
                        colors: [.oceanBlue, .primaryBrand],
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
                ForEach(legs) { leg in
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
                            .background(.primaryBrand.opacity(0.12), in: Capsule())
                    }
                    .frame(width: 180, alignment: .leading)
                    .padding()
                    .background(Color.adaptiveCardBackground, in: RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.oceanBlue.opacity(0.4), lineWidth: 1)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

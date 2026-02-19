import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: [SortDescriptor(\DutyPeriod.startDate, order: .forward)])
    private var dutyPeriods: [DutyPeriod]

    private var activeDuty: DutyPeriod? {
        let now = Date()
        return dutyPeriods.first { $0.startDate <= now && $0.endDate >= now } ?? dutyPeriods.first
    }

    private var nextLeg: FlightLeg? {
        guard let activeDuty else { return nil }
        let sorted = activeDuty.flightLegs.sorted(by: { $0.scheduledDeparture < $1.scheduledDeparture })
        return sorted.first(where: { $0.scheduledArrival > .now }) ?? sorted.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CurrentFlightReleaseCard(leg: nextLeg)

                if let activeDuty {
                    DailyItineraryStrip(legs: activeDuty.flightLegs.sorted(by: { $0.scheduledDeparture < $1.scheduledDeparture }))
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

    private var progress: Double {
        guard let leg else { return 0 }
        let total = leg.scheduledArrival.timeIntervalSince(leg.scheduledDeparture)
        guard total > 0 else { return 0 }
        let elapsed = Date().timeIntervalSince(leg.scheduledDeparture)
        return min(max(elapsed / total, 0), 1)
    }

    private var remainingText: String {
        guard let leg else { return "--" }
        let remainingMinutes = max(Int(leg.scheduledArrival.timeIntervalSinceNow / 60), 0)
        return "\(remainingMinutes / 60)h \(remainingMinutes % 60)m"
    }

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

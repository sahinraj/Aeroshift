import SwiftUI
import SwiftData

struct UpcomingRotationsView: View {
    @Query(sort: [SortDescriptor(\DutyPeriod.startDate, order: .forward)])
    private var dutyPeriods: [DutyPeriod]

    private var upcomingDuties: [DutyPeriod] {
        dutyPeriods.filter { $0.startDate > .now }
    }

    var body: some View {
        NavigationStack {
            Group {
                if upcomingDuties.isEmpty {
                    ContentUnavailableView(
                        "No Upcoming Rotations",
                        systemImage: "calendar.badge.plus",
                        description: Text("Import a multi-duty roster to see upcoming rotations here.")
                    )
                } else {
                    List(upcomingDuties, id: \.id) { duty in
                        NavigationLink {
                            DutyPeriodDetailView(duty: duty)
                        } label: {
                            DutyPeriodRow(duty: duty)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Upcoming Rotations")
        }
    }
}

private struct DutyPeriodRow: View {
    let duty: DutyPeriod

    private var sortedLegs: [FlightLeg] {
        duty.flightLegs.sorted(by: { $0.scheduledDeparture < $1.scheduledDeparture })
    }

    private var routeSummary: String {
        guard let first = sortedLegs.first, let last = sortedLegs.last else {
            return "No legs"
        }

        if first.id == last.id {
            return "\(first.origin) → \(first.destination)"
        }

        return "\(first.origin) → \(last.destination)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(duty.startDate, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.headline)
                Spacer()
                Text("\(sortedLegs.count) leg\(sortedLegs.count == 1 ? "" : "s")")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.PrimaryBrand)
            }

            Text(routeSummary)
                .font(.title3.weight(.semibold))

            HStack(spacing: 12) {
                Label {
                    Text(duty.startDate, style: .time)
                } icon: {
                    Image(systemName: "clock")
                }
                Text("→")
                    .foregroundStyle(.secondary)
                Text(duty.endDate, style: .time)
                Spacer()
                Text(blockTimeText)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 6)
    }

    private var blockTimeText: String {
        let hours = duty.totalBlockMinutes / 60
        let minutes = duty.totalBlockMinutes % 60
        return "\(hours)h \(minutes)m block"
    }
}

private struct DutyPeriodDetailView: View {
    let duty: DutyPeriod

    private var sortedLegs: [FlightLeg] {
        duty.flightLegs.sorted(by: { $0.scheduledDeparture < $1.scheduledDeparture })
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(duty.startDate, format: .dateTime.weekday(.wide).month(.wide).day())
                            .font(.title3.weight(.semibold))
                        Text("\(sortedLegs.count) leg\(sortedLegs.count == 1 ? "" : "s") · \(blockTimeText)")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(sortedLegs, id: \.id) { leg in
                    FlightLegDetailRow(leg: leg)
                }
            }
            .padding()
        }
        .navigationTitle("Rotation Detail")
        .background(Color.adaptiveCanvasBackground as Color?)
    }

    private var blockTimeText: String {
        let hours = duty.totalBlockMinutes / 60
        let minutes = duty.totalBlockMinutes % 60
        return "\(hours)h \(minutes)m block"
    }
}

private struct FlightLegDetailRow: View {
    let leg: FlightLeg

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: leg.legType == .flight ? "airplane" : "arrow.right.arrow.left")
                .foregroundStyle(Color.PrimaryBrand)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(leg.origin) → \(leg.destination)")
                    .font(.headline)
                Text("\(leg.flightNumber) · \(leg.legType.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(leg.scheduledDeparture, style: .time)
                    .font(.subheadline.weight(.medium))
                Text(leg.scheduledArrival, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.adaptiveCardBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

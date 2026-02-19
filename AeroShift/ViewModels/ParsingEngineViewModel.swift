import Foundation
import SwiftData
import Combine

struct ParsedLegDraft: Sendable {
    let flightNumber: String
    let origin: String
    let destination: String
    let departure: Date
    let arrival: Date
    let type: FlightLeg.LegType
}

actor BidPackParsingActor {
    private let timeZone = TimeZone(secondsFromGMT: 0) ?? .current

    /// Parsing runs off-main so long text input never blocks UI interactions.
    func parse(rawText: String, referenceDate: Date = .now) -> [ParsedLegDraft] {
        let lines = rawText
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HHmm"

        return lines.compactMap { line in
            // Expected lightweight format: F1234 JFK LAX 0545 0915 FLIGHT
            let tokens = line.split(separator: " ").map(String.init)
            guard tokens.count >= 6 else { return nil }

            let type = FlightLeg.LegType(rawValue: tokens[5].lowercased()) ?? .flight
            guard
                let departure = formatter.date(from: tokens[3]),
                let arrival = formatter.date(from: tokens[4])
            else { return nil }

            return ParsedLegDraft(
                flightNumber: tokens[0],
                origin: tokens[1],
                destination: tokens[2],
                departure: merge(date: referenceDate, with: departure),
                arrival: merge(date: referenceDate, with: arrival),
                type: type
            )
        }
    }

    private func merge(date: Date, with timeOnlyDate: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOnlyDate)
        return calendar.date(from: DateComponents(
            year: dateComponents.year,
            month: dateComponents.month,
            day: dateComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute
        )) ?? date
    }
}

@ModelActor
actor ParsingStore {
    func ingest(_ drafts: [ParsedLegDraft], for date: Date = .now) throws {
        guard !drafts.isEmpty else { return }

        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        let descriptor = FetchDescriptor<RosterMonth>(
            predicate: #Predicate { $0.month == month && $0.year == year }
        )
        let existingMonth = try modelContext.fetch(descriptor).first
        let rosterMonth = existingMonth ?? RosterMonth(month: month, year: year)

        let dutyStart = drafts.map(\.departure).min() ?? date
        let dutyEnd = drafts.map(\.arrival).max() ?? date
        let totalBlockMinutes = drafts.reduce(into: 0) { partialResult, draft in
            partialResult += Int(draft.arrival.timeIntervalSince(draft.departure) / 60)
        }

        let duty = DutyPeriod(
            startDate: dutyStart,
            endDate: dutyEnd,
            totalBlockMinutes: totalBlockMinutes,
            rosterMonth: rosterMonth
        )

        drafts.forEach { draft in
            let leg = FlightLeg(
                flightNumber: draft.flightNumber,
                origin: draft.origin,
                destination: draft.destination,
                scheduledDeparture: draft.departure,
                scheduledArrival: draft.arrival,
                legType: draft.type,
                dutyPeriod: duty
            )
            duty.flightLegs.append(leg)
        }

        rosterMonth.dutyPeriods.append(duty)

        modelContext.insert(rosterMonth)
        modelContext.insert(duty)
        try modelContext.save()
    }
}

@MainActor
final class ParsingEngineViewModel: ObservableObject {
    @Published var rawText: String = ""
    @Published private(set) var isImporting = false
    @Published private(set) var lastImportCount: Int?

    private let parser = BidPackParsingActor()
    private let parsingStore: ParsingStore

    init(modelContainer: ModelContainer) {
        self.parsingStore = ParsingStore(modelContainer: modelContainer)
    }

    func importText() {
        guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isImporting = true
        let payload = rawText

        Task {
            let drafts = await parser.parse(rawText: payload)

            do {
                try await parsingStore.ingest(drafts)
                lastImportCount = drafts.count
                rawText = ""
            } catch {
                lastImportCount = nil
            }

            isImporting = false
        }
    }
}

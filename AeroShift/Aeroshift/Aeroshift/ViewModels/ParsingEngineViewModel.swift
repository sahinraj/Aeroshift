import Foundation
import SwiftData
import Combine

struct ParsingIssue: Identifiable, Sendable {
    let lineNumber: Int
    let message: String
    let rawLine: String

    var id: Int { lineNumber }
}

struct ParsedLegDraft: Identifiable, Sendable {
    let flightNumber: String
    let origin: String
    let destination: String
    let departure: Date
    let arrival: Date
    let type: FlightLeg.LegType
    let dutyGroupIndex: Int

    var id: String { dedupeKey }

    var dedupeKey: String {
        [
            flightNumber.uppercased(),
            origin.uppercased(),
            destination.uppercased(),
            String(departure.timeIntervalSinceReferenceDate),
            String(arrival.timeIntervalSinceReferenceDate),
            type.rawValue.lowercased()
        ].joined(separator: "|")
    }
}

struct ParseResult: Sendable {
    let drafts: [ParsedLegDraft]
    let issues: [ParsingIssue]

    var hasImportableLegs: Bool { !drafts.isEmpty }

    var groups: [ParsedLegGroup] {
        Dictionary(grouping: drafts, by: \.dutyGroupIndex)
            .sorted(by: { $0.key < $1.key })
            .enumerated()
            .map { ParsedLegGroup(index: $0.offset, drafts: $0.element.value) }
    }
}

struct ParsedLegGroup: Identifiable, Sendable {
    let index: Int
    let drafts: [ParsedLegDraft]

    var id: Int { index }
}

actor BidPackParsingActor {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    /// Parsing runs off-main so long text input never blocks UI interactions.
    func parse(rawText: String, referenceDate: Date = .now) -> ParseResult {
        var drafts: [ParsedLegDraft] = []
        var issues: [ParsingIssue] = []
        var knownKeys = Set<String>()
        var dutyGroupIndex = 0
        var currentGroupHasRows = false

        for (index, rawLine) in rawText.components(separatedBy: .newlines).enumerated() {
            let lineNumber = index + 1
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty {
                if currentGroupHasRows {
                    dutyGroupIndex += 1
                    currentGroupHasRows = false
                }
                continue
            }

            currentGroupHasRows = true

            // Expected lightweight format: F1234 JFK LAX 0545 0915 FLIGHT
            let tokens = line
                .split(whereSeparator: { $0.isWhitespace })
                .map(String.init)
            guard tokens.count >= 6 else {
                issues.append(ParsingIssue(lineNumber: lineNumber, message: "Expected at least 6 fields.", rawLine: line))
                continue
            }

            guard let type = FlightLeg.LegType(rawValue: tokens[5].lowercased()) else {
                issues.append(ParsingIssue(lineNumber: lineNumber, message: "Unknown leg type. Use flight, deadhead, or layover.", rawLine: line))
                continue
            }

            guard let departureComponents = timeComponents(from: tokens[3]),
                  let arrivalComponents = timeComponents(from: tokens[4]) else {
                issues.append(ParsingIssue(lineNumber: lineNumber, message: "Times must use 24-hour HHmm format.", rawLine: line))
                continue
            }

            let mergedDeparture = merge(date: referenceDate, with: departureComponents)
            var mergedArrival = merge(date: referenceDate, with: arrivalComponents)
            if mergedArrival < mergedDeparture {
                mergedArrival = calendar.date(byAdding: .day, value: 1, to: mergedArrival) ?? mergedArrival
            }

            let draft = ParsedLegDraft(
                flightNumber: tokens[0].uppercased(),
                origin: tokens[1].uppercased(),
                destination: tokens[2].uppercased(),
                departure: mergedDeparture,
                arrival: mergedArrival,
                type: type,
                dutyGroupIndex: dutyGroupIndex
            )

            guard knownKeys.insert(draft.dedupeKey).inserted else {
                issues.append(ParsingIssue(lineNumber: lineNumber, message: "Duplicate leg in this import was skipped.", rawLine: line))
                continue
            }

            drafts.append(draft)
        }

        return ParseResult(drafts: drafts, issues: issues)
    }

    private func timeComponents(from token: String) -> DateComponents? {
        guard token.count == 4, token.allSatisfy(\.isNumber),
              let hour = Int(token.prefix(2)),
              let minute = Int(token.suffix(2)),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return nil
        }

        return DateComponents(hour: hour, minute: minute)
    }

    private func merge(date: Date, with timeComponents: DateComponents) -> Date {
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        var mergedComponents = DateComponents()
        mergedComponents.timeZone = calendar.timeZone
        mergedComponents.year = dateComponents.year
        mergedComponents.month = dateComponents.month
        mergedComponents.day = dateComponents.day
        mergedComponents.hour = timeComponents.hour
        mergedComponents.minute = timeComponents.minute
        return calendar.date(from: mergedComponents) ?? date
    }
}

struct IngestSummary: Sendable {
    let insertedCount: Int
    let duplicateCount: Int
    let dutyCount: Int
}

@ModelActor
actor ParsingStore {
    func ingest(_ drafts: [ParsedLegDraft], for date: Date = .now) throws -> IngestSummary {
        guard !drafts.isEmpty else {
            return IngestSummary(insertedCount: 0, duplicateCount: 0, dutyCount: 0)
        }

        let existingLegs = try modelContext.fetch(FetchDescriptor<FlightLeg>())
        var knownKeys = Set(existingLegs.map(\.dedupeKey))
        var uniqueDrafts: [ParsedLegDraft] = []
        var duplicateCount = 0

        for draft in drafts {
            if knownKeys.insert(draft.dedupeKey).inserted {
                uniqueDrafts.append(draft)
            } else {
                duplicateCount += 1
            }
        }

        guard !uniqueDrafts.isEmpty else {
            return IngestSummary(insertedCount: 0, duplicateCount: duplicateCount, dutyCount: 0)
        }

        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        let descriptor = FetchDescriptor<RosterMonth>(
            predicate: #Predicate { $0.month == month && $0.year == year }
        )
        let existingMonth = try modelContext.fetch(descriptor).first
        let rosterMonth = existingMonth ?? RosterMonth(month: month, year: year)

        if existingMonth == nil {
            modelContext.insert(rosterMonth)
        }

        let groupedDrafts = Dictionary(grouping: uniqueDrafts, by: \.dutyGroupIndex)
        let importBatch = ImportBatch(
            title: "Roster import",
            legCount: uniqueDrafts.count,
            dutyCount: groupedDrafts.count
        )
        modelContext.insert(importBatch)

        for group in groupedDrafts.sorted(by: { $0.key < $1.key }) {
            let groupDrafts = group.value
            let dutyStart = groupDrafts.map(\.departure).min() ?? date
            let dutyEnd = groupDrafts.map(\.arrival).max() ?? date
            let totalBlockMinutes = groupDrafts.reduce(into: 0) { partialResult, draft in
                partialResult += Int(draft.arrival.timeIntervalSince(draft.departure) / 60)
            }

            let duty = DutyPeriod(
                startDate: dutyStart,
                endDate: dutyEnd,
                totalBlockMinutes: totalBlockMinutes,
                rosterMonth: rosterMonth,
                importBatch: importBatch
            )
            modelContext.insert(duty)

            groupDrafts.forEach { draft in
                let leg = FlightLeg(
                    flightNumber: draft.flightNumber,
                    origin: draft.origin,
                    destination: draft.destination,
                    scheduledDeparture: draft.departure,
                    scheduledArrival: draft.arrival,
                    legType: draft.type,
                    dutyPeriod: duty
                )
                modelContext.insert(leg)
                duty.flightLegs.append(leg)
            }

            rosterMonth.dutyPeriods.append(duty)
            importBatch.dutyPeriods.append(duty)
        }
        try modelContext.save()

        return IngestSummary(
            insertedCount: uniqueDrafts.count,
            duplicateCount: duplicateCount,
            dutyCount: groupedDrafts.count
        )
    }
}

@MainActor
final class ParsingEngineViewModel: ObservableObject {
    @Published var rawText: String = ""
    @Published private(set) var parseResult: ParseResult?
    @Published private(set) var isImporting = false
    @Published private(set) var isParsing = false
    @Published private(set) var lastImportSummary: IngestSummary?
    @Published private(set) var errorMessage: String?

    private let parser = BidPackParsingActor()
    private let parsingStore: ParsingStore

    init(modelContainer: ModelContainer) {
        self.parsingStore = ParsingStore(modelContainer: modelContainer)
    }

    func reviewImport() {
        guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isParsing = true
        errorMessage = nil
        lastImportSummary = nil
        let payload = rawText

        Task {
            parseResult = await parser.parse(rawText: payload)
            isParsing = false
        }
    }

    func confirmImport() {
        guard let parseResult, parseResult.hasImportableLegs else { return }

        isImporting = true
        errorMessage = nil

        Task {
            do {
                lastImportSummary = try await parsingStore.ingest(parseResult.drafts)
                self.parseResult = nil
                rawText = ""
            } catch {
                errorMessage = "Could not save the import locally: \(error.localizedDescription)"
            }

            isImporting = false
        }
    }

    func cancelReview() {
        parseResult = nil
        errorMessage = nil
    }
}

import Foundation

#if canImport(AppIntents)
import AppIntents

struct OpenActiveDutyIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Active Duty"

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
#endif

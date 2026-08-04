# AeroShift Architecture

## Overview
AeroShift is an offline-first personal iPadOS/iOS app built with Swift in strict MVVM. The app explores aviation roster ingestion, stores data locally using SwiftData, and renders active-duty state in native SwiftUI views.

## Architectural Style
- **MVVM:**
  - `View`: presentation and user interactions.
  - `ViewModel`: UI state and orchestration.
  - `Model / Actors`: persistence + parsing.
- **Concurrency boundaries:**
  - Parsing runs in a dedicated background actor.
  - SwiftData ingestion runs in a `@ModelActor`.
  - UI updates stay on `@MainActor`.

## Persistence Schema (SwiftData)
- `RosterMonth` (month, year) → one-to-many `DutyPeriod`
- `DutyPeriod` (startDate, endDate, totalBlockMinutes) → one-to-many `FlightLeg`
- `FlightLeg` (flight number, route, departure/arrival, leg type)

## UI Structure
- Root `NavigationSplitView` optimized for iPad.
- Sidebar destinations:
  - Active Duty
  - Upcoming Rotations
  - Bid Pack Archive
  - Settings
- Active Duty detail:
  - Current Flight Release card
  - Block-time progress
  - Horizontal itinerary strip

## Import lifecycle
1. Raw text is parsed off the main actor.
2. Valid legs and line-specific parsing issues are shown in an import review.
3. The user explicitly confirms the review before persistence.
4. `ParsingStore` compares stable local keys and skips duplicate legs.

## Local data controls
Settings provides synthetic sample data for development and a confirmed delete-all flow for local roster records. These actions are device-local and do not export or transmit data.

## Testing
The `AeroshiftTests` target covers overnight parsing, actionable parser issues, duty selection, and in-progress leg selection. Fixtures use synthetic identifiers and routes.

## Networking
No external network calls are required for core functionality. The baseline implementation assumes airplane mode or zero-trust conditions.

## Personal-project boundary
The app is intentionally standalone and unrelated to employment. It has no employer integration, credentials, proprietary APIs, or external data-sharing path. Development and testing should use synthetic or personally owned data.

## Disclaimer
AeroShift is not affiliated with, sponsored by, endorsed by, or developed for FedEx Corporation, its subsidiaries, or any employer. The project must not contain or process employer confidential information, proprietary code, credentials, internal APIs, or operational data.

## Live Activities status
ActivityKit attributes and the app-side manager are scaffolded, but the Live Activity widget source is not compiled into the main app target. A dedicated Widget Extension target still needs to be added before lock-screen or Dynamic Island UI can be considered production-ready.

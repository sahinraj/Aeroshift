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
- `ImportBatch` (local import timestamp and counts) → one-to-many `DutyPeriod`
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
2. Blank lines divide the personal import format into duty groups; no blank lines preserves the single-duty behavior.
3. Valid legs and line-specific parsing issues are shown in an import review.
4. The user explicitly confirms the review before persistence.
5. `ParsingStore` compares stable local keys and creates one `DutyPeriod` per group.

## Local data controls
Settings provides synthetic sample data for development and a confirmed delete-all flow for local roster records. These actions are device-local and do not export or transmit data.

## Import history
Each confirmed import creates an `ImportBatch` with local timestamp and counts. The archive displays batches and allows deleting one batch; its associated duties and legs are removed through SwiftData relationships.

## Dashboard states
The dashboard distinguishes active duty, upcoming duty, and no active/upcoming duty. Progress is shown only for an active flight; upcoming flights show their scheduled departure instead of an inaccurate remaining-time value.

## Testing
The `AeroshiftTests` target covers overnight parsing, actionable parser issues, multi-duty grouping, showcase-data seeding, duty selection, and in-progress leg selection. Fixtures use synthetic identifiers and routes. GitHub Actions runs the shared Xcode scheme on an available iOS Simulator.

## Networking
No external network calls are required for core functionality. The baseline implementation assumes airplane mode or zero-trust conditions.

## Personal-project boundary
The app is intentionally standalone and unrelated to employment. It has no employer integration, credentials, proprietary APIs, or external data-sharing path. Development and testing should use synthetic or personally owned data.

## Disclaimer
AeroShift is not affiliated with, sponsored by, endorsed by, or developed for FedEx Corporation, its subsidiaries, or any employer. The project must not contain or process employer confidential information, proprietary code, credentials, internal APIs, or operational data.

## Live Activities status
The project now contains a dedicated Widget Extension target for the lock-screen and Dynamic Island UI. It compiles the shared ActivityKit attributes and brand theme only; roster persistence and network access remain in the app target. Device-level ActivityKit entitlement and presentation testing are still required before calling the surface production-ready.

## Showcase workflow
The Settings screen includes a `Load Showcase Demo` action that creates a repeatable, synthetic local roster with one active duty, one upcoming rotation, and import history. This provides a safe path for screenshots, demos, and portfolio review without using employer or confidential data.

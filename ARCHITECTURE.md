# AeroShift Architecture

## Overview
AeroShift is an offline-first iPadOS/iOS app built with Swift 6 and strict MVVM. The app ingests aviation bid packs and releases, stores them locally using SwiftData, and renders active-duty state in native SwiftUI views.

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

## Networking
No external network calls are required for core functionality. The baseline implementation assumes airplane mode or zero-trust conditions.

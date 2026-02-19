# AeroShift iOS Application README

## Product Vision
AeroShift is an offline-first iPadOS and iOS application for flight crews to ingest bid packs and releases, organize duty timelines locally, and monitor active duty with a native dashboard.

## Core Features
- **Offline-first architecture:** All ingestion, persistence, and display workflows operate without network access.
- **Native SwiftUI dashboard:** iPad-first split-view layout with active duty context and itinerary cards.
- **Local parsing pipeline:** Raw text imports are parsed in background actors and persisted with SwiftData.
- **Live surfaces foundation:** App Intents and Live Activity attribute scaffolding for lock screen and dynamic updates.

## Technical Stack
- **Swift 6**
- **SwiftUI**
- **SwiftData**
- **Combine**
- **MVVM**

## Principles
- Never block the main thread for parsing or batch inserts.
- Keep business logic in ViewModels / actors, not views.
- Use semantic spacing, native typography, and adaptive system backgrounds.
- Make zero external network calls by default.

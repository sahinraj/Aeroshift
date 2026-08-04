# AeroShift iOS Application README

## Product Vision
AeroShift is an offline-first personal iPadOS and iOS application for exploring roster ingestion, local duty timelines, and an active-duty dashboard.

This repository is a standalone personal project for private development and experimentation. It is not a work project.

## Disclaimer
AeroShift is not affiliated with, sponsored by, endorsed by, or developed for FedEx Corporation, its subsidiaries, or any employer. It does not contain or depend on FedEx confidential or proprietary code, data, systems, credentials, APIs, trademarks, or branding. Do not import employer-provided or confidential material into this repository or app.

## Core Features
- **Offline-first architecture:** All ingestion, persistence, and display workflows operate without network access.
- **Native SwiftUI dashboard:** iPad-first split-view layout with active duty context and itinerary cards.
- **Reviewable local parsing:** Raw text imports are parsed in background actors, reviewed with line-specific issues, and confirmed before SwiftData persistence.
- **Multi-duty grouping:** Blank lines in the personal import format separate duties while keeping single-duty imports backward compatible.
- **Upcoming rotations:** Future duties are organized into a local list with route, timing, block-time, and leg detail.
- **Import history:** Confirmed imports are tracked locally and can be removed as a batch.
- **Explicit dashboard states:** Active, upcoming, and empty states are presented separately.
- **Duplicate-safe ingestion:** Re-importing the same leg skips existing local records instead of creating duplicates.
- **Local data controls:** Synthetic sample data and delete-all-local-data actions support safe development and privacy-conscious testing.
- **Test coverage foundation:** Parser and dashboard-selection tests live in a dedicated `AeroshiftTests` target.
- **Live surfaces:** A dedicated WidgetKit extension target hosts the Live Activity UI and shares only ActivityKit attributes and theme code.
- **Privacy manifest:** The app declares no tracking, collected data types, or required-reason API categories.

## Technical Stack
- **Swift (Swift 5 language mode in the Xcode project)**
- **SwiftUI**
- **SwiftData**
- **Combine**
- **MVVM**

## Principles
- Never block the main thread for parsing or batch inserts.
- Keep business logic in ViewModels / actors, not views.
- Use semantic spacing, native typography, and adaptive system backgrounds.
- Make zero external network calls by default.

## Privacy Boundary
- Imported text and parsed roster data remain on the device.
- No network, analytics, account, or employer-service integration is part of the baseline.
- Use synthetic or personally owned sample data while developing and testing.
- See [SECURITY.md](SECURITY.md) for the repository’s personal-project safety boundary and accidental-exposure procedure.

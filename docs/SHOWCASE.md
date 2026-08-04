# AeroShift Showcase Guide

This guide keeps portfolio demonstrations repeatable, technically honest, and separated from employer data.

The polished public presentation is available at the [AeroShift Product Page](index.html) when GitHub Pages is enabled for this repository.

## Demo narrative

1. **Problem:** Roster information is difficult to review when it is scattered across text and calendar-like views.
2. **Import:** Paste the synthetic roster format into Bid Pack Archive and review valid legs and actionable issues before saving.
3. **Persistence:** Confirm the import and show the local Import Batch history.
4. **Decision support:** Open Active Duty to show the active-flight progress state, then Upcoming Rotations to show the future-duty state.
5. **Glanceable surface:** Start a Live Activity when running on a supported device and show the Widget Extension surface.
6. **Trust:** Open Settings to show local-only storage, the data controls, and the development boundary.

## Screenshot checklist

Capture these screens after running the shared Xcode scheme on a simulator or device:

- Active Duty with `DEMO123` and the route `AAA → BBB`.
- Upcoming Rotations with the `CCC → EEE` synthetic duty.
- Bid Pack Archive showing Import Review and Import History.
- Settings showing local data counts and the privacy boundary.
- Live Activity on the Lock Screen or Dynamic Island when supported.
- Light and dark appearances, with Dynamic Type checked at a larger accessibility size.

## Safe demo rules

- Use `Settings > Load Showcase Demo` or the documented synthetic parser rows only.
- Do not use employer schedules, internal identifiers, credentials, screenshots, or operational data.
- Keep screenshots free of personal notifications, account names, and unrelated device content.
- Do not claim device-level Live Activity validation until it has been tested on supported hardware or Simulator.

## Portfolio evidence

The strongest repository evidence is:

- A clean GitHub Actions run for the shared Xcode scheme.
- Screenshots that show the import-review-to-dashboard flow.
- Tests covering parser issues, duty selection, and showcase-data relationships.
- README links to the architecture, privacy boundary, and showcase walkthrough.

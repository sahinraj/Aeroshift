// AeroShiftLiveActivityWidget.swift
// WidgetKit configuration scaffold for Active Duty Live Activity

#if canImport(ActivityKit) && canImport(WidgetKit)
import WidgetKit
import SwiftUI
import ActivityKit

@available(iOSApplicationExtension 16.1, *)
struct AeroShiftLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ActiveDutyActivityAttributes.self) { context in
            // Lock Screen / Banner presentation
            LiveActivityLockScreenView(context: context)
                .activityBackgroundTint(Color.adaptiveCanvasBackground)
                .activitySystemActionForegroundColor(Color.PrimaryBrand)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.flightNumber)
                        .font(.headline).bold()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.headline)
                        .foregroundStyle(Color.PrimaryBrand)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(Color.PrimaryBrand)
                }
            } compactLeading: {
                Text("AS").bold().foregroundStyle(Color.PrimaryBrand)
            } compactTrailing: {
                Text("\(Int(context.state.progress * 100))")
                    .font(.caption2)
            } minimal: {
                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(Color.PrimaryBrand, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
    }
}

private struct LiveActivityLockScreenView: View {
    let context: ActivityViewContext<ActiveDutyActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AeroShift")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.attributes.flightNumber)
                    .font(.headline).bold()
                ProgressView(value: context.state.progress)
                    .tint(Color.PrimaryBrand)
                Text("Remaining: \(context.state.blockMinutesRemaining / 60)h \(context.state.blockMinutesRemaining % 60)m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ZStack {
                Circle().stroke(Color.OceanBlue.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(Color.PrimaryBrand, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 38, height: 38)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
        }
    }
}

#Preview("Live Activity Preview") {
    let attributes = ActiveDutyActivityAttributes(flightNumber: "AS123")
    let content = ActiveDutyActivityAttributes.ContentState(route: "SEA → SFO", blockMinutesRemaining: 52, progress: 0.42)
    return attributes.previewContext(content, viewKind: .content)
}
#endif

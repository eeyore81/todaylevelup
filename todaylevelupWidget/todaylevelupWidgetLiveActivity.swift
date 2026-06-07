//
//  todaylevelupWidgetLiveActivity.swift
//  todaylevelupWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - ActivityAttributes

struct TimerActivityAttributes: ActivityAttributes {
    var timerType: String
    var questName: String
    struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var totalSeconds: Int
        var isRunning: Bool
    }
}

// MARK: - Live Activity View

struct TimerLiveActivityView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: context.attributes.timerType == "focus" ? "brain.head.profile" : "gamecontroller.fill")
                .font(.title2)
                .foregroundStyle(context.attributes.timerType == "focus" ? .cyan : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.timerType == "focus" ? "집중 중" : "플레이 중")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                if !context.attributes.questName.isEmpty {
                    Text(context.attributes.questName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            Spacer()
            Text(timeStr(context.state.remainingSeconds))
                .font(.title.bold().monospaced())
                .foregroundColor(.white)
                .contentTransition(.numericText())
        }
        .padding()
        .activityBackgroundTint(Color.blue.opacity(0.8))
        .activitySystemActionForegroundColor(.white)
    }

    private func timeStr(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }
}

// MARK: - Widget

struct todaylevelupWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.timerType == "focus" ? "집중" : "플레이")
                        .font(.caption).foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(diTime(context.state.remainingSeconds))
                        .font(.title2.bold().monospaced()).foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {}
            } compactLeading: {
                Image(systemName: "timer").foregroundColor(.white)
            } compactTrailing: {
                Text(diTime(context.state.remainingSeconds))
                    .font(.caption.monospaced()).foregroundColor(.white)
            } minimal: {
                Image(systemName: "timer").foregroundColor(.white)
            }
        }
    }
}

private func diTime(_ s: Int) -> String {
    String(format: "%02d:%02d", s / 60, s % 60)
}
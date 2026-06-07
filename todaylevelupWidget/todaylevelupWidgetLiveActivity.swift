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
        var endTimestamp: Date
    }
}

// MARK: - Lock Screen View

struct TimerLiveActivityView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    private var isFocus: Bool { context.attributes.timerType == "focus" }
    private var accent: Color { isFocus ? .cyan : .orange }

    var body: some View {
        HStack(spacing: 16) {
            // 왼쪽: 프로그레스 링 + 아이콘
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.15), lineWidth: 4)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                Image(systemName: isFocus ? "brain.head.profile" : "gamecontroller.fill")
                    .font(.title3)
                    .foregroundStyle(accent)
            }

            // 중앙: 라벨 + 퀘스트명
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Circle().fill(context.state.isRunning ? accent : .yellow).frame(width: 6, height: 6)
                    Text(context.state.isRunning ? (isFocus ? "집중" : "플레이") : "일시정지")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(context.state.isRunning ? .white : .yellow)
                }
                if !context.attributes.questName.isEmpty {
                    Text(context.attributes.questName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                }
                if !context.state.isRunning {
                    Text("일시정지")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }

            Spacer()

            // 오른쪽: 타이머
            if context.state.isRunning {
                Text(timerInterval: Date()...context.state.endTimestamp, countsDown: true)
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            } else {
                Text(timeStr(context.state.remainingSeconds))
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .activityBackgroundTint(.black.opacity(0.5))
        .activitySystemActionForegroundColor(.white)
    }

    private var progress: CGFloat {
        guard context.state.totalSeconds > 0 else { return 1 }
        return CGFloat(context.state.totalSeconds - context.state.remainingSeconds) / CGFloat(context.state.totalSeconds)
    }
}

// MARK: - Dynamic Island

struct todaylevelupWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            TimerLiveActivityView(context: context)
        } dynamicIsland: { context in
            let f = context.attributes.timerType == "focus"
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: f ? "brain.head.profile" : "gamecontroller.fill")
                        Text(f ? "집중" : "게임")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(f ? .cyan : .orange)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.endTimestamp, countsDown: true)
                        .font(.title2.bold().monospaced())
                }
                DynamicIslandExpandedRegion(.center) {
                    if !context.attributes.questName.isEmpty {
                        Text(context.attributes.questName).font(.caption2).lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.15)).frame(height: 3)
                            Capsule().fill(f ? Color.cyan : Color.orange)
                                .frame(width: geo.size.width * diProgress(context), height: 3)
                        }
                    }.frame(height: 3)
                }
            } compactLeading: {
                Image(systemName: f ? "brain.head.profile" : "gamecontroller.fill")
                    .foregroundStyle(f ? .cyan : .orange)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.endTimestamp, countsDown: true)
                    .font(.caption.monospaced())
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

private func timeStr(_ s: Int) -> String {
    String(format: "%02d:%02d", s / 60, s % 60)
}

private func diProgress(_ ctx: ActivityViewContext<TimerActivityAttributes>) -> CGFloat {
    guard ctx.state.totalSeconds > 0 else { return 1 }
    return CGFloat(ctx.state.totalSeconds - ctx.state.remainingSeconds) / CGFloat(ctx.state.totalSeconds)
}

private func diTime(_ s: Int) -> String {
    String(format: "%02d:%02d", s / 60, s % 60)
}
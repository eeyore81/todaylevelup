//
//  TimerActivityAttributes.swift
//  todaylevelup
//

import ActivityKit
import Foundation

// MARK: - Live Activity Attributes

struct TimerActivityAttributes: ActivityAttributes {
    var timerType: String
    var questName: String
    struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var totalSeconds: Int
        var isRunning: Bool
    }
}

// MARK: - TimerActivityManager

@MainActor
final class TimerActivityManager {
    static let shared = TimerActivityManager()

    private var currentActivity: Activity<TimerActivityAttributes>?

    private init() {}

    /// Live Activity 시작
    func start(timerType: String, totalSeconds: Int, questName: String) -> Bool {
        // 권한 체크
        let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
        print("🎯 Live Activity 권한: \(enabled)")

        guard enabled else {
            print("🎯 Live Activity가 비활성화되어 있습니다. 설정에서 'Live Activities'를 켜주세요.")
            return false
        }

        // 기존 Activity가 있으면 종료
        if let existing = currentActivity {
            Task { await existing.end(dismissalPolicy: .immediate) }
            currentActivity = nil
        }

        let attributes = TimerActivityAttributes(
            timerType: timerType,
            questName: questName
        )
        let initialState = TimerActivityAttributes.ContentState(
            remainingSeconds: totalSeconds,
            totalSeconds: totalSeconds,
            isRunning: true
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil)
            )
            currentActivity = activity
            print("🎯 Live Activity 시작 성공! ID: \(activity.id)")
            print("🎯 → 잠금화면에서 확인하세요. Dynamic Island는 iPhone 14 Pro 이상 실기기에서만 보입니다.")
            return true
        } catch {
            print("🎯 Live Activity 시작 실패: \(error.localizedDescription)")
            return false
        }
    }

    /// 타이머 상태 업데이트
    func update(remainingSeconds: Int, totalSeconds: Int, isRunning: Bool) {
        let state = TimerActivityAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            isRunning: isRunning
        )

        Task {
            await currentActivity?.update(
                .init(state: state, staleDate: nil)
            )
        }
    }

    /// Live Activity 종료
    func end() {
        let finalState = TimerActivityAttributes.ContentState(
            remainingSeconds: 0,
            totalSeconds: currentActivity?.content.state.totalSeconds ?? 0,
            isRunning: false
        )

        Task {
            await currentActivity?.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            currentActivity = nil
        }
    }
}

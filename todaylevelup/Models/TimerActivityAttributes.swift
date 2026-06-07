//
//  TimerActivityAttributes.swift
//  todaylevelup
//

import ActivityKit
import UIKit
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
    private var targetEndDate: Date?
    private var totalSeconds: Int = 0
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    private init() {}

    func start(timerType: String, totalSeconds: Int, questName: String) -> Bool {
        let enabled = ActivityAuthorizationInfo().areActivitiesEnabled
        guard enabled else { print("Live Activity disabled"); return false }

        self.totalSeconds = totalSeconds
        self.targetEndDate = Date().addingTimeInterval(TimeInterval(totalSeconds))

        if let existing = currentActivity {
            Task { await existing.end(dismissalPolicy: .immediate) }
            currentActivity = nil
        }

        let attributes = TimerActivityAttributes(timerType: timerType, questName: questName)
        let state = TimerActivityAttributes.ContentState(
            remainingSeconds: totalSeconds, totalSeconds: totalSeconds, isRunning: true
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: targetEndDate)
            )
            currentActivity = activity
            print("Live Activity started: \(activity.id)")
            return true
        } catch {
            print("Live Activity error: \(error)")
            return false
        }
    }

    func update(remainingSeconds: Int, totalSeconds: Int, isRunning: Bool) {
        let state = TimerActivityAttributes.ContentState(
            remainingSeconds: remainingSeconds, totalSeconds: totalSeconds, isRunning: isRunning
        )
        let stale = isRunning ? targetEndDate : nil
        Task { await currentActivity?.update(.init(state: state, staleDate: stale)) }
    }

    func end() {
        targetEndDate = nil
        endBackgroundTask()
        let final = TimerActivityAttributes.ContentState(
            remainingSeconds: 0, totalSeconds: currentActivity?.content.state.totalSeconds ?? totalSeconds, isRunning: false
        )
        Task {
            await currentActivity?.end(.init(state: final, staleDate: nil), dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    /// 백그라운드 진입 시 호출 - 가능한 한 오래 타이머 유지
    func enterBackground() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        // 30초 연장 후에도 종료 시각은 유지
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self] in
            self?.refreshFromEndDate()
        }
    }

    func enterForeground() {
        endBackgroundTask()
        refreshFromEndDate()
    }

    private func refreshFromEndDate() {
        guard let endDate = targetEndDate, currentActivity != nil else { return }
        let remaining = max(0, Int(endDate.timeIntervalSinceNow))
        if remaining <= 0 {
            end()
        } else {
            update(remainingSeconds: remaining, totalSeconds: totalSeconds, isRunning: true)
        }
    }

    private func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
}

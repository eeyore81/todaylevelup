//
//  TimerActivityAttributes.swift
//  todaylevelup
//

import ActivityKit
import UserNotifications
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    var timerType: String
    var questName: String
    struct ContentState: Codable, Hashable {
        var remainingSeconds: Int
        var totalSeconds: Int
        var isRunning: Bool
        var endTimestamp: Date  // 종료 시점 절대시간
    }
}

@MainActor
final class TimerActivityManager {
    static let shared = TimerActivityManager()
    private var currentActivity: Activity<TimerActivityAttributes>?
    private var targetEndDate: Date?
    private var totalSeconds: Int = 0

    func start(timerType: String, totalSeconds: Int, questName: String) -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return false }
        self.totalSeconds = totalSeconds
        self.targetEndDate = Date().addingTimeInterval(TimeInterval(totalSeconds))

        if let e = currentActivity { Task { await e.end(dismissalPolicy: .immediate) }; currentActivity = nil }

        let attr = TimerActivityAttributes(timerType: timerType, questName: questName)
        let state = TimerActivityAttributes.ContentState(remainingSeconds: totalSeconds, totalSeconds: totalSeconds, isRunning: true, endTimestamp: targetEndDate!)

        do {
            currentActivity = try Activity.request(attributes: attr, content: .init(state: state, staleDate: targetEndDate))
            scheduleEndNotification()
            return true
        } catch { print("LA error: \(error)"); return false }
    }

    func update(remainingSeconds: Int, totalSeconds: Int, isRunning: Bool) {
        let s = TimerActivityAttributes.ContentState(remainingSeconds: remainingSeconds, totalSeconds: totalSeconds, isRunning: isRunning, endTimestamp: targetEndDate ?? Date())
        Task { await currentActivity?.update(.init(state: s, staleDate: isRunning ? targetEndDate : nil)) }
    }

    func end() {
        targetEndDate = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timerEnd"])
        let f = TimerActivityAttributes.ContentState(remainingSeconds: 0, totalSeconds: currentActivity?.content.state.totalSeconds ?? totalSeconds, isRunning: false, endTimestamp: Date())
        Task { await currentActivity?.end(.init(state: f, staleDate: nil), dismissalPolicy: .immediate); currentActivity = nil }
    }

    func scheduleEndNotification() {
        guard let end = targetEndDate else { return }
        let interval = end.timeIntervalSinceNow
        guard interval > 1 else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ 타이머 종료!"
        content.body = "포모도로가 완료되었습니다."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "timerEnd", content: content, trigger: trigger))
    }

    func getRemainingSeconds() -> Int {
        guard let end = targetEndDate else { return 0 }
        return max(0, Int(end.timeIntervalSinceNow))
    }
}

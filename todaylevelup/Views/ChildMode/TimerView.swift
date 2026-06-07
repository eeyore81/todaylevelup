//
//  TimerView.swift
//  todaylevelup
//

import SwiftUI
import ActivityKit

enum TimerMode {
    case focus                     // 집중 포모도로
    case play(minutes: Int)        // 플레이 타이머 (게임시간)
}

struct TimerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let timerType: TimerMode
    var inventoryItem: InventoryItem?  // 플레이 타이머일 때 사용 중인 인벤토리 아이템
    var questId: UUID?                 // 수행 중인 퀘스트 ID

    @State private var remainingSeconds: Int
    @State private var totalSeconds: Int
    @State private var isRunning = true
    @State private var targetEndDate: Date = Date()
    @State private var timer: Timer?
    @State private var showCompletion = false

    // 경고 효과 (플레이 타이머 종료 1분 전)
    @State private var warningFlash = false
    @State private var warningTimer: Timer?
    @State private var liveActivityActive = false

    init(timerType: TimerMode, inventoryItem: InventoryItem? = nil, questId: UUID? = nil) {
        self.timerType = timerType
        self.inventoryItem = inventoryItem
        self.questId = questId
        let minutes: Int
        switch timerType {
        case .focus:
            minutes = PomodoroReward.defaultFocusMinutes
        case .play(let mins):
            minutes = mins
        }
        let total = minutes * 60
        _totalSeconds = State(initialValue: total)
        _remainingSeconds = State(initialValue: total)
    }

    var body: some View {
        ZStack {
            // 배경
            backgroundColor
                .ignoresSafeArea()

            // 경고 테두리 (플레이 타이머 종료 1분 전)
            if warningFlash {
                borderFlash
            }

            VStack(spacing: 32) {
                // 상단 타이틀
                timerHeader

                Spacer()

                // 중앙 타이머
                timerCircle

                Spacer()

                // 하단 컨트롤
                controlButtons
            }
            .padding(40)

            // 완료 모달
            if showCompletion {
                completionOverlay
            }
        }
        .onAppear {
            targetEndDate = Date().addingTimeInterval(TimeInterval(totalSeconds))
            startDisplayTimer()
            startLiveActivity()
        }
        .onDisappear { stopAllTimers() }
        .onChange(of: remainingSeconds) { _, newValue in
            updateLiveActivity()
            if case .play = timerType, newValue <= 60, newValue > 0 {
                startWarningFlash()
            }
            if newValue <= 0 {
                handleCompletion()
            }
        }
    }

    // MARK: - Timer Header

    private var timerHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: isFocusMode ? "brain.head.profile" : "gamecontroller.fill")
                    .font(.title)
                Text(isFocusMode ? "집중 타임" : "플레이 타임")
                    .font(.title.bold())
                // Live Activity 상태 표시
                Image(systemName: liveActivityActive ? "livephoto" : "livephoto.slash")
                    .font(.caption)
                    .foregroundStyle(liveActivityActive ? .green : .red.opacity(0.6))
            }
            if let questName = questName {
                Text(questName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .foregroundStyle(.white)
    }

    // MARK: - Timer Circle

    private var timerCircle: some View {
        ZStack {
            // 배경 원
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 12)
                .frame(width: 240, height: 240)

            // 프로그레스 원
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    isFocusMode ? Color.white : Color.yellow,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 240, height: 240)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // 시간 표시
            VStack(spacing: 8) {
                Text(timeString)
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                Text(isRunning ? "진행 중..." : "일시정지")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 40) {
            // 포기하기
            Button {
                stopAllTimers()
                dismiss()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                    Text(isFocusMode ? "포기하기" : "그만하기")
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.8))
            }

            // 일시정지 / 재개
            Button {
                if isRunning {
                    pauseTimer()
                } else {
                    resumeTimer()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                    Text(isRunning ? "일시정지" : "재개")
                        .font(.caption)
                }
                .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                if isFocusMode {
                    // 집중 완료
                    Text("🎉")
                        .font(.system(size: 80))
                    Text(questId != nil ? "퀘스트 완료!" : "미션 완료!")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    if let qid = questId, let quest = appState.dailyQuests.first(where: { $0.id == qid }) {
                        Text(quest.title)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))
                    }

                    HStack(spacing: 16) {
                        completionBadge(icon: "star.fill", text: "+\(PomodoroReward.pointsPerSession)P", color: .yellow)
                        if questId != nil, let q = appState.dailyQuests.first(where: { $0.id == questId }) {
                            completionBadge(icon: "gift.fill", text: "+\(q.rewardPoints)P", color: .orange)
                        }
                        completionBadge(icon: "bolt.fill", text: "+\(PomodoroReward.expPerSession)EXP", color: .cyan)
                    }
                    Text("내가 노력해서 얻은 포인트로\n상점에서 보상을 구매해보세요!")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    // 플레이 완료
                    Text("⏰")
                        .font(.system(size: 80))
                    Text("플레이 시간 종료!")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("다음 미션을 준비할 시간이에요!")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                }

                Button {
                    stopAllTimers()
                    dismiss()
                } label: {
                    Text("확인")
                        .font(.headline)
                        .foregroundStyle(isFocusMode ? .blue : .orange)
                        .frame(width: 200)
                        .padding()
                        .background(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(40)
        }
    }

    // MARK: - Border Flash (종료 1분 전 경고)

    private var borderFlash: some View {
        Rectangle()
            .stroke(
                Color.yellow,
                style: StrokeStyle(lineWidth: 8)
            )
            .ignoresSafeArea()
            .opacity(warningFlash ? 1.0 : 0.3)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: warningFlash)
    }

    // MARK: - Timer Logic (종료 시각 기반)

    private func startDisplayTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            refreshFromEndDate()
        }
    }

    private func stopDisplayTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func refreshFromEndDate() {
        let now = Date()
        if isRunning {
            let left = max(0, Int(targetEndDate.timeIntervalSince(now)))
            if remainingSeconds != left {
                remainingSeconds = left
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        stopDisplayTimer()
        TimerActivityManager.shared.update(remainingSeconds: remainingSeconds, totalSeconds: totalSeconds, isRunning: false)
    }

    private func resumeTimer() {
        // 재개 시: 남은 시간 기준으로 새 종료 시각 설정
        targetEndDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        isRunning = true
        startDisplayTimer()
        TimerActivityManager.shared.update(remainingSeconds: remainingSeconds, totalSeconds: totalSeconds, isRunning: true)
    }

    private func stopAllTimers() {
        stopDisplayTimer()
        warningTimer?.invalidate()
        warningTimer = nil
        TimerActivityManager.shared.end()
    }

    private func startWarningFlash() {
        guard warningTimer == nil else { return }
        warningFlash = true
        warningTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            warningFlash.toggle()
        }
    }

    private func handleCompletion() {
        stopAllTimers()
        if isFocusMode {
            appState.completePomodoro(minutes: totalSeconds / 60, questId: questId)
        } else {
            appState.consumePlayTime(minutes: totalSeconds / 60)
            if let item = inventoryItem {
                appState.markInventoryItemUsed(item)
            }
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showCompletion = true
        }
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        let typeStr = isFocusMode ? "focus" : "play"
        let quest = questName ?? ""
        liveActivityActive = TimerActivityManager.shared.start(
            timerType: typeStr,
            totalSeconds: totalSeconds,
            questName: quest
        )
    }

    private func updateLiveActivity() {
        guard liveActivityActive else { return }
        TimerActivityManager.shared.update(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
            isRunning: isRunning
        )
    }

    // MARK: - Helpers

    private var isFocusMode: Bool {
        if case .focus = timerType { return true }
        return false
    }

    private var questName: String? {
        guard let qid = questId else { return nil }
        return appState.dailyQuests.first(where: { $0.id == qid })?.title
    }

    private var backgroundColor: Color {
        isFocusMode ? Color(red: 0.05, green: 0.1, blue: 0.35) : Color(red: 0.35, green: 0.15, blue: 0.05)
    }

    private var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(totalSeconds - remainingSeconds) / CGFloat(totalSeconds)
    }

    private var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func completionBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .font(.headline)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white.opacity(0.15))
        .clipShape(Capsule())
    }
}

#Preview {
    TimerView(timerType: .focus)
        .environment(AppState())
}

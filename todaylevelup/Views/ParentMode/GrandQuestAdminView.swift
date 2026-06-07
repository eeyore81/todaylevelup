//
//  GrandQuestAdminView.swift
//  todaylevelup
//

import SwiftUI

struct GrandQuestAdminView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddSheet = false

    var body: some View {
        List {
            // 승인 대기
            if !pendingQuests.isEmpty {
                Section("🔔 승인 대기") {
                    ForEach(pendingQuests) { quest in
                        questAdminRow(quest, isPending: true)
                    }
                }
            }

            // 진행 중
            if !ongoingQuests.isEmpty {
                Section("📋 진행 중") {
                    ForEach(ongoingQuests) { quest in
                        questAdminRow(quest, isPending: false)
                    }
                }
            }

            // 완료
            if !completedQuests.isEmpty {
                Section("✅ 보상 지급 완료") {
                    ForEach(completedQuests) { quest in
                        questAdminRow(quest, isPending: false)
                    }
                }
            }

            if appState.grandQuests.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("등록된 그랜드 퀘스트가 없습니다")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .navigationTitle("그랜드 퀘스트 관리")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            GrandQuestAddView { newQuest in
                appState.addGrandQuest(newQuest)
                showAddSheet = false
            }
        }
    }

    private func questAdminRow(_ quest: GrandQuest, isPending: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(quest.title)
                        .font(.subheadline.bold())
                    Text("보상: \(quest.rewardText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(quest.status)
            }

            HStack {
                Text(conditionText(quest))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(quest.currentProgress) / \(quest.conditionValue)")
                    .font(.caption.bold())
                    .foregroundStyle(quest.status == .achieved ? .green : .blue)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    Capsule()
                        .fill(questProgressColor(quest))
                        .frame(width: geo.size.width * quest.progressRatio, height: 6)
                }
            }
            .frame(height: 6)

            // 승인 버튼
            if quest.status == .achieved {
                Button {
                    appState.approveGrandQuest(quest)
                } label: {
                    Label("보상 지급 승인하기", systemImage: "checkmark.seal.fill")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: QuestStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(status))
                .frame(width: 8, height: 8)
            Text(statusLabel(status))
                .font(.caption)
        }
        .foregroundStyle(statusColor(status))
    }

    private func conditionText(_ quest: GrandQuest) -> String {
        switch quest.conditionType {
        case .pomodoroCount:
            return "포모도로 \(quest.conditionValue)회 달성"
        case .levelReach:
            return "레벨 \(quest.conditionValue) 달성"
        }
    }

    private func questProgressColor(_ quest: GrandQuest) -> Color {
        switch quest.status {
        case .achieved: return .green
        case .rewarded: return .gray
        case .ongoing: return .blue
        }
    }

    private func statusColor(_ status: QuestStatus) -> Color {
        switch status {
        case .ongoing: return .blue
        case .achieved: return .orange
        case .rewarded: return .green
        }
    }

    private func statusLabel(_ status: QuestStatus) -> String {
        switch status {
        case .ongoing: return "진행 중"
        case .achieved: return "승인 대기"
        case .rewarded: return "완료"
        }
    }

    private var pendingQuests: [GrandQuest] {
        appState.grandQuests.filter { $0.status == .achieved }
    }

    private var ongoingQuests: [GrandQuest] {
        appState.grandQuests.filter { $0.status == .ongoing }
    }

    private var completedQuests: [GrandQuest] {
        appState.grandQuests.filter { $0.status == .rewarded }
    }
}

// MARK: - Grand Quest Add View

struct GrandQuestAddView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (GrandQuest) -> Void

    @State private var title: String = ""
    @State private var conditionType: QuestConditionType = .pomodoroCount
    @State private var conditionValue: Int = 10
    @State private var rewardText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("퀘스트 목표") {
                    TextField("목표 제목", text: $title)
                        .placeholder(when: title.isEmpty) {
                            Text("예: 수학 문제집 완권")
                                .foregroundStyle(.secondary)
                        }
                }

                Section("달성 조건") {
                    Picker("조건 종류", selection: $conditionType) {
                        Text("포모도로 횟수").tag(QuestConditionType.pomodoroCount)
                        Text("레벨 달성").tag(QuestConditionType.levelReach)
                    }

                    if conditionType == .pomodoroCount {
                        Stepper("포모도로 \(conditionValue)회", value: $conditionValue, in: 1...500, step: 5)
                    } else {
                        Stepper("레벨 \(conditionValue)", value: $conditionValue, in: 2...100)
                    }
                }

                Section("보상") {
                    TextField("보상 내용", text: $rewardText)
                        .placeholder(when: rewardText.isEmpty) {
                            Text("예: 놀이공원 가기")
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .navigationTitle("그랜드 퀘스트 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        let quest = GrandQuest(
                            title: title,
                            conditionType: conditionType,
                            conditionValue: conditionValue,
                            rewardText: rewardText
                        )
                        onSave(quest)
                        dismiss()
                    }
                    .disabled(title.isEmpty || rewardText.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Placeholder Modifier

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    NavigationStack {
        GrandQuestAdminView()
            .environment(AppState())
    }
}

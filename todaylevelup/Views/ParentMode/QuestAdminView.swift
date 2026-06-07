//
//  QuestAdminView.swift
//  todaylevelup
//

import SwiftUI

struct QuestAdminView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddSheet = false
    @State private var editingQuest: DailyQuest?

    var body: some View {
        List {
            if !activeQuests.isEmpty {
                Section("🟢 활성 퀘스트 (\(activeQuests.count))") {
                    ForEach(activeQuests) { quest in
                        questAdminRow(quest)
                    }
                }
            }

            if !inactiveQuests.isEmpty {
                Section("🔴 숨김 (\(inactiveQuests.count))") {
                    ForEach(inactiveQuests) { quest in
                        questAdminRow(quest)
                    }
                }
            }

            if appState.dailyQuests.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checklist")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("등록된 퀘스트가 없습니다")
                        .foregroundStyle(.secondary)
                    Text("+ 버튼으로 일일 퀘스트를 추가해주세요")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .navigationTitle("일일 퀘스트 관리")
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
            QuestEditView { newQuest in
                appState.addDailyQuest(newQuest)
                showAddSheet = false
            }
        }
        .sheet(item: $editingQuest) { quest in
            QuestEditView(existingQuest: quest) { updatedQuest in
                appState.updateDailyQuest(updatedQuest)
                editingQuest = nil
            }
        }
    }

    private func questAdminRow(_ quest: DailyQuest) -> some View {
        HStack(spacing: 14) {
            Image(systemName: quest.iconName)
                .font(.title3)
                .foregroundStyle(questIconColor(quest))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(quest.title)
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    Label("+\(quest.rewardPoints)P", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Label("최대 \(quest.dailyRepeatLimit)회/일", systemImage: "repeat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 활성화 토글
            Button {
                appState.toggleDailyQuestActive(quest)
            } label: {
                Image(systemName: quest.isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(quest.isActive ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                appState.removeDailyQuest(quest)
            } label: {
                Label("삭제", systemImage: "trash")
            }

            Button {
                editingQuest = quest
            } label: {
                Label("수정", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    private var activeQuests: [DailyQuest] {
        appState.dailyQuests.filter { $0.isActive }
    }

    private var inactiveQuests: [DailyQuest] {
        appState.dailyQuests.filter { !$0.isActive }
    }

    private func questIconColor(_ quest: DailyQuest) -> Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .teal, .indigo]
        let hash = abs(quest.iconName.hashValue) % colors.count
        return colors[hash]
    }
}

// MARK: - Quest Add/Edit Sheet

struct QuestEditView: View {
    @Environment(\.dismiss) private var dismiss

    var existingQuest: DailyQuest?
    var onSave: (DailyQuest) -> Void

    @State private var title: String = ""
    @State private var iconName: String = "checkmark.circle.fill"
    @State private var rewardPoints: Int = 10
    @State private var dailyRepeatLimit: Int = 2
    @State private var isActive: Bool = true

    let iconOptions = [
        "function", "character.book.closed.fill", "book.fill",
        "music.note", "figure.run", "pencil.and.ruler.fill",
        "globe", "flask.fill", "paintpalette.fill",
        "puzzlepiece.fill", "keyboard.fill", "camera.fill",
        "leaf.fill", "sun.max.fill", "star.fill",
        "heart.fill", "house.fill", "bicycle"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("퀘스트 정보") {
                    TextField("퀘스트 이름", text: $title)

                    Stepper("완료 보상: \(rewardPoints) P", value: $rewardPoints, in: 1...100, step: 5)

                    Stepper("하루 반복 가능: \(dailyRepeatLimit)회", value: $dailyRepeatLimit, in: 1...10)
                    Text("아이가 이 퀘스트를 하루에 최대 몇 번까지 수행할 수 있는지 설정합니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("아이콘") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                iconName = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundStyle(iconName == icon ? .blue : .secondary)
                                    .frame(height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(iconName == icon ? Color.blue.opacity(0.1) : .clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section {
                    Toggle("활성화", isOn: $isActive)
                } footer: {
                    Text("비활성화하면 아이의 홈 화면에서 이 퀘스트가 보이지 않습니다")
                }
            }
            .navigationTitle(existingQuest != nil ? "퀘스트 수정" : "퀘스트 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let quest = DailyQuest(
                            id: existingQuest?.id ?? UUID(),
                            title: title,
                            iconName: iconName,
                            rewardPoints: rewardPoints,
                            dailyRepeatLimit: dailyRepeatLimit,
                            isActive: isActive
                        )
                        onSave(quest)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let quest = existingQuest {
                    title = quest.title
                    iconName = quest.iconName
                    rewardPoints = quest.rewardPoints
                    dailyRepeatLimit = quest.dailyRepeatLimit
                    isActive = quest.isActive
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    NavigationStack {
        QuestAdminView()
            .environment(AppState())
    }
}

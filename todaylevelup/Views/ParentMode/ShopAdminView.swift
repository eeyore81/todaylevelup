//
//  ShopAdminView.swift
//  todaylevelup
//

import SwiftUI

struct ShopAdminView: View {
    @Environment(AppState.self) private var appState
    @State private var showAddSheet = false
    @State private var editingItem: ShopItem?

    var body: some View {
        List {
            // 활성 상품
            Section("🟢 진열 중 (\(activeItems.count))") {
                ForEach(activeItems) { item in
                    shopItemAdminRow(item)
                }
            }

            // 비활성 상품
            if !inactiveItems.isEmpty {
                Section("🔴 숨김 (\(inactiveItems.count))") {
                    ForEach(inactiveItems) { item in
                        shopItemAdminRow(item)
                    }
                }
            }
        }
        .navigationTitle("상점 관리")
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
            ShopItemEditView { newItem in
                appState.addShopItem(newItem)
                showAddSheet = false
            }
        }
        .sheet(item: $editingItem) { item in
            ShopItemEditView(existingItem: item) { updatedItem in
                appState.updateShopItem(updatedItem)
                editingItem = nil
            }
        }
    }

    private func shopItemAdminRow(_ item: ShopItem) -> some View {
        HStack(spacing: 14) {
            Image(systemName: item.iconName)
                .font(.title3)
                .foregroundStyle(item.type == .timer ? .blue : .orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.bold())
                Text(item.type == .timer
                    ? "게임시간 \(item.timerMinutes ?? 0)분"
                    : "실물 보상")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(item.costPoints)P")
                .font(.caption.bold())
                .foregroundStyle(.orange)

            // 활성화 토글
            Button {
                appState.toggleShopItemActive(item)
            } label: {
                Image(systemName: item.isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isActive ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                appState.removeShopItem(item)
            } label: {
                Label("삭제", systemImage: "trash")
            }

            Button {
                editingItem = item
            } label: {
                Label("수정", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }

    private var activeItems: [ShopItem] {
        appState.shopItems.filter { $0.isActive }
    }

    private var inactiveItems: [ShopItem] {
        appState.shopItems.filter { !$0.isActive }
    }
}

// MARK: - Shop Item Add/Edit Sheet

struct ShopItemEditView: View {
    @Environment(\.dismiss) private var dismiss

    var existingItem: ShopItem?
    var onSave: (ShopItem) -> Void

    @State private var name: String = ""
    @State private var iconName: String = "star.fill"
    @State private var itemType: ItemType = .timer
    @State private var costPoints: Int = 10
    @State private var timerMinutes: Int = 10
    @State private var isActive: Bool = true

    let iconOptions = [
        "gamecontroller.fill", "play.rectangle.fill", "tv.fill",
        "takeoutbag.and.cup.and.straw.fill", "fork.knife",
        "birthday.cake.fill", "gift.fill", "cup.and.saucer.fill",
        "popcorn.fill", "icecream.fill", "puzzlepiece.fill",
        "book.fill", "paintpalette.fill", "bicycle"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("상품 정보") {
                    TextField("이름", text: $name)

                    Picker("종류", selection: $itemType) {
                        Text("게임시간 (타이머)").tag(ItemType.timer)
                        Text("실물 보상 (소비)").tag(ItemType.consumable)
                    }

                    Stepper("가격: \(costPoints) P", value: $costPoints, in: 1...500, step: 5)
                }

                if itemType == .timer {
                    Section("게임시간 설정") {
                        Stepper("플레이 시간: \(timerMinutes)분", value: $timerMinutes, in: 1...120, step: 5)
                        Text("아이가 구매 후 포모도로 타이머로 이 시간만큼 플레이할 수 있어요")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        Text("아이가 구매 후 '소비' 버튼을 누르면 부모님 확인 후 사용 처리됩니다")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
                    Toggle("상점에 진열하기", isOn: $isActive)
                }
            }
            .navigationTitle(existingItem != nil ? "상품 수정" : "상품 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let item = ShopItem(
                            id: existingItem?.id ?? UUID(),
                            name: name,
                            iconName: iconName,
                            type: itemType,
                            costPoints: costPoints,
                            timerMinutes: itemType == .timer ? timerMinutes : nil,
                            isActive: isActive
                        )
                        onSave(item)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let item = existingItem {
                    name = item.name
                    iconName = item.iconName
                    itemType = item.type
                    costPoints = item.costPoints
                    timerMinutes = item.timerMinutes ?? 10
                    isActive = item.isActive
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    NavigationStack {
        ShopAdminView()
            .environment(AppState())
    }
}

//
//  AppState.swift
//  todaylevelup
//

import SwiftUI
import Observation

@Observable
final class AppState {
    // MARK: - User Data
    var childProfile: ChildProfile
    var shopItems: [ShopItem] = []
    var inventory: [InventoryItem] = []
    var grandQuests: [GrandQuest] = []
    var dailyQuests: [DailyQuest] = []
    var questCompletions: [QuestCompletion] = []
    var sessionLogs: [SessionLog] = []

    // MARK: - Parent Auth
    var parentPin: String = "0000"
    var isParentMode: Bool = false
    var pinAttempts: Int = 0
    var pinLockUntil: Date?

    // MARK: - Theme
    var isRPGTheme: Bool = true   // 기본 RPG 테마 ON

    // MARK: - Navigation
    var selectedTab: ChildTab = .home

    // MARK: - Preset Shop Items (초기 템플릿)
    static let presetShopItems: [ShopItem] = [
        ShopItem(name: "게임 10분", iconName: "gamecontroller.fill", type: .timer, costPoints: 10, timerMinutes: 10),
        ShopItem(name: "게임 25분", iconName: "gamecontroller.fill", type: .timer, costPoints: 25, timerMinutes: 25),
        ShopItem(name: "유튜브 10분", iconName: "play.rectangle.fill", type: .timer, costPoints: 10, timerMinutes: 10),
        ShopItem(name: "유튜브 25분", iconName: "play.rectangle.fill", type: .timer, costPoints: 25, timerMinutes: 25),
        ShopItem(name: "과자", iconName: "takeoutbag.and.cup.and.straw.fill", type: .consumable, costPoints: 20),
        ShopItem(name: "라면", iconName: "fork.knife", type: .consumable, costPoints: 30),
        ShopItem(name: "아이스크림", iconName: "birthday.cake.fill", type: .consumable, costPoints: 15)
    ]

    // MARK: - Preset Daily Quests (초기 템플릿)
    static let presetDailyQuests: [DailyQuest] = [
        DailyQuest(title: "수학 문제 풀기", iconName: "function", rewardPoints: 15, dailyRepeatLimit: 3),
        DailyQuest(title: "영어 단어 암기", iconName: "character.book.closed.fill", rewardPoints: 10, dailyRepeatLimit: 2),
        DailyQuest(title: "책 읽기", iconName: "book.fill", rewardPoints: 20, dailyRepeatLimit: 2),
        DailyQuest(title: "악기 연습", iconName: "music.note", rewardPoints: 15, dailyRepeatLimit: 2),
        DailyQuest(title: "운동하기", iconName: "figure.run", rewardPoints: 10, dailyRepeatLimit: 1)
    ]

    // MARK: - Init
    init() {
        self.childProfile = ChildProfile(name: "용사")
        loadData()
        if shopItems.isEmpty {
            shopItems = Self.presetShopItems
        }
        if dailyQuests.isEmpty {
            dailyQuests = Self.presetDailyQuests
        }
    }

    // MARK: - Persistence

    private func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    func saveData() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(childProfile)
            try data.write(to: documentsURL().appendingPathComponent("profile.json"))

            let shopData = try encoder.encode(shopItems)
            try shopData.write(to: documentsURL().appendingPathComponent("shop.json"))

            let invData = try encoder.encode(inventory)
            try invData.write(to: documentsURL().appendingPathComponent("inventory.json"))

            let questData = try encoder.encode(grandQuests)
            try questData.write(to: documentsURL().appendingPathComponent("quests.json"))

            let logData = try encoder.encode(sessionLogs)
            try logData.write(to: documentsURL().appendingPathComponent("logs.json"))

            let dailyQuestData = try encoder.encode(dailyQuests)
            try dailyQuestData.write(to: documentsURL().appendingPathComponent("daily_quests.json"))

            let completionData = try encoder.encode(questCompletions)
            try completionData.write(to: documentsURL().appendingPathComponent("quest_completions.json"))

            UserDefaults.standard.set(parentPin, forKey: "parent_pin")
            UserDefaults.standard.set(isRPGTheme, forKey: "rpg_theme")
        } catch {
            print("Save error: \(error)")
        }
    }

    func loadData() {
        let decoder = JSONDecoder()
        let fm = FileManager.default
        let dir = documentsURL()

        if let data = try? Data(contentsOf: dir.appendingPathComponent("profile.json")),
           let profile = try? decoder.decode(ChildProfile.self, from: data) {
            childProfile = profile
        }
        if let data = try? Data(contentsOf: dir.appendingPathComponent("shop.json")),
           let items = try? decoder.decode([ShopItem].self, from: data) {
            shopItems = items
        }
        if let data = try? Data(contentsOf: dir.appendingPathComponent("inventory.json")),
           let items = try? decoder.decode([InventoryItem].self, from: data) {
            inventory = items
        }
        if let data = try? Data(contentsOf: dir.appendingPathComponent("quests.json")),
           let quests = try? decoder.decode([GrandQuest].self, from: data) {
            grandQuests = quests
        }
        if let data = try? Data(contentsOf: dir.appendingPathComponent("logs.json")),
           let logs = try? decoder.decode([SessionLog].self, from: data) {
            sessionLogs = logs
        }
        if let data = try? Data(contentsOf: dir.appendingPathComponent("daily_quests.json")),
           let quests = try? decoder.decode([DailyQuest].self, from: data) {
            dailyQuests = quests
        }
        if let data = try? Data(contentsOf: dir.appendingPathComponent("quest_completions.json")),
           let completions = try? decoder.decode([QuestCompletion].self, from: data) {
            questCompletions = completions
        }
        if let pin = UserDefaults.standard.string(forKey: "parent_pin") {
            parentPin = pin
        }
        isRPGTheme = UserDefaults.standard.bool(forKey: "rpg_theme")
    }

    // MARK: - Pomodoro Completion (퀘스트 수행 완료)

    func completePomodoro(minutes: Int, questId: UUID? = nil) {
        childProfile.totalPomodorosCompleted += 1

        // 기본 EXP
        let earnedExp = PomodoroReward.expPerSession
        var totalPoints = PomodoroReward.pointsPerSession

        // 퀘스트 보너스 포인트
        if let qid = questId, let quest = dailyQuests.first(where: { $0.id == qid }) {
            totalPoints += quest.rewardPoints
            questCompletions.append(QuestCompletion(questId: qid, date: Date(), pomodoroMinutes: minutes))
        }

        childProfile.currentExp += earnedExp
        childProfile.pointBalance += totalPoints

        // 레벨업 체크
        while childProfile.currentExp >= childProfile.expToNextLevel {
            childProfile.currentExp -= childProfile.expToNextLevel
            childProfile.currentLevel += 1
        }

        // 세션 로그
        sessionLogs.append(SessionLog(type: .work, minutes: minutes, date: Date()))

        // 그랜드 퀘스트 진행도 갱신
        updateQuestProgress()

        saveData()
    }

    // MARK: - Daily Allowance (하루 일당 포인트)

    var canClaimDailyPoints: Bool {
        !childProfile.claimedToday
    }

    func claimDailyPoints() {
        guard canClaimDailyPoints else { return }
        childProfile.pointBalance += childProfile.dailyPointAllowance
        childProfile.lastDailyClaimDate = Date()
        saveData()
    }

    func setDailyAllowance(_ amount: Int) {
        childProfile.dailyPointAllowance = max(0, amount)
        saveData()
    }

    // MARK: - Play Timer Consumption (게임시간 소비)

    func consumePlayTime(minutes: Int) {
        sessionLogs.append(SessionLog(type: .play, minutes: minutes, date: Date()))
        saveData()
    }

    // MARK: - Shop Purchase

    func purchaseItem(_ item: ShopItem) -> Bool {
        guard childProfile.pointBalance >= item.costPoints else { return false }
        guard item.isActive else { return false }

        childProfile.pointBalance -= item.costPoints
        let inventoryItem = InventoryItem(shopItem: item, purchasedDate: Date())
        inventory.append(inventoryItem)
        saveData()
        return true
    }

    // MARK: - Inventory Use

    /// TIMER 아이템 사용: 플레이 타이머 시작 (실제 소비는 타이머 완료 후)
    func markInventoryItemUsed(_ item: InventoryItem) {
        if let index = inventory.firstIndex(where: { $0.id == item.id && !$0.isUsed }) {
            inventory[index].isUsed = true
            saveData()
        }
    }

    /// CONSUMABLE 아이템 소비 요청 (부모 승인 후)
    func requestConsumableUse(_ item: InventoryItem) {
        // 부모 승인 팝업 표시는 View에서 처리
    }

    /// CONSUMABLE 아이템 소비 완료 (부모 승인됨)
    func confirmConsumableUsed(_ item: InventoryItem) {
        if let index = inventory.firstIndex(where: { $0.id == item.id && !$0.isUsed }) {
            inventory[index].isUsed = true
            saveData()
        }
    }

    // MARK: - Parent: Shop Management

    func addShopItem(_ item: ShopItem) {
        shopItems.append(item)
        saveData()
    }

    func updateShopItem(_ item: ShopItem) {
        if let index = shopItems.firstIndex(where: { $0.id == item.id }) {
            shopItems[index] = item
            saveData()
        }
    }

    func toggleShopItemActive(_ item: ShopItem) {
        if let index = shopItems.firstIndex(where: { $0.id == item.id }) {
            shopItems[index].isActive.toggle()
            saveData()
        }
    }

    func removeShopItem(_ item: ShopItem) {
        shopItems.removeAll { $0.id == item.id }
        saveData()
    }

    // MARK: - Parent: Grand Quest Management

    func addGrandQuest(_ quest: GrandQuest) {
        grandQuests.append(quest)
        saveData()
    }

    func approveGrandQuest(_ quest: GrandQuest) {
        if let index = grandQuests.firstIndex(where: { $0.id == quest.id && $0.status == .achieved }) {
            grandQuests[index].status = .rewarded
            saveData()
        }
    }

    private func updateQuestProgress() {
        for i in grandQuests.indices where grandQuests[i].status == .ongoing {
            switch grandQuests[i].conditionType {
            case .pomodoroCount:
                grandQuests[i].currentProgress = childProfile.totalPomodorosCompleted
            case .levelReach:
                grandQuests[i].currentProgress = childProfile.currentLevel
            }
            if grandQuests[i].currentProgress >= grandQuests[i].conditionValue {
                grandQuests[i].status = .achieved
            }
        }
    }

    // MARK: - Daily Quest: 오늘 완료 횟수 계산

    func todayCompletionCount(for questId: UUID) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return questCompletions.filter {
            $0.questId == questId && Calendar.current.isDate($0.date, inSameDayAs: today)
        }.count
    }

    func remainingCount(for quest: DailyQuest) -> Int {
        max(0, quest.dailyRepeatLimit - todayCompletionCount(for: quest.id))
    }

    func isQuestAvailable(_ quest: DailyQuest) -> Bool {
        quest.isActive && remainingCount(for: quest) > 0
    }

    // MARK: - Parent: Daily Quest Management

    func addDailyQuest(_ quest: DailyQuest) {
        dailyQuests.append(quest)
        saveData()
    }

    func updateDailyQuest(_ quest: DailyQuest) {
        if let index = dailyQuests.firstIndex(where: { $0.id == quest.id }) {
            dailyQuests[index] = quest
            saveData()
        }
    }

    func toggleDailyQuestActive(_ quest: DailyQuest) {
        if let index = dailyQuests.firstIndex(where: { $0.id == quest.id }) {
            dailyQuests[index].isActive.toggle()
            saveData()
        }
    }

    func removeDailyQuest(_ quest: DailyQuest) {
        dailyQuests.removeAll { $0.id == quest.id }
        saveData()
    }

    // MARK: - Parent PIN Auth

    func verifyPin(_ input: String) -> Bool {
        if let lockUntil = pinLockUntil, Date() < lockUntil {
            return false
        }
        if input == parentPin {
            pinAttempts = 0
            pinLockUntil = nil
            isParentMode = true
            return true
        } else {
            pinAttempts += 1
            if pinAttempts >= 5 {
                pinLockUntil = Date().addingTimeInterval(60) // 1분 잠금
            }
            return false
        }
    }

    func exitParentMode() {
        isParentMode = false
    }

    func changePin(_ newPin: String) {
        parentPin = newPin
        UserDefaults.standard.set(newPin, forKey: "parent_pin")
    }

    // MARK: - Theme

    func toggleRPGTheme() {
        isRPGTheme.toggle()
        UserDefaults.standard.set(isRPGTheme, forKey: "rpg_theme")
    }
}

// MARK: - Child Tab Enum

enum ChildTab: String, CaseIterable {
    case home = "홈"
    case shop = "상점"
    case wallet = "지갑"

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .shop: return "storefront.fill"
        case .wallet: return "wallet.pass.fill"
        }
    }
}

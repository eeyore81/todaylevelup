//
//  DataModels.swift
//  todaylevelup
//

import Foundation

// MARK: - Item Types

enum ItemType: String, Codable, CaseIterable {
    case timer       // 디지털 시간형 (게임, 유튜브) - 포모도로 플레이 타이머로 소비
    case consumable  // 실물 소멸형 (과자, 라면 등) - 소비 버튼으로 소비
}

// MARK: - Shop Item (부모가 등록한 상점 상품)

struct ShopItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var iconName: String
    var type: ItemType
    var costPoints: Int
    var timerMinutes: Int?       // TIMER 타입일 때 플레이 시간(분)
    var isActive: Bool = true    // 상점 진열 여부

    static func == (lhs: ShopItem, rhs: ShopItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Inventory Item (아이가 구매하여 보유 중인 카드)

struct InventoryItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var shopItem: ShopItem
    var purchasedDate: Date
    var isUsed: Bool = false

    static func == (lhs: InventoryItem, rhs: InventoryItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Grand Quest (장기 목표)

enum QuestConditionType: String, Codable, CaseIterable {
    case pomodoroCount  // 포모도로 누적 N회
    case levelReach     // 레벨 N 달성
}

enum QuestStatus: String, Codable {
    case ongoing    // 진행 중
    case achieved   // 달성 (부모 승인 대기)
    case rewarded   // 보상 지급 완료
}

struct GrandQuest: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var conditionType: QuestConditionType
    var conditionValue: Int
    var rewardText: String
    var status: QuestStatus = .ongoing
    var currentProgress: Int = 0

    var progressRatio: Double {
        guard conditionValue > 0 else { return 0 }
        return min(Double(currentProgress) / Double(conditionValue), 1.0)
    }

    static func == (lhs: GrandQuest, rhs: GrandQuest) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Child Profile

struct ChildProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var currentLevel: Int = 1
    var currentExp: Int = 0
    var pointBalance: Int = 100    // 테스트용 기본 포인트
    var totalPomodorosCompleted: Int = 0

    // 하루 일당 포인트 (부모가 설정, 디폴트 30)
    var dailyPointAllowance: Int = 30
    var lastDailyClaimDate: Date? = nil

    /// 오늘 이미 일당을 수령했는지 여부
    var claimedToday: Bool {
        guard let lastDate = lastDailyClaimDate else { return false }
        return Calendar.current.isDate(lastDate, inSameDayAs: Date())
    }

    /// 다음 레벨까지 필요한 EXP
    var expToNextLevel: Int {
        currentLevel * 100
    }

    var levelProgress: Double {
        guard expToNextLevel > 0 else { return 1.0 }
        return min(Double(currentExp) / Double(expToNextLevel), 1.0)
    }

    static func == (lhs: ChildProfile, rhs: ChildProfile) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Session Log

enum SessionType: String, Codable {
    case work  // 집중(공부)
    case play  // 플레이(게임)
}

struct SessionLog: Identifiable, Codable {
    var id: UUID = UUID()
    var type: SessionType
    var minutes: Int
    var date: Date
}

// MARK: - Daily Quest (부모가 만든 일일 퀘스트)

struct DailyQuest: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String              // 퀘스트 이름 (예: "수학 문제 10개 풀기")
    var iconName: String           // SF Symbol 이름
    var rewardPoints: Int          // 완료 시 받는 추가 포인트
    var dailyRepeatLimit: Int      // 하루 반복 가능 횟수
    var isActive: Bool = true

    static func == (lhs: DailyQuest, rhs: DailyQuest) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Quest Completion (퀘스트 수행 기록)

struct QuestCompletion: Identifiable, Codable {
    var id: UUID = UUID()
    var questId: UUID
    var date: Date
    var pomodoroMinutes: Int
}

// MARK: - Pomodoro Rewards

struct PomodoroReward {
    static let expPerSession: Int = 10
    static let pointsPerSession: Int = 10
    static let defaultFocusMinutes: Int = 25
}

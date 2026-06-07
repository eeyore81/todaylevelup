//
//  HomeView.swift
//  todaylevelup
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showTimer = false
    @State private var showParentAuth = false
    @State private var showDailyClaimed = false
    @State private var selectedQuestId: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - 프로필 & 레벨 카드
                    profileCard

                    // MARK: - 오늘의 포인트 (일당)
                    if appState.canClaimDailyPoints {
                        dailyClaimCard
                    } else {
                        dailyClaimedBadge
                    }

                    // MARK: - 그랜드 퀘스트
                    if !activeQuests.isEmpty {
                        grandQuestSection
                    }

                    // MARK: - 퀵 액션
                    quickActions

                    // MARK: - 일일 퀘스트
                    dailyQuestSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("오늘레벨업")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showParentAuth = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                }
            }
            .fullScreenCover(isPresented: $showTimer) {
                TimerView(timerType: .focus, questId: selectedQuestId)
            }
            .sheet(isPresented: $showParentAuth) {
                ParentAuthView()
            }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 12) {
            // 아바타
            ZStack {
                Circle()
                    .fill(levelGradient)
                    .frame(width: 80, height: 80)
                Text("Lv.\(appState.childProfile.currentLevel)")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }

            Text(appState.childProfile.name)
                .font(.title3.bold())

            // EXP 바
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 12)
                        Capsule()
                            .fill(levelGradient)
                            .frame(width: geo.size.width * appState.childProfile.levelProgress, height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("EXP \(appState.childProfile.currentExp) / \(appState.childProfile.expToNextLevel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(appState.childProfile.levelProgress * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                }
            }

            HStack(spacing: 24) {
                statItem(icon: "flame.fill", value: "\(appState.childProfile.totalPomodorosCompleted)", label: "포모도로", color: .orange)
                statItem(icon: "star.fill", value: "\(appState.childProfile.pointBalance)", label: "포인트", color: .yellow)
                statItem(icon: "wallet.pass.fill", value: "\(unusedInventoryCount)", label: "보유카드", color: .purple)
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    // MARK: - Grand Quest Section

    private var grandQuestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("그랜드 퀘스트", systemImage: "trophy.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            ForEach(activeQuests) { quest in
                grandQuestRow(quest)
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10)
    }

    private func grandQuestRow(_ quest: GrandQuest) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(quest.title)
                        .font(.subheadline.bold())
                    Text("보상: \(quest.rewardText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(quest.status == .achieved ? "🎉 달성!" : "\(quest.currentProgress)/\(quest.conditionValue)")
                    .font(.caption.bold())
                    .foregroundStyle(quest.status == .achieved ? .green : .orange)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    Capsule()
                        .fill(quest.status == .achieved ? Color.green : Color.orange)
                        .frame(width: geo.size.width * quest.progressRatio, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Daily Claim Card

    private var dailyClaimCard: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                appState.claimDailyPoints()
                showDailyClaimed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showDailyClaimed = false
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sun.max.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                    .symbolEffect(.bounce, value: showDailyClaimed)

                VStack(alignment: .leading, spacing: 2) {
                    Text("오늘의 포인트 받기")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("매일 +\(appState.childProfile.dailyPointAllowance)P 지급!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "gift.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.yellow.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var dailyClaimedBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Text("오늘의 포인트 수령 완료!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("+\(appState.childProfile.dailyPointAllowance)P")
                .font(.subheadline.bold())
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 16) {
            NavigationLink(destination: WalletView()) {
                quickActionCard(
                    icon: "wallet.pass.fill",
                    title: "내 지갑",
                    subtitle: "보유 \(unusedInventoryCount)장",
                    color: .purple
                )
            }
            .buttonStyle(.plain)

            NavigationLink(destination: ShopView()) {
                quickActionCard(
                    icon: "storefront.fill",
                    title: "상점",
                    subtitle: "\(appState.childProfile.pointBalance) P",
                    color: .orange
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func quickActionCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }

    // MARK: - Daily Quest Section

    private var dailyQuestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("오늘의 퀘스트", systemImage: "checklist")
                .font(.headline)

            if availableQuests.isEmpty {
                HStack {
                    Image(systemName: "tray.fill")
                        .foregroundStyle(.secondary)
                    Text("오늘 수행할 수 있는 퀘스트가 없어요")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ForEach(availableQuests) { quest in
                    questCard(quest)
                }
            }
        }
    }

    private func questCard(_ quest: DailyQuest) -> some View {
        Button {
            selectedQuestId = quest.id
            showTimer = true
        } label: {
            HStack(spacing: 14) {
                // 퀘스트 아이콘
                ZStack {
                    Circle()
                        .fill(questIconColor(quest).opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: quest.iconName)
                        .font(.title3)
                        .foregroundStyle(questIconColor(quest))
                }

                // 퀘스트 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    HStack(spacing: 6) {
                        Label("+\(quest.rewardPoints)P", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Label("25분", systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                Spacer()

                // 남은 횟수
                VStack(spacing: 2) {
                    Text("남은 횟수")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(appState.remainingCount(for: quest))회")
                        .font(.title3.bold())
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: questIconColor(quest).opacity(0.08), radius: 6)
        }
        .buttonStyle(.plain)
    }

    private func questIconColor(_ quest: DailyQuest) -> Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .teal, .indigo]
        let hash = abs(quest.iconName.hashValue) % colors.count
        return colors[hash]
    }

    // MARK: - Quick Actions

    private var levelGradient: LinearGradient {
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var unusedInventoryCount: Int {
        appState.inventory.filter { !$0.isUsed }.count
    }

    private var availableQuests: [DailyQuest] {
        appState.dailyQuests.filter { appState.isQuestAvailable($0) }
    }

    private var activeQuests: [GrandQuest] {
        appState.grandQuests.filter { $0.status != .rewarded }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
}

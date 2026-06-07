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
    @State private var entranceAnimation = false

    var body: some View {
        NavigationStack {
            ZStack {
                (rpg ? RPGTheme.bgDark : Color(.systemGroupedBackground)).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: rpg ? 16 : 24) {
                        profileCard
                        if appState.canClaimDailyPoints { dailyClaimCard } else { dailyClaimedBadge }
                        if !activeGrandQuests.isEmpty { grandQuestSection }
                        quickActions
                        dailyQuestSection
                    }
                    .padding()
                    .opacity(entranceAnimation ? 1 : 0)
                    .offset(y: entranceAnimation ? 0 : 30)
                }
            }
            .navigationTitle(rpg ? "🏰 오늘의 던전" : "오늘레벨업")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showParentAuth = true } label: {
                        Image(systemName: "gearshape.fill").font(.title3)
                            .foregroundStyle(rpg ? RPGTheme.gold : .primary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showTimer) { TimerView(timerType: .focus, questId: selectedQuestId) }
            .sheet(isPresented: $showParentAuth) { ParentAuthView() }
        }
        .onAppear { withAnimation(.easeOut(duration: 0.8)) { entranceAnimation = true } }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: rpg ? 10 : 12) {
            if rpg {
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "diamond.fill").font(.caption2).foregroundStyle(RPGTheme.goldDim)
                    }
                }
                Text("⚔️ 용사 정보 ⚔️").font(.system(size: 13).weight(.bold)).foregroundStyle(RPGTheme.textGold).tracking(4)
            }
            ZStack {
                if rpg {
                    Circle().stroke(RPGTheme.gold, lineWidth: 3).frame(width: 84, height: 84)
                        .shadow(color: RPGTheme.gold.opacity(0.4), radius: 6)
                }
                Circle().fill(rpg ? AnyShapeStyle(RPGTheme.bgElevated) : AnyShapeStyle(levelGradient))
                    .frame(width: rpg ? 76 : 80, height: rpg ? 76 : 80)
                Text("Lv.\(appState.childProfile.currentLevel)").font(.title2.bold())
                    .foregroundStyle(rpg ? RPGTheme.textGold : .white)
            }
            Text(appState.childProfile.name)
                .font(rpg ? .system(size: 20).weight(.bold) : .title3.bold())
                .foregroundStyle(rpg ? RPGTheme.textPrimary : .primary).tracking(rpg ? 3 : 0)

            VStack(spacing: 4) {
                if rpg {
                    RPGProgressBar(progress: appState.childProfile.levelProgress, color: RPGTheme.expBar)
                } else {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.systemGray5)).frame(height: 12)
                            Capsule().fill(levelGradient).frame(width: geo.size.width * appState.childProfile.levelProgress, height: 12)
                        }
                    }.frame(height: 12)
                }
                HStack {
                    Text("EXP \(appState.childProfile.currentExp) / \(appState.childProfile.expToNextLevel)")
                        .font(.caption).foregroundStyle(rpg ? RPGTheme.textSecondary : .secondary)
                    Spacer()
                    Text("\(Int(appState.childProfile.levelProgress * 100))%")
                        .font(.caption.bold()).foregroundStyle(rpg ? RPGTheme.expBar : .blue)
                }
            }

            HStack(spacing: rpg ? 20 : 24) {
                statItem(icon: "flame.fill", value: "\(appState.childProfile.totalPomodorosCompleted)",
                         label: rpg ? "전투" : "포모도로", color: rpg ? RPGTheme.dangerRed : .orange)
                statItem(icon: rpg ? "dollarsign.circle.fill" : "star.fill", value: "\(appState.childProfile.pointBalance)",
                         label: rpg ? "골드" : "포인트", color: rpg ? RPGTheme.gold : .yellow)
                statItem(icon: "wallet.pass.fill", value: "\(unusedInventoryCount)",
                         label: rpg ? "아이템" : "보유카드", color: rpg ? RPGTheme.questPurple : .purple)
            }
        }
        .padding()
        .background(rpg ? RPGTheme.bgCard : .white)
        .clipShape(RoundedRectangle(cornerRadius: rpg ? 12 : 20))
        .overlay { if rpg { RoundedRectangle(cornerRadius: 12).stroke(RPGTheme.borderGold, lineWidth: 1.5) } }
        .shadow(color: rpg ? .black.opacity(0.4) : .black.opacity(0.05), radius: rpg ? 8 : 10)
    }

    // MARK: - Grand Quest Section

    private var grandQuestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if rpg {
                RPGOrnateHeader(title: "위대한 원정", icon: "trophy.fill")
            } else {
                Label("그랜드 퀘스트", systemImage: "trophy.fill").font(.headline).foregroundStyle(.orange)
            }
            ForEach(activeGrandQuests) { quest in grandQuestRow(quest) }
        }
        .padding()
        .background(rpg ? RPGTheme.bgCard : .white)
        .clipShape(RoundedRectangle(cornerRadius: rpg ? 12 : 20))
        .overlay { if rpg { RoundedRectangle(cornerRadius: 12).stroke(RPGTheme.borderGold, lineWidth: 1.5) } }
        .shadow(color: rpg ? .black.opacity(0.3) : .black.opacity(0.05), radius: rpg ? 6 : 10)
    }

    private func grandQuestRow(_ quest: GrandQuest) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(quest.title).font(.subheadline.bold()).foregroundStyle(rpg ? RPGTheme.textPrimary : .primary)
                    Text("보상: \(quest.rewardText)").font(.caption).foregroundStyle(rpg ? RPGTheme.textSecondary : .secondary)
                }
                Spacer()
                Text(quest.status == .achieved ? "🎉 달성!" : "\(quest.currentProgress)/\(quest.conditionValue)")
                    .font(.caption.bold())
                    .foregroundStyle(quest.status == .achieved ? (rpg ? RPGTheme.gold : .green) : (rpg ? RPGTheme.goldLight : .orange))
            }
            if rpg {
                RPGProgressBar(progress: quest.progressRatio, color: quest.status == .achieved ? RPGTheme.hpGreen : RPGTheme.gold, height: 6)
            } else {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.systemGray5)).frame(height: 8)
                        Capsule().fill(quest.status == .achieved ? Color.green : Color.orange)
                            .frame(width: geo.size.width * quest.progressRatio, height: 8)
                    }
                }.frame(height: 8)
            }
        }
        .padding(12)
        .background(rpg ? RPGTheme.bgElevated : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Daily Claim

    private var dailyClaimCard: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appState.claimDailyPoints(); showDailyClaimed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showDailyClaimed = false }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: rpg ? "bolt.fill" : "sun.max.fill").font(.title2)
                    .foregroundStyle(rpg ? RPGTheme.goldLight : .yellow).symbolEffect(.bounce, value: showDailyClaimed)
                VStack(alignment: .leading, spacing: 2) {
                    Text(rpg ? "오늘의 골드 수령" : "오늘의 포인트 받기").font(.headline).foregroundStyle(rpg ? RPGTheme.textGold : .primary)
                    Text(rpg ? "매일 +\(appState.childProfile.dailyPointAllowance)골드!" : "매일 +\(appState.childProfile.dailyPointAllowance)P 지급!")
                        .font(.caption).foregroundStyle(rpg ? RPGTheme.textSecondary : .secondary)
                }
                Spacer()
                Image(systemName: rpg ? "dollarsign.circle.fill" : "gift.fill").font(.title3).foregroundStyle(rpg ? RPGTheme.gold : .orange)
            }
            .padding()
            .background(rpg ? RPGTheme.bgCard : Color.yellow.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: rpg ? 12 : 16).stroke(rpg ? RPGTheme.goldDim : Color.yellow.opacity(0.3), lineWidth: 1) }
        }.buttonStyle(.plain)
    }

    private var dailyClaimedBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(rpg ? RPGTheme.hpGreen : .green)
            Text(rpg ? "오늘의 골드 수령 완료!" : "오늘의 포인트 수령 완료!").font(.subheadline).foregroundStyle(rpg ? RPGTheme.textSecondary : .secondary)
            Spacer()
            Text("+\(appState.childProfile.dailyPointAllowance)\(rpg ? "G" : "P")").font(.subheadline.bold()).foregroundStyle(rpg ? RPGTheme.gold : .green)
        }.padding(.horizontal, 4)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 16) {
            NavigationLink(destination: WalletView()) {
                quickActionCard(icon: "wallet.pass.fill", title: rpg ? "가방" : "내 지갑",
                                subtitle: rpg ? "아이템 \(unusedInventoryCount)개" : "보유 \(unusedInventoryCount)장",
                                color: rpg ? RPGTheme.questPurple : .purple)
            }.buttonStyle(.plain)
            NavigationLink(destination: ShopView()) {
                quickActionCard(icon: "storefront.fill", title: "상점",
                                subtitle: "\(appState.childProfile.pointBalance) \(rpg ? "G" : "P")",
                                color: rpg ? RPGTheme.gold : .orange)
            }.buttonStyle(.plain)
        }
    }

    private func quickActionCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title).foregroundStyle(color)
            Text(title).font(.headline).foregroundStyle(rpg ? RPGTheme.textPrimary : .primary)
            Text(subtitle).font(.caption).foregroundStyle(rpg ? RPGTheme.textSecondary : .secondary)
        }
        .frame(maxWidth: .infinity).padding()
        .background(rpg ? RPGTheme.bgCard : .white)
        .clipShape(RoundedRectangle(cornerRadius: rpg ? 12 : 16))
        .overlay { if rpg { RoundedRectangle(cornerRadius: 12).stroke(RPGTheme.borderDim, lineWidth: 1) } }
        .shadow(color: rpg ? .black.opacity(0.3) : .black.opacity(0.05), radius: rpg ? 6 : 8)
    }

    // MARK: - Daily Quest Section

    private var dailyQuestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if rpg {
                RPGOrnateHeader(title: "오늘의 의뢰", icon: "scroll.fill")
            } else {
                Label("오늘의 퀘스트", systemImage: "checklist").font(.headline)
            }
            if availableQuests.isEmpty {
                HStack {
                    Image(systemName: rpg ? "moon.stars.fill" : "tray.fill").foregroundStyle(rpg ? RPGTheme.textSecondary : .secondary)
                    Text(rpg ? "모든 의뢰를 완료했습니다!" : "오늘 수행할 수 있는 퀘스트가 없어요")
                        .font(.subheadline).foregroundStyle(rpg ? RPGTheme.textSecondary : .secondary)
                }
                .padding().frame(maxWidth: .infinity)
                .background(rpg ? RPGTheme.bgCard : .white)
                .clipShape(RoundedRectangle(cornerRadius: rpg ? 12 : 16))
                .overlay { if rpg { RoundedRectangle(cornerRadius: 12).stroke(RPGTheme.borderDim, lineWidth: 1) } }
            } else {
                ForEach(availableQuests) { quest in questCard(quest) }
            }
        }
    }

    private func questCard(_ quest: DailyQuest) -> some View {
        Button { selectedQuestId = quest.id; showTimer = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(questIconColor(quest).opacity(rpg ? 0.3 : 0.15)).frame(width: 48, height: 48)
                    if rpg { Circle().stroke(questIconColor(quest).opacity(0.5), lineWidth: 1.5).frame(width: 48, height: 48) }
                    Image(systemName: quest.iconName).font(.title3).foregroundStyle(questIconColor(quest))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.title).font(.headline).foregroundStyle(rpg ? RPGTheme.textPrimary : .primary)
                    HStack(spacing: 6) {
                        Label("+\(quest.rewardPoints)\(rpg ? "G" : "P")", systemImage: rpg ? "dollarsign.circle.fill" : "star.fill")
                            .font(.caption).foregroundStyle(rpg ? RPGTheme.gold : .orange)
                        Label("25분", systemImage: "timer").font(.caption).foregroundStyle(rpg ? RPGTheme.manaBlue : .blue)
                    }
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(rpg ? "잔여" : "남은 횟수").font(.caption2).foregroundStyle(rpg ? RPGTheme.textSecondary : .secondary)
                    Text("\(appState.remainingCount(for: quest))회").font(.title3.bold()).foregroundStyle(rpg ? RPGTheme.goldLight : .blue)
                }
            }
            .padding()
            .background(rpg ? RPGTheme.bgCard : .white)
            .clipShape(RoundedRectangle(cornerRadius: rpg ? 10 : 16))
            .overlay { if rpg { RoundedRectangle(cornerRadius: 10).stroke(RPGTheme.goldDim.opacity(0.6), lineWidth: 1) } }
            .shadow(color: rpg ? questIconColor(quest).opacity(0.15) : questIconColor(quest).opacity(0.08), radius: rpg ? 8 : 6)
        }.buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var rpg: Bool { appState.isRPGTheme }
    private var levelGradient: LinearGradient { LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) }

    private func statItem(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.headline).foregroundStyle(rpg ? RPGTheme.textPrimary : .primary)
            Text(label).font(.caption2).foregroundStyle(rpg ? RPGTheme.textSecondary : .secondary)
        }
    }

    private func questIconColor(_ quest: DailyQuest) -> Color {
        [.blue, .purple, .green, .orange, .pink, .teal, .indigo][abs(quest.iconName.hashValue) % 7]
    }

    private var unusedInventoryCount: Int { appState.inventory.filter { !$0.isUsed }.count }
    private var availableQuests: [DailyQuest] { appState.dailyQuests.filter { appState.isQuestAvailable($0) } }
    private var activeGrandQuests: [GrandQuest] { appState.grandQuests.filter { $0.status != .rewarded } }
}

#Preview {
    HomeView()
        .environment(AppState())
}

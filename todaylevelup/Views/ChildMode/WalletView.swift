//
//  WalletView.swift
//  todaylevelup
//

import SwiftUI

struct WalletView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedItem: InventoryItem?
    @State private var showConsumeAlert = false
    @State private var showPlayTimer = false
    @State private var showParentRequest = false
    @State private var cardToShred: UUID?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            (rpg ? RPGTheme.bgDark : Color(.systemGroupedBackground)).ignoresSafeArea()
            VStack(spacing: 0) {
                walletHeader
                ScrollView {
                    if unusedItems.isEmpty && usedItems.isEmpty {
                        emptyWalletView
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            if !unusedItems.isEmpty {
                                Text(rpg ? "🎒 사용 가능" : "사용 가능").font(.headline)
                                    .foregroundStyle(rpg ? RPGTheme.textGold : .primary).padding(.horizontal)
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(unusedItems) { walletCard($0) }
                                }.padding(.horizontal)
                            }
                            if !usedItems.isEmpty {
                                Text("사용 완료").font(.headline)
                                    .foregroundStyle(rpg ? RPGTheme.textSecondary : .secondary).padding(.horizontal)
                                LazyVGrid(columns: columns, spacing: 12) {
                                    ForEach(usedItems) { usedCardView($0) }
                                }.padding(.horizontal)
                            }
                        }.padding(.vertical)
                    }
                }
            }
        }
        .navigationTitle(rpg ? "🎒 모험가 가방" : "내 지갑")
        .alert("아이템 사용", isPresented: $showConsumeAlert) {
            Button("취소", role: .cancel) { }
            if let item = selectedItem {
                if item.shopItem.type == .timer {
                    Button("플레이 시작!") {
                        showPlayTimer = true
                    }
                } else {
                    Button("부모님께 보여드리기") {
                        showParentRequest = true
                    }
                }
            }
        } message: {
            if let item = selectedItem {
                if item.shopItem.type == .timer {
                    Text("\(item.shopItem.name) (\(item.shopItem.timerMinutes ?? 0)분) 플레이 타이머를 시작할까요?")
                } else {
                    Text("\(item.shopItem.name)을(를) 사용하려면 부모님께 기기를 보여주세요!")
                }
            }
        }
        .fullScreenCover(isPresented: $showPlayTimer) {
            if let item = selectedItem {
                TimerView(timerType: .play(minutes: item.shopItem.timerMinutes ?? 10), inventoryItem: item)
            }
        }
        .sheet(isPresented: $showParentRequest) {
            parentRequestSheet
        }
    }

    // MARK: - Wallet Header

    private var walletHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rpg ? "보유 아이템" : "보유 카드").font(.subheadline).foregroundStyle(rpg ? RPGTheme.textSecondary : .secondary)
                Text("\(unusedItems.count)\(rpg ? "개" : "장")").font(.title.bold()).foregroundStyle(rpg ? RPGTheme.textPrimary : .primary)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: rpg ? "dollarsign.circle.fill" : "star.fill").foregroundStyle(rpg ? RPGTheme.gold : .yellow)
                Text("\(appState.childProfile.pointBalance) \(rpg ? "G" : "P")").font(.headline).foregroundStyle(rpg ? RPGTheme.gold : .primary)
            }
        }
        .padding()
        .background(rpg ? RPGTheme.bgCard : .white)
        .overlay(alignment: .bottom) {
            if rpg { Rectangle().fill(RPGTheme.goldDim).frame(height: 1) }
        }
    }

    // MARK: - Wallet Card

    private func walletCard(_ item: InventoryItem) -> some View {
        Button {
            selectedItem = item
            showConsumeAlert = true
        } label: {
            cardContent(item, isUsed: false)
        }
        .buttonStyle(.plain)
    }

    private func usedCardView(_ item: InventoryItem) -> some View {
        cardContent(item, isUsed: true)
    }

    private func cardContent(_ item: InventoryItem, isUsed: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(itemColor(item.shopItem).opacity(isUsed ? (rpg ? 0.05 : 0.1) : (rpg ? 0.25 : 0.2)))
                    .frame(width: 48, height: 48)
                if rpg && !isUsed {
                    RoundedRectangle(cornerRadius: 12).stroke(itemColor(item.shopItem).opacity(0.4), lineWidth: 1).frame(width: 48, height: 48)
                }
                Image(systemName: item.shopItem.iconName).font(.title2)
                    .foregroundStyle(isUsed ? (rpg ? RPGTheme.textSecondary : .secondary) : itemColor(item.shopItem))
            }
            Text(item.shopItem.name).font(.subheadline.bold())
                .foregroundStyle(isUsed ? (rpg ? RPGTheme.textSecondary : .secondary) : (rpg ? RPGTheme.textPrimary : .primary))
                .lineLimit(1)
            HStack(spacing: 2) {
                Image(systemName: item.shopItem.type == .timer ? "timer" : "takeoutbag.and.cup.and.straw.fill").font(.caption2)
                Text(item.shopItem.type == .timer ? "\(item.shopItem.timerMinutes ?? 0)분" : "소비").font(.caption2)
            }.foregroundStyle(rpg ? RPGTheme.textSecondary : .secondary)
            if isUsed {
                Label("사용 완료", systemImage: "checkmark.circle.fill").font(.caption2)
                    .foregroundStyle(rpg ? RPGTheme.hpGreen : .green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(rpg ? RPGTheme.bgCard : .white)
        .clipShape(RoundedRectangle(cornerRadius: rpg ? 12 : 16))
        .shadow(color: rpg ? .black.opacity(0.3) : .black.opacity(0.03), radius: 6)
        .opacity(isUsed ? 0.6 : 1.0)
        .overlay { if cardToShred == item.id { shredOverlay } }
    }

    // MARK: - Parent Request Sheet

    private var parentRequestSheet: some View {
        VStack(spacing: 24) {
            if let item = selectedItem {
                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)

                Text("부모님께 보여주세요!")
                    .font(.title2.bold())

                Text("\(item.shopItem.name)을(를) 사용하려면\n부모님의 확인이 필요해요")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                VStack(spacing: 12) {
                    Button {
                        // 부모 승인 시뮬레이션 (실제로는 부모 PIN 입력 필요)
                        appState.confirmConsumableUsed(item)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            cardToShred = item.id
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            cardToShred = nil
                            showParentRequest = false
                            selectedItem = nil
                        }
                    } label: {
                        Label("부모님 확인 완료", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .presentationDetents([.medium])
    }

    // MARK: - Shred Overlay (파쇄 이펙트)

    private var shredOverlay: some View {
        VStack {
            Image(systemName: "trash.slash.fill")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("사용 완료!")
                .font(.caption.bold())
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Empty State

    private var emptyWalletView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("지갑이 비어있어요")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("미션을 완료하고 포인트로\n상점에서 아이템을 구매해보세요!")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 80)
    }

    // MARK: - Helpers

    private var rpg: Bool { appState.isRPGTheme }

    private var unusedItems: [InventoryItem] {
        appState.inventory.filter { !$0.isUsed }
    }

    private var usedItems: [InventoryItem] {
        appState.inventory.filter { $0.isUsed }
    }

    private func itemColor(_ item: ShopItem) -> Color {
        item.type == .timer ? .blue : .orange
    }
}

#Preview {
    NavigationStack {
        WalletView()
            .environment(AppState())
    }
}

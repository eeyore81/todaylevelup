//
//  ShopView.swift
//  todaylevelup
//

import SwiftUI

struct ShopView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedItem: ShopItem?
    @State private var showPurchaseAlert = false
    @State private var purchaseSuccess = false
    @State private var flyingCard = false

    var body: some View {
        VStack(spacing: 0) {
            // 포인트 잔액 헤더
            pointHeader

            // 상품 리스트
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(activeShopItems) { item in
                        shopItemRow(item)
                    }

                    if activeShopItems.isEmpty {
                        emptyShopView
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("포인트 상점")
        .alert("구매 확인", isPresented: $showPurchaseAlert) {
            Button("취소", role: .cancel) { }
            Button("구매하기") {
                if let item = selectedItem {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        purchaseSuccess = appState.purchaseItem(item)
                        flyingCard = purchaseSuccess
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        flyingCard = false
                        selectedItem = nil
                    }
                }
            }
        } message: {
            if let item = selectedItem {
                Text("\(item.name)을(를) \(item.costPoints)포인트로 구매하시겠습니까?")
            }
        }
        .overlay {
            if flyingCard, let item = selectedItem {
                flyingCardOverlay(item)
            }
        }
    }

    // MARK: - Point Header

    private var pointHeader: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text("보유 포인트")
                .font(.subheadline)
            Spacer()
            Text("\(appState.childProfile.pointBalance) P")
                .font(.title2.bold())
                .foregroundStyle(.orange)
        }
        .padding()
        .background(.white)
    }

    // MARK: - Shop Item Row

    private func shopItemRow(_ item: ShopItem) -> some View {
        HStack(spacing: 16) {
            // 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(itemColor(item).opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: item.iconName)
                    .font(.title3)
                    .foregroundStyle(itemColor(item))
            }

            // 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                HStack(spacing: 4) {
                    Image(systemName: item.type == .timer ? "timer" : "takeoutbag.and.cup.and.straw.fill")
                        .font(.caption)
                    Text(item.type == .timer ? "게임시간 (\(item.timerMinutes ?? 0)분)" : "실물 보상")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 가격 & 구매 버튼
            VStack(spacing: 8) {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text("\(item.costPoints)")
                        .font(.headline)
                }

                Button {
                    selectedItem = item
                    showPurchaseAlert = true
                } label: {
                    Text("구매")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            canAfford(item)
                                ? Color.blue
                                : Color(.systemGray3)
                        )
                        .clipShape(Capsule())
                }
                .disabled(!canAfford(item))
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 6)
    }

    // MARK: - Empty State

    private var emptyShopView: some View {
        VStack(spacing: 16) {
            Image(systemName: "storefront.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("상점이 비어있어요")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("부모님이 상점에 상품을 추가할 거예요!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 80)
    }

    // MARK: - Flying Card Overlay

    private func flyingCardOverlay(_ item: ShopItem) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: item.iconName)
                        .font(.largeTitle)
                        .foregroundStyle(itemColor(item))
                    Text("\(item.name) 획득!")
                        .font(.headline)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                Spacer()
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private var activeShopItems: [ShopItem] {
        appState.shopItems.filter { $0.isActive }
    }

    private func canAfford(_ item: ShopItem) -> Bool {
        appState.childProfile.pointBalance >= item.costPoints
    }

    private func itemColor(_ item: ShopItem) -> Color {
        item.type == .timer ? .blue : .orange
    }
}

#Preview {
    NavigationStack {
        ShopView()
            .environment(AppState())
    }
}

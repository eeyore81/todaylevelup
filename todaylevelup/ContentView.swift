//
//  ContentView.swift
//  todaylevelup
//
//  Created by margarine on 6/7/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            if appState.isParentMode {
                ParentDashboardView()
                    .transition(.move(edge: .trailing))
            } else {
                childModeView
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: appState.isParentMode)
    }

    // MARK: - Child Mode (Tab View)

    private var childModeView: some View {
        TabView(selection: appState.selectedTabBinding) {
            HomeView()
                .tabItem {
                    Label(ChildTab.home.rawValue, systemImage: ChildTab.home.iconName)
                }
                .tag(ChildTab.home)

            ShopView()
                .tabItem {
                    Label(ChildTab.shop.rawValue, systemImage: ChildTab.shop.iconName)
                }
                .tag(ChildTab.shop)

            WalletView()
                .tabItem {
                    Label(ChildTab.wallet.rawValue, systemImage: ChildTab.wallet.iconName)
                }
                .tag(ChildTab.wallet)
        }
        .tint(.blue)
    }
}

// MARK: - AppState Tab Binding Extension

extension AppState {
    var selectedTabBinding: Binding<ChildTab> {
        Binding(
            get: { self.selectedTab },
            set: { self.selectedTab = $0 }
        )
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}

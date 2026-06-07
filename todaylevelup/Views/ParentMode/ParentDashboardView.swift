//
//  ParentDashboardView.swift
//  todaylevelup
//

import SwiftUI

struct ParentDashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 자녀 현황
                Section("👤 자녀 현황") {
                    HStack {
                        Text("이름")
                        Spacer()
                        Text(appState.childProfile.name)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("현재 레벨")
                        Spacer()
                        Text("Lv.\(appState.childProfile.currentLevel)")
                            .foregroundStyle(.blue)
                    }
                    HStack {
                        Text("보유 포인트")
                        Spacer()
                        Text("\(appState.childProfile.pointBalance) P")
                            .foregroundStyle(.orange)
                    }
                    HStack {
                        Text("총 포모도로")
                        Spacer()
                        Text("\(appState.childProfile.totalPomodorosCompleted)회")
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: - 하루 일당 포인트 설정
                Section {
                    HStack {
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(.yellow)
                        Text("하루 일당")
                        Spacer()
                        Stepper {
                            Text("\(appState.childProfile.dailyPointAllowance) P")
                                .bold()
                                .foregroundStyle(.orange)
                        } onIncrement: {
                            appState.setDailyAllowance(appState.childProfile.dailyPointAllowance + 5)
                        } onDecrement: {
                            appState.setDailyAllowance(max(0, appState.childProfile.dailyPointAllowance - 5))
                        }
                    }
                } header: {
                    Text("💸 일당 포인트")
                } footer: {
                    Text("매일 아이가 '오늘의 포인트 받기'로 수령하는 기본 포인트입니다. 미션 수행 없이도 최소한의 포인트를 보장합니다.")
                }

                // MARK: - 일일 퀘스트 관리
                Section("📋 일일 퀘스트") {
                    NavigationLink {
                        QuestAdminView()
                    } label: {
                        Label("퀘스트 관리 (\(activeQuestCount)개 활성)", systemImage: "checklist")
                    }
                }

                // MARK: - 상점 관리
                Section("🏪 상점 관리") {
                    NavigationLink {
                        ShopAdminView()
                    } label: {
                        Label("상품 관리 (\(activeShopCount)개 진열 중)", systemImage: "storefront.fill")
                    }
                }

                // MARK: - 그랜드 퀘스트 관리
                Section("🏆 그랜드 퀘스트") {
                    NavigationLink {
                        GrandQuestAdminView()
                    } label: {
                        Label("퀘스트 관리 (\(pendingApprovalCount)개 승인 대기)", systemImage: "trophy.fill")
                    }
                }

                // MARK: - PIN 변경
                Section("🔒 보안") {
                    NavigationLink {
                        ChangePinView()
                    } label: {
                        Label("PIN 번호 변경", systemImage: "lock.rotation")
                    }
                }

                // MARK: - 테마
                Section {
                    Toggle(isOn: Binding(
                        get: { appState.isRPGTheme },
                        set: { _ in appState.toggleRPGTheme() }
                    )) {
                        Label("RPG 던전 테마", systemImage: appState.isRPGTheme ? "shield.lefthalf.filled" : "shield.righthalf.filled")
                    }
                } header: {
                    Text("🎨 테마 설정")
                } footer: {
                    Text("ON: 던전 게임처럼 어두운 RPG 스타일로 변경됩니다.\nOFF: 기본 깔끔한 모던 스타일입니다.")
                }

                // MARK: - 종료
                Section {
                    Button(role: .destructive) {
                        appState.exitParentMode()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("관리자 모드 종료", systemImage: "lock.open.fill")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("부모 관리 모드")
        }
    }

    private var activeShopCount: Int {
        appState.shopItems.filter { $0.isActive }.count
    }

    private var activeQuestCount: Int {
        appState.dailyQuests.filter { $0.isActive }.count
    }

    private var pendingApprovalCount: Int {
        appState.grandQuests.filter { $0.status == .achieved }.count
    }
}

// MARK: - Change PIN View

struct ChangePinView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var currentPin = ""
    @State private var newPin = ""
    @State private var confirmPin = ""
    @State private var errorMessage: String?
    @State private var successMessage = false

    var body: some View {
        Form {
            Section("현재 PIN") {
                SecureField("현재 PIN 4자리", text: $currentPin)
                    .keyboardType(.numberPad)
            }

            Section("새 PIN") {
                SecureField("새 PIN 4자리", text: $newPin)
                    .keyboardType(.numberPad)
                SecureField("새 PIN 확인", text: $confirmPin)
                    .keyboardType(.numberPad)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    changePin()
                } label: {
                    HStack {
                        Spacer()
                        Text("PIN 변경")
                            .bold()
                        Spacer()
                    }
                }
                .disabled(currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty)
            }
        }
        .navigationTitle("PIN 변경")
        .alert("성공", isPresented: $successMessage) {
            Button("확인") { dismiss() }
        } message: {
            Text("PIN 번호가 변경되었습니다.")
        }
    }

    private func changePin() {
        guard currentPin == appState.parentPin else {
            errorMessage = "현재 PIN이 일치하지 않습니다."
            return
        }
        guard newPin.count == 4, newPin.allSatisfy({ $0.isNumber }) else {
            errorMessage = "새 PIN은 숫자 4자리여야 합니다."
            return
        }
        guard newPin == confirmPin else {
            errorMessage = "새 PIN이 일치하지 않습니다."
            return
        }
        appState.changePin(newPin)
        successMessage = true
    }
}

#Preview {
    ParentDashboardView()
        .environment(AppState())
}

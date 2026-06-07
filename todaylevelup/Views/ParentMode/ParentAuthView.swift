//
//  ParentAuthView.swift
//  todaylevelup
//

import SwiftUI

struct ParentAuthView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var pinInput = ""
    @State private var shake = false
    @State private var errorMessage: String?

    private let pinLength = 4

    var body: some View {
        VStack(spacing: 32) {
            // 헤더
            VStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
                Text("부모님 확인")
                    .font(.title2.bold())
                Text("관리자 모드로 이동하려면\nPIN을 입력해주세요")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)

            // PIN 도트 표시
            HStack(spacing: 20) {
                ForEach(0..<pinLength, id: \.self) { index in
                    Circle()
                        .fill(index < pinInput.count ? Color.blue : Color(.systemGray4))
                        .frame(width: 20, height: 20)
                        .scaleEffect(index < pinInput.count ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: pinInput.count)
                }
            }
            .modifier(ShakeEffect(shakes: shake ? 2 : 0))
            .animation(shake ? .default.repeatCount(3) : .default, value: shake)

            // 에러 메시지
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if isLockedOut {
                // 잠금 상태
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text("\(remainingLockSeconds)초 후에\n다시 시도할 수 있어요")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            } else {
                // 숫자 키패드
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(1...9, id: \.self) { num in
                        pinButton("\(num)")
                    }
                    pinButton("")  // 빈칸
                    pinButton("0")
                    pinButton("⌫", isDelete: true)
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            // 닫기 버튼
            Button {
                dismiss()
            } label: {
                Text("닫기")
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 20)
        }
        .presentationDetents([.large])
    }

    // MARK: - PIN Button

    private func pinButton(_ label: String, isDelete: Bool = false) -> some View {
        Button {
            if isDelete {
                if !pinInput.isEmpty {
                    pinInput.removeLast()
                }
            } else if !label.isEmpty {
                guard pinInput.count < pinLength else { return }
                pinInput.append(label)
                if pinInput.count == pinLength {
                    verifyPin()
                }
            }
        } label: {
            if isDelete {
                Image(systemName: "delete.left")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 70, height: 60)
            } else if label.isEmpty {
                Color.clear
                    .frame(width: 70, height: 60)
            } else {
                Text(label)
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                    .frame(width: 70, height: 60)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - PIN Verification

    private func verifyPin() {
        if appState.verifyPin(pinInput) {
            dismiss()
        } else {
            errorMessage = "PIN이 일치하지 않습니다"
            withAnimation { shake.toggle() }
            pinInput = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                errorMessage = nil
            }
        }
    }

    // MARK: - Lock State

    private var isLockedOut: Bool {
        if let lockUntil = appState.pinLockUntil, Date() < lockUntil {
            return true
        }
        return false
    }

    private var remainingLockSeconds: Int {
        guard let lockUntil = appState.pinLockUntil else { return 0 }
        return max(0, Int(lockUntil.timeIntervalSinceNow))
    }
}

// MARK: - Shake Effect Modifier

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(CGFloat(shakes) * .pi)
        return ProjectionTransform(CGAffineTransform(translationX: translation * 10, y: 0))
    }
}

#Preview {
    ParentAuthView()
        .environment(AppState())
}

//
//  RPGTheme.swift
//  todaylevelup
//

import SwiftUI

// MARK: - RPG Theme Constants

struct RPGTheme {
    // 배경
    static let bgDark      = Color(red: 0.08, green: 0.06, blue: 0.16)   // 깊은 던전 어둠
    static let bgCard      = Color(red: 0.15, green: 0.10, blue: 0.22)   // 카드 배경
    static let bgElevated  = Color(red: 0.20, green: 0.14, blue: 0.28)   // 떠있는 카드

    // 골드/장식
    static let gold        = Color(red: 0.95, green: 0.75, blue: 0.20)   // 골드
    static let goldDim     = Color(red: 0.60, green: 0.45, blue: 0.10)   // 어두운 골드
    static let goldLight   = Color(red: 1.00, green: 0.88, blue: 0.50)   // 밝은 골드

    // 텍스트
    static let textPrimary = Color(red: 0.93, green: 0.90, blue: 0.80)   // 양피지색
    static let textSecondary = Color(red: 0.65, green: 0.60, blue: 0.50) // 보조 텍스트
    static let textGold    = Color(red: 0.95, green: 0.78, blue: 0.30)

    // 액센트
    static let expBar      = Color(red: 0.20, green: 0.70, blue: 0.90)   // EXP 바
    static let hpGreen     = Color(red: 0.20, green: 0.80, blue: 0.30)
    static let dangerRed   = Color(red: 0.90, green: 0.20, blue: 0.20)
    static let manaBlue    = Color(red: 0.30, green: 0.50, blue: 0.95)
    static let questPurple = Color(red: 0.60, green: 0.30, blue: 0.90)

    // 보더
    static let borderGold  = Color(red: 0.70, green: 0.50, blue: 0.15)
    static let borderDim   = Color(red: 0.35, green: 0.25, blue: 0.40)
}

// MARK: - RPG Card Modifier

struct RPGStatCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(RPGTheme.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(RPGTheme.borderGold, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
    }
}

struct RPGQuestCard: ViewModifier {
    var isAvailable: Bool = true

    func body(content: Content) -> some View {
        content
            .padding()
            .background(RPGTheme.bgElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isAvailable ? RPGTheme.goldDim : RPGTheme.borderDim, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(isAvailable ? 1.0 : 0.6)
    }
}

struct RPGGlowBorder: ViewModifier {
    var color: Color = RPGTheme.gold

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.4), lineWidth: 2)
                    .blur(radius: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.6), lineWidth: 1)
            )
    }
}

// MARK: - RPG Progress Bar Style

struct RPGProgressBar: View {
    var progress: Double
    var color: Color = RPGTheme.expBar
    var height: CGFloat = 12
    var showGlow: Bool = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // 배경
                Capsule()
                    .fill(Color.black.opacity(0.5))
                    .frame(height: height)
                    .overlay(
                        Capsule()
                            .stroke(RPGTheme.borderDim, lineWidth: 0.5)
                    )

                // 진행
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(height, geo.size.width * progress), height: height)
                    .shadow(color: showGlow ? color.opacity(0.5) : .clear, radius: 4)
            }
        }
        .frame(height: height)
    }
}

// MARK: - RPG Ornate Header

struct RPGOrnateHeader: View {
    var title: String
    var icon: String
    var color: Color = RPGTheme.gold

    var body: some View {
        HStack(spacing: 8) {
            Text("◆")
                .foregroundStyle(color.opacity(0.5))
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.custom("", size: 18).weight(.bold))
                .foregroundStyle(RPGTheme.textGold)
            Text("◆")
                .foregroundStyle(color.opacity(0.5))
        }
    }
}

// MARK: - View Extensions

extension View {
    func rpgStatCard() -> some View {
        modifier(RPGStatCard())
    }

    func rpgQuestCard(isAvailable: Bool = true) -> some View {
        modifier(RPGQuestCard(isAvailable: isAvailable))
    }

    func rpgGlowBorder(color: Color = RPGTheme.gold) -> some View {
        modifier(RPGGlowBorder(color: color))
    }
}

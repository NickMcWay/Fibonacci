import SwiftUI

struct ShopView: View {
    @AppStorage("SlideWords_Coins")          private var coins:          Int = 125
    @AppStorage("SlideWords_HintCharges")    private var hintCharges:    Int = 2
    @AppStorage("SlideWords_ShuffleCharges") private var shuffleCharges: Int = 1
    @AppStorage("SlideWords_BombCharges")    private var bombCharges:    Int = 1
    @AppStorage("SlideWords_WildCharges")    private var wildCharges:    Int = 1

    @Environment(\.dismiss) private var dismiss

    private let hintCost    = 25
    private let shuffleCost = 50
    private let wildCost    = 60
    private let bombCost    = 75

    private let uiTint = Color(red: 0.93, green: 0.88, blue: 0.99)
    private let uiInk  = Color(red: 0.24, green: 0.20, blue: 0.49)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.97, green: 0.95, blue: 1.0).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        coinBalanceCard
                        powerUpSection
                        coinPacksSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(uiInk)
                }
            }
        }
    }

    // MARK: - Coin Balance

    private var coinBalanceCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(Color(red: 1, green: 0.72, blue: 0.3))

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Coins")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(uiInk.opacity(0.65))
                Text("\(coins)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(uiInk)
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(uiTint)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.7), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Power-Ups

    private var powerUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Power-Ups")

            VStack(spacing: 10) {
                shopRow(
                    icon: "lightbulb.fill",
                    iconColor: Color(red: 1, green: 0.78, blue: 0.1),
                    title: "Hint",    detail: "Reveals a pending word match",
                    owned: hintCharges, cost: hintCost,
                    canAfford: coins >= hintCost
                ) { coins -= hintCost; hintCharges += 1 }

                shopRow(
                    icon: "shuffle",
                    iconColor: Color(red: 0.2, green: 0.6, blue: 1),
                    title: "Shuffle", detail: "Randomly rearranges all tiles",
                    owned: shuffleCharges, cost: shuffleCost,
                    canAfford: coins >= shuffleCost
                ) { coins -= shuffleCost; shuffleCharges += 1 }

                shopRow(
                    icon: "wand.and.stars",
                    iconColor: Color(red: 0.55, green: 0.25, blue: 0.95),
                    title: "Wild",    detail: "Converts any tile into a joker",
                    owned: wildCharges, cost: wildCost,
                    canAfford: coins >= wildCost
                ) { coins -= wildCost; wildCharges += 1 }

                shopRow(
                    icon: "burst.fill",
                    iconColor: Color(red: 1, green: 0.35, blue: 0.25),
                    title: "Bomb",    detail: "Clears a full row and column",
                    owned: bombCharges, cost: bombCost,
                    canAfford: coins >= bombCost
                ) { coins -= bombCost; bombCharges += 1 }
            }
        }
    }

    // MARK: - Coin Packs

    private var coinPacksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Coin Packs")

            HStack(spacing: 12) {
                coinPackCard(amount: 100, label: "Starter", color: Color(red: 0.85, green: 0.92, blue: 1))
                coinPackCard(amount: 300, label: "Builder", color: Color(red: 0.88, green: 1,    blue: 0.88))
                coinPackCard(amount: 750, label: "Master",  color: Color(red: 1,    green: 0.92, blue: 0.78))
            }

            Text("Coin packs are free — no purchase required.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func coinPackCard(amount: Int, label: String, color: Color) -> some View {
        Button { coins += amount } label: {
            VStack(spacing: 8) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(red: 0.85, green: 0.55, blue: 0.1))
                Text("+\(amount)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(uiInk)
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Text("FREE")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(Color(red: 0.25, green: 0.65, blue: 0.35)))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(color)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.7), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .foregroundColor(uiInk)
    }

    private func shopRow(
        icon: String, iconColor: Color,
        title: String, detail: String,
        owned: Int, cost: Int, canAfford: Bool,
        onBuy: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(iconColor.opacity(0.15)).frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(uiInk)
                    Text("×\(owned)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onBuy) {
                HStack(spacing: 4) {
                    Image(systemName: "bitcoinsign.circle.fill").font(.system(size: 12))
                    Text("\(cost)").font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(canAfford ? .white : .gray)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(
                    Capsule().fill(canAfford
                                   ? Color(red: 0.25, green: 0.55, blue: 1.0)
                                   : Color.gray.opacity(0.25))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAfford)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.75))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.6), lineWidth: 1))
        )
    }
}

#Preview("Shop") {
    ShopView()
}

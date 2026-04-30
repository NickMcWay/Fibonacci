// PopupViews.swift
// All Quibly modal pop-ups: GameOver, Pause, BuyCharge, DailyReward, Quests, Profile, Locked.
// Each comes in two forms:
//   - An inline view (used inside overlays in GameView / MenuView)
//   - A *Sheet wrapper (used as .sheet / .fullScreenCover)

import SwiftUI

// MARK: - Game Over Popup

struct GameOverPopup: View {
    let score: Int
    let words: Int
    let bestCombo: Int
    let onMenu: () -> Void
    let onPlayAgain: () -> Void

    @AppStorage("SlideWords_BestScore") private var bestScore: Int = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(spacing: 0) {
                // Floating trophy above card
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color(red: 1, green: 0.97, blue: 0.7), Color.qSun1],
                            center: .topLeading, startRadius: 0, endRadius: 40
                        ))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color(red: 0.71, green: 0.43, blue: 0).opacity(0.4), radius: 0, x: 0, y: 6)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color.qGoldDeep)
                }
                .floatingAnimation(delay: 0, duration: 2.4, distance: 5)
                .zIndex(1)
                .offset(y: 40)

                VStack(spacing: 16) {
                    Spacer().frame(height: 40)

                    Text(score > bestScore ? "New Best!" : "Game Over")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.qInk)
                    Text(score > bestScore
                        ? "You beat your record!"
                        : "Final score: \(score)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.qInkSoft)

                    // Stats
                    HStack(spacing: 0) {
                        statCell(label: "Score", value: "\(score)")
                        Divider().frame(height: 36).overlay(Color.qInk.opacity(0.15))
                        statCell(label: "Words", value: "\(words)")
                        Divider().frame(height: 36).overlay(Color.qInk.opacity(0.15))
                        statCell(label: "Best Combo", value: bestCombo > 0 ? "×\(bestCombo)" : "—")
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.65))
                    )

                    // Coin earned chip
                    HStack(spacing: 8) {
                        Circle()
                            .fill(RadialGradient(colors: [Color(red: 1, green: 0.96, blue: 0.7), Color(red: 0.94, green: 0.64, blue: 0.13)], center: .topLeading, startRadius: 0, endRadius: 8))
                            .frame(width: 16, height: 16)
                        Text("+85 earned")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.qGoldDeep)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(red: 1, green: 0.97, blue: 0.85), Color(red: 1, green: 0.89, blue: 0.60)],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .shadow(color: Color(red: 0.71, green: 0.43, blue: 0).opacity(0.3), radius: 0, x: 0, y: 2)
                    )

                    // Buttons
                    HStack(spacing: 8) {
                        Button(action: onMenu) {
                            Text("Menu")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.qInk)
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(PuffyButtonStyle(variant: .ghost))

                        Button(action: onPlayAgain) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.qGoldDeep)
                                Text("Play Again")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.qGoldDeep)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(PuffyButtonStyle(variant: .gold))
                    }
                }
                .padding(22)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(LinearGradient(
                            colors: [Color(red: 1, green: 0.97, blue: 0.91), Color(red: 1, green: 0.90, blue: 0.72)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.85), lineWidth: 1.5))
                        .shadow(color: Color.qInk.opacity(0.28), radius: 0, x: 0, y: 12)
                        .shadow(color: Color.qInk.opacity(0.35), radius: 30, x: 0, y: 20)
                )
            }
            .padding(.horizontal, 28)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
            .animation(.spring(response: 0.38, dampingFraction: 0.65), value: true)
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.qInk.opacity(0.60))
                .tracking(0.6)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.qInk)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pause Popup

struct PausePopup: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { onResume() }

            VStack(spacing: 16) {
                Text("Paused")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.qInk)
                Text("Take a breath. Take a sip. ☕")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.qInkSoft)

                VStack(spacing: 8) {
                    Button(action: onResume) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.qGoldDeep)
                            Text("Resume").font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(Color.qGoldDeep)
                        }
                    }
                    .buttonStyle(PuffyButtonStyle(variant: .gold))

                    Button(action: onRestart) {
                        HStack(spacing: 8) {
                            Image(systemName: "shuffle").font(.system(size: 14, weight: .bold)).foregroundStyle(Color.white)
                            Text("Restart").font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(Color.white)
                        }
                    }
                    .buttonStyle(PuffyButtonStyle(variant: .grape))

                    Button(action: onMenu) {
                        Text("Quit to Menu")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.qInk)
                    }
                    .buttonStyle(PuffyButtonStyle(variant: .ghost))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(LinearGradient(
                        colors: [Color(red: 1, green: 0.97, blue: 0.91), Color(red: 1, green: 0.84, blue: 0.92)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.white.opacity(0.85), lineWidth: 1.5))
                    .shadow(color: Color.qInk.opacity(0.22), radius: 0, x: 0, y: 10)
                    .shadow(color: Color.qInk.opacity(0.35), radius: 28, x: 0, y: 18)
            )
            .padding(.horizontal, 36)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
            .animation(.spring(response: 0.38, dampingFraction: 0.65), value: true)
        }
    }
}

// MARK: - Buy Charge Popup Sheet

struct BuyChargePopupSheet: View {
    let powerUpName: String
    let icon: String
    let iconGradient: [Color]
    let singleCost: Int
    let tripleCost: Int
    let coins: Int
    let onBuy: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 14)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: iconGradient, startPoint: .top, endPoint: .bottom))
                        .shadow(color: iconGradient.last!.opacity(0.4), radius: 0, x: 0, y: 3)
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Out of \(powerUpName)s!")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.qInk)
                    Text("Buy more to keep going.")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.qInkSoft)
                }
                Spacer()
            }
            .padding(.horizontal, 22)

            HStack(spacing: 10) {
                buyCard(qty: 1, cost: singleCost, popular: false)
                buyCard(qty: 3, cost: tripleCost, popular: true)
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)

            HStack(spacing: 10) {
                Circle()
                    .fill(RadialGradient(colors: [Color(red: 1, green: 0.96, blue: 0.7), Color(red: 0.94, green: 0.64, blue: 0.13)], center: .topLeading, startRadius: 0, endRadius: 10))
                    .frame(width: 22, height: 22)
                Text("You have \(coins) coins")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qInk)
                Spacer()
                Button { dismiss() } label: {
                    Text("Get more →")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.qInk.opacity(0.70))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.qInk.opacity(0.06))
            )
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
    }

    private func buyCard(qty: Int, cost: Int, popular: Bool) -> some View {
        let canAfford = coins >= cost
        return Button {
            guard canAfford else { return }
            onBuy(qty)
            dismiss()
        } label: {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(popular
                        ? LinearGradient(colors: [Color(red: 1, green: 0.96, blue: 0.83), Color.qSun1], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.qInk.opacity(0.06), Color.qInk.opacity(0.04)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(popular ? Color.qSun1.opacity(0.5) : Color.qInk.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: popular ? Color(red: 0.71, green: 0.43, blue: 0).opacity(0.3) : Color.clear, radius: 0, x: 0, y: 3)

                VStack(spacing: 6) {
                    Spacer().frame(height: popular ? 12 : 4)
                    Text("×\(qty)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.qInk)
                    if popular {
                        Text("13% off")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.qMint2)
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(RadialGradient(colors: [Color(red: 1, green: 0.96, blue: 0.7), Color(red: 0.94, green: 0.64, blue: 0.13)], center: .topLeading, startRadius: 0, endRadius: 7))
                            .frame(width: 14, height: 14)
                        Text("\(cost)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.qGoldDeep)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: canAfford
                                    ? [Color(red: 1, green: 0.97, blue: 0.85), Color(red: 1, green: 0.89, blue: 0.60)]
                                    : [Color.gray.opacity(0.2), Color.gray.opacity(0.15)],
                                startPoint: .top, endPoint: .bottom
                            ))
                    )
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }

                if popular {
                    Text("BEST VALUE")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Capsule().fill(Color.qBubble2))
                        .offset(y: -8)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!canAfford)
        .opacity(canAfford ? 1 : 0.55)
    }
}

// MARK: - Daily Reward Sheet

struct DailyRewardPopupSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct Day { let n: Int; let reward: String; let claimed: Bool; let today: Bool; let big: Bool }
    private let days: [Day] = [
        .init(n: 1, reward: "+25",  claimed: true,  today: false, big: false),
        .init(n: 2, reward: "+50",  claimed: true,  today: false, big: false),
        .init(n: 3, reward: "💡",   claimed: false, today: true,  big: false),
        .init(n: 4, reward: "+100", claimed: false, today: false, big: false),
        .init(n: 5, reward: "🔀",   claimed: false, today: false, big: false),
        .init(n: 6, reward: "+200", claimed: false, today: false, big: false),
        .init(n: 7, reward: "🎁",   claimed: false, today: false, big: true),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color.qBubble1, location: 0),
                    .init(color: Color.qPeach1, location: 0.6),
                    .init(color: Color.qSun1, location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                Text("Daily Reward 🎁")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.qInk)
                    .shadow(color: Color.white.opacity(0.4), radius: 0, x: 0, y: 1)

                Text("Day 3 · keep your streak alive!")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.qInkSoft)

                // 7-day grid: row1 = days 1-4, row2 = days 5-6, row3 = day 7 full-width
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ForEach(days.prefix(4), id: \.n) { dayBox($0) }
                    }
                    HStack(spacing: 8) {
                        ForEach(days.dropFirst(4).prefix(2), id: \.n) { dayBox($0) }
                        Spacer()
                        Spacer()
                    }
                    dayBox(days[6])
                }
                .padding(.horizontal, 4)

                Button { dismiss() } label: {
                    HStack(spacing: 8) {
                        Text("Claim Today")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.qGoldDeep)
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.qGoldDeep)
                    }
                }
                .buttonStyle(PuffyButtonStyle(variant: .gold))
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 22)
        }
    }

    private func dayBox(_ day: Day) -> some View {
        VStack(spacing: 4) {
            Text("Day \(day.n)")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(day.today ? Color.white.opacity(0.95) : Color.qInk.opacity(0.60))
                .tracking(0.3)
            Text(day.reward)
                .font(.system(size: day.big ? 22 : 16, weight: .semibold, design: .rounded))
                .foregroundStyle(day.today ? Color.white : Color.qInk)
                .shadow(color: day.today ? Color(red: 0.71, green: 0.35, blue: 0).opacity(0.4) : Color.clear, radius: 0, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(day.today
                    ? LinearGradient(colors: [Color.qSun1, Color.qSun2], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [Color.white.opacity(day.claimed ? 0.5 : 0.7), Color.white.opacity(day.claimed ? 0.4 : 0.6)], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(day.today ? Color.white.opacity(0.5) : Color.qInk.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: day.today ? Color.qSun2.opacity(0.4) : Color.clear, radius: 0, x: 0, y: 3)
        )
        .overlay(alignment: .topTrailing) {
            if day.claimed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.qMint2)
                    .offset(x: 4, y: -4)
            }
        }
        .opacity(day.claimed && !day.today ? 0.55 : 1.0)
        .wiggle(active: day.today)
    }
}

// MARK: - Quests Sheet

struct QuestsPopupSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct Quest { let name: String; let icon: String; let color: [Color]; let progress: Int; let total: Int; let reward: Int }
    private let quests: [Quest] = [
        .init(name: "Score 500 in one game",    icon: "trophy.fill",  color: [Color.qSun1, Color.qSun2],     progress: 320, total: 500, reward: 50),
        .init(name: "Spell 5 words ≥ 5 letters", icon: "textformat",   color: [Color.qGrape1, Color.qGrape2], progress: 3,   total: 5,   reward: 30),
        .init(name: "Trigger a ×3 combo",        icon: "flame.fill",   color: [Color.qCoral1, Color.qCoral2], progress: 0,   total: 1,   reward: 75),
    ]

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            HStack {
                Text("Daily Quests")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qInk)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.qInk.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)

            VStack(spacing: 10) {
                ForEach(quests.indices, id: \.self) { i in
                    questRow(quests[i])
                }
            }
            .padding(.horizontal, 18)

            // Weekly chest
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.qSun1)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly Chest")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Complete 21/30 quests to unlock")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.9))
                }
                Spacer()
                Text("21/30")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [Color.qGrape1, Color.qBubble2], startPoint: .leading, endPoint: .trailing))
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
    }

    private func questRow(_ quest: Quest) -> some View {
        let pct = min(1.0, Double(quest.progress) / Double(quest.total))
        let done = quest.progress >= quest.total

        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: quest.color, startPoint: .top, endPoint: .bottom))
                    .shadow(color: quest.color.last!.opacity(0.3), radius: 0, x: 0, y: 2)
                Image(systemName: quest.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 5) {
                Text(quest.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qInk)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(Color.qInk.opacity(0.10))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 999)
                        .fill(LinearGradient(colors: [Color.qMint1, Color.qMint2], startPoint: .leading, endPoint: .trailing))
                        .frame(width: nil, height: 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .mask(
                            GeometryReader { geo in
                                HStack(spacing: 0) {
                                    Color.black.frame(width: geo.size.width * pct)
                                    Color.clear
                                }
                            }
                        )
                }
                Text("\(quest.progress)/\(quest.total)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.qInkSoft)
            }

            HStack(spacing: 4) {
                if done {
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy))
                } else {
                    Circle()
                        .fill(RadialGradient(colors: [Color(red: 1, green: 0.96, blue: 0.7), Color(red: 0.94, green: 0.64, blue: 0.13)], center: .topLeading, startRadius: 0, endRadius: 6))
                        .frame(width: 12, height: 12)
                }
                Text(done ? "Claim" : "\(quest.reward)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(done ? Color.white : Color.qGoldDeep)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(done
                        ? LinearGradient(colors: [Color.qMint1, Color.qMint2], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color(red: 1, green: 0.97, blue: 0.85), Color(red: 1, green: 0.89, blue: 0.60)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 0, x: 0, y: 2)
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.qInk.opacity(0.05))
        )
    }
}

// MARK: - Profile Sheet

struct ProfilePopupSheet: View {
    @AppStorage("SlideWords_BestScore") private var bestScore: Int = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.qBubble1, Color.qGrape1], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Color.qInk.opacity(0.35), radius: 0, x: 0, y: 4)
                Text("R")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color.qInk.opacity(0.4), radius: 0, x: 0, y: 2)
            }
            .frame(width: 80, height: 80)

            VStack(spacing: 4) {
                Text("Riley")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qInk)
                Text("Level 12 · 7-day streak 🔥")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.qInkSoft)
            }

            // XP Bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(Color.qInk.opacity(0.10))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 999)
                    .fill(LinearGradient(colors: [Color.qSun1, Color.qBubble2, Color.qGrape1], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .mask(
                        GeometryReader { geo in
                            HStack(spacing: 0) {
                                Color.black.frame(width: geo.size.width * 0.62)
                                Color.clear
                            }
                        }
                    )
            }
            .padding(.horizontal, 22)

            // Stats grid
            HStack(spacing: 0) {
                profileStat(label: "Best", value: "\(bestScore)")
                Divider().frame(height: 36).overlay(Color.qInk.opacity(0.15))
                profileStat(label: "Games", value: "48")
                Divider().frame(height: 36).overlay(Color.qInk.opacity(0.15))
                profileStat(label: "Longest", value: "QUIBLY")
            }
            .padding(.horizontal, 22)

            Button { dismiss() } label: {
                Text("Close")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qInk)
            }
            .buttonStyle(PuffyButtonStyle(variant: .ghost))
            .padding(.horizontal, 22)
            .padding(.bottom, 24)
        }
    }

    private func profileStat(label: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.qInk.opacity(0.60))
                .tracking(0.6)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.qInk)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Locked Feature Sheet

struct LockedPopupSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.qGrape1.opacity(0.8), Color.qGrape2], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Color.qGrape2.opacity(0.4), radius: 0, x: 0, y: 3)
                Image(systemName: "lock.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)

            VStack(spacing: 4) {
                Text("Coming soon")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qInk)
                Text("Friends & duels unlock at Level 15.")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.qInkSoft)
                    .multilineTextAlignment(.center)
            }

            Button { dismiss() } label: {
                Text("Got it")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qGoldDeep)
            }
            .buttonStyle(PuffyButtonStyle(variant: .gold))
            .padding(.horizontal, 36)
            .padding(.bottom, 24)
        }
    }
}

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
    let currentStreak: Int
    let streakJustExtended: Bool
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

                    // Streak card
                    streakCard

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

    private var streakCard: some View {
        let isMilestone = streakJustExtended && [3, 7, 14, 30, 100].contains(currentStreak)
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: streakJustExtended
                            ? [Color.qSun1, Color.qSun2]
                            : [Color(red: 1, green: 0.85, blue: 0.77), Color(red: 1, green: 0.72, blue: 0.53)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .shadow(color: Color.qSun2.opacity(streakJustExtended ? 0.45 : 0.2), radius: 0, x: 0, y: 3)
                Image(systemName: "flame.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(streakJustExtended ? Color.qGoldDeep : Color.white.opacity(0.75))
            }
            .frame(width: 48, height: 48)
            .wiggle(active: isMilestone)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("\(currentStreak) Day Streak")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.qInk)
                    if streakJustExtended {
                        Text("+1")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(
                                Capsule().fill(Color.qSun2)
                                    .shadow(color: Color(red: 0.71, green: 0.27, blue: 0).opacity(0.4), radius: 0, x: 0, y: 2)
                            )
                    }
                }
                Group {
                    if let label = milestoneLabel(currentStreak), streakJustExtended {
                        Text(label).foregroundStyle(Color.qMint2)
                    } else if streakJustExtended {
                        Text("Keep the flame alive!").foregroundStyle(Color.qInkSoft)
                    } else {
                        Text("Play tomorrow to keep your streak").foregroundStyle(Color.qInkSoft)
                    }
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: streakJustExtended
                        ? [Color(red: 1, green: 0.97, blue: 0.85), Color(red: 1, green: 0.89, blue: 0.60)]
                        : [Color.white.opacity(0.60), Color.white.opacity(0.45)],
                    startPoint: .top, endPoint: .bottom
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(streakJustExtended ? Color.qSun1.opacity(0.5) : Color.qInk.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func milestoneLabel(_ streak: Int) -> String? {
        switch streak {
        case 3:   return "Hat-trick! 🎯"
        case 7:   return "Week Warrior! ⚡"
        case 14:  return "Fortnight Streak! 💪"
        case 30:  return "Monthly Master! 👑"
        case 100: return "Centurion! 🏆"
        default:  return nil
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

    private struct Day { let n: Int; let reward: String; let icon: String?; let claimed: Bool; let today: Bool }
    private let days: [Day] = [
        .init(n: 1, reward: "+25",  icon: nil,             claimed: true,  today: false),
        .init(n: 2, reward: "+50",  icon: nil,             claimed: true,  today: false),
        .init(n: 3, reward: "+75",  icon: "lightbulb.fill", claimed: false, today: true),
        .init(n: 4, reward: "+100", icon: nil,             claimed: false, today: false),
        .init(n: 5, reward: "Shuffle", icon: "shuffle",    claimed: false, today: false),
        .init(n: 6, reward: "+200", icon: nil,             claimed: false, today: false),
        .init(n: 7, reward: "Chest", icon: "gift.fill",    claimed: false, today: false),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color.qBubble2.opacity(0.85), location: 0),
                    .init(color: Color.qBubble1.opacity(0.8),  location: 0.4),
                    .init(color: Color.qSun1.opacity(0.75),    location: 1),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Handle
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 36, height: 4)
                        .padding(.top, 12)
                        .padding(.bottom, 24)

                    // Hero gift icon
                    ZStack {
                        Circle()
                            .fill(RadialGradient(
                                colors: [Color(red: 1, green: 0.97, blue: 0.7), Color.qSun1],
                                center: .topLeading, startRadius: 0, endRadius: 50
                            ))
                            .shadow(color: Color.qSun2.opacity(0.5), radius: 0, x: 0, y: 6)
                            .shadow(color: Color.qSun2.opacity(0.3), radius: 20, x: 0, y: 10)
                        Image(systemName: "gift.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Color.qGoldDeep)
                    }
                    .frame(width: 96, height: 96)
                    .floatingAnimation(delay: 0, duration: 2.8, distance: 5)
                    .padding(.bottom, 18)

                    // Title
                    VStack(spacing: 6) {
                        Text("Daily Reward")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Color.qInk.opacity(0.25), radius: 0, x: 0, y: 2)
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.qSun2)
                            Text("Day 3 · Keep your streak alive!")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.88))
                        }
                    }
                    .padding(.bottom, 28)

                    // 7-day grid — 4 across on top, then 3 across
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            ForEach(days.prefix(4), id: \.n) { dayBox($0) }
                        }
                        HStack(spacing: 10) {
                            ForEach(Array(days.dropFirst(4)), id: \.n) { dayBox($0) }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)

                    // Today's reward callout
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.qSun1, Color.qSun2], startPoint: .top, endPoint: .bottom))
                                .shadow(color: Color.qSun2.opacity(0.4), radius: 0, x: 0, y: 3)
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.qGoldDeep)
                        }
                        .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Today's Reward")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .tracking(0.3)
                            Text("+75 coins + 1 Hint power-up")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.85))
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.2))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.4), lineWidth: 1))
                    )
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)

                    // Claim button
                    Button { dismiss() } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.qGoldDeep)
                            Text("Claim Today's Reward")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.qGoldDeep)
                        }
                    }
                    .buttonStyle(PuffyButtonStyle(variant: .gold))
                    .padding(.horizontal, 22)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private func dayBox(_ day: Day) -> some View {
        VStack(spacing: 6) {
            Text("Day \(day.n)")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(day.today ? Color.white : Color.qInk.opacity(0.60))
                .tracking(0.3)

            if let icon = day.icon {
                Image(systemName: icon)
                    .font(.system(size: day.n == 7 ? 24 : 18, weight: .bold))
                    .foregroundStyle(day.today ? Color.white : Color.qInk)
                    .shadow(color: day.today ? Color.qGoldDeep.opacity(0.4) : Color.clear, radius: 0, x: 0, y: 1)
            } else {
                Text(day.reward)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(day.today ? Color.white : Color.qInk)
                    .shadow(color: day.today ? Color.qGoldDeep.opacity(0.4) : Color.clear, radius: 0, x: 0, y: 1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(day.today
                    ? LinearGradient(colors: [Color.qSun1, Color.qSun2], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(
                        colors: [Color.white.opacity(day.claimed ? 0.45 : 0.65), Color.white.opacity(day.claimed ? 0.35 : 0.55)],
                        startPoint: .top, endPoint: .bottom
                      )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(day.today ? Color.white.opacity(0.55) : Color.qInk.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: day.today ? Color.qSun2.opacity(0.45) : Color.clear, radius: 0, x: 0, y: 3)
        )
        .overlay(alignment: .topTrailing) {
            if day.claimed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.qMint2)
                    .offset(x: 5, y: -5)
            }
        }
        .opacity(day.claimed && !day.today ? 0.5 : 1.0)
        .wiggle(active: day.today)
    }
}

// MARK: - Quests Sheet

struct QuestsPopupSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct Quest { let name: String; let icon: String; let color: [Color]; let progress: Int; let total: Int; let reward: Int }
    private let quests: [Quest] = [
        .init(name: "Score 500 in one game",     icon: "trophy.fill",  color: [Color.qSun1, Color.qSun2],     progress: 320, total: 500, reward: 50),
        .init(name: "Spell 5 words ≥ 5 letters", icon: "textformat",   color: [Color.qGrape1, Color.qGrape2], progress: 3,   total: 5,   reward: 30),
        .init(name: "Trigger a ×3 combo",        icon: "flame.fill",   color: [Color.qCoral1, Color.qCoral2], progress: 0,   total: 1,   reward: 75),
    ]

    private var completedCount: Int { quests.filter { $0.progress >= $0.total }.count }

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.40, green: 0.82, blue: 0.62), location: 0),
                    .init(color: Color.qBubble1.opacity(0.85), location: 0.5),
                    .init(color: Color.qSun1.opacity(0.7), location: 1),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Handle
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 36, height: 4)
                        .padding(.top, 12)
                        .padding(.bottom, 22)

                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Quests")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: Color.qInk.opacity(0.25), radius: 0, x: 0, y: 2)
                            Text("Resets in 6h 42m")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.white.opacity(0.65))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)

                    // Progress summary card
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(completedCount) of \(quests.count) done")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Today's challenges")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            ForEach(quests.indices, id: \.self) { i in
                                let done = quests[i].progress >= quests[i].total
                                ZStack {
                                    Circle()
                                        .fill(done
                                            ? LinearGradient(colors: [Color.qMint1, Color.qMint2], startPoint: .top, endPoint: .bottom)
                                            : LinearGradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                                        )
                                        .shadow(color: done ? Color.qMint2.opacity(0.4) : Color.clear, radius: 0, x: 0, y: 2)
                                    Image(systemName: done ? "checkmark" : "\(i + 1)")
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 28, height: 28)
                            }
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.2))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.4), lineWidth: 1))
                    )
                    .padding(.horizontal, 22)
                    .padding(.bottom, 20)

                    // Quest cards
                    VStack(spacing: 14) {
                        ForEach(quests.indices, id: \.self) { i in
                            questCard(quests[i])
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 22)

                    // Weekly chest
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WEEKLY CHEST")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .tracking(0.8)
                            .padding(.horizontal, 2)

                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(LinearGradient(colors: [Color.qGrape1, Color.qGrape2], startPoint: .top, endPoint: .bottom))
                                    .shadow(color: Color.qGrape2.opacity(0.45), radius: 0, x: 0, y: 4)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundStyle(Color.qSun1)
                                    .shadow(color: Color.qSun2.opacity(0.5), radius: 0, x: 0, y: 2)
                            }
                            .frame(width: 68, height: 68)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Complete 30 quests")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("21 of 30 weekly quests done")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.75))
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 999)
                                        .fill(Color.white.opacity(0.25))
                                        .frame(height: 8)
                                    GeometryReader { geo in
                                        RoundedRectangle(cornerRadius: 999)
                                            .fill(LinearGradient(colors: [Color.qSun1, Color.qSun2], startPoint: .leading, endPoint: .trailing))
                                            .frame(width: geo.size.width * (21.0 / 30.0), height: 8)
                                    }
                                    .frame(height: 8)
                                }
                            }

                            Text("21/30")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.18))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.35), lineWidth: 1))
                    )
                    .padding(.horizontal, 22)
                    .padding(.bottom, 36)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private func questCard(_ quest: Quest) -> some View {
        let pct = min(1.0, Double(quest.progress) / Double(quest.total))
        let done = quest.progress >= quest.total

        return VStack(spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: quest.color, startPoint: .top, endPoint: .bottom))
                        .shadow(color: quest.color.last!.opacity(0.4), radius: 0, x: 0, y: 3)
                    Image(systemName: quest.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(quest.progress) / \(quest.total)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.75))
                }

                Spacer()

                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.qMint1)
                        .shadow(color: Color.qMint2.opacity(0.4), radius: 0, x: 0, y: 2)
                } else {
                    VStack(spacing: 2) {
                        Circle()
                            .fill(RadialGradient(colors: [Color(red: 1, green: 0.96, blue: 0.7), Color(red: 0.94, green: 0.64, blue: 0.13)], center: .topLeading, startRadius: 0, endRadius: 8))
                            .frame(width: 18, height: 18)
                        Text("+\(quest.reward)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.qSun1)
                    }
                }
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(Color.white.opacity(0.25))
                    .frame(height: 10)
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 999)
                        .fill(done
                            ? LinearGradient(colors: [Color.qMint1, Color.qMint2], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.65)], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: max(geo.size.width * pct, pct > 0 ? 10 : 0), height: 10)
                }
                .frame(height: 10)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.35), lineWidth: 1))
        )
    }
}

// MARK: - Profile Sheet

struct ProfilePopupSheet: View {
    @AppStorage("SlideWords_BestScore") private var bestScore: Int = 0
    @AppStorage("SlideWords_TotalXP")   private var totalXP: Int  = 0
    @AppStorage("SlideWords_Coins")     private var coins: Int     = 125
    @AppStorage("SlideWords_Streak")    private var streak: Int    = 7
    @Environment(\.dismiss) private var dismiss

    private let xpPerLevel = 500
    private var level: Int  { totalXP / xpPerLevel + 1 }
    private var xpInLevel: Int { totalXP % xpPerLevel }
    private var progress: Double { Double(xpInLevel) / Double(xpPerLevel) }

    private struct Badge { let icon: String; let name: String; let unlocked: Bool; let color: [Color] }
    private let badges: [Badge] = [
        .init(icon: "star.fill",     name: "First Word",  unlocked: true,  color: [Color.qSun1, Color.qSun2]),
        .init(icon: "flame.fill",    name: "On Fire",     unlocked: true,  color: [Color.qCoral1, Color.qCoral2]),
        .init(icon: "trophy.fill",   name: "High Score",  unlocked: true,  color: [Color.qGrape1, Color.qGrape2]),
        .init(icon: "bolt.fill",     name: "Blitz King",  unlocked: false, color: [Color.qSky1, Color.qSky2]),
        .init(icon: "crown.fill",    name: "Word Master", unlocked: false, color: [Color.qMint1, Color.qMint2]),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color.qGrape2.opacity(0.9), location: 0),
                    .init(color: Color.qBubble1.opacity(0.75), location: 0.45),
                    .init(color: Color.qSun1.opacity(0.6), location: 1),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Handle
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 36, height: 4)
                        .padding(.top, 12)
                        .padding(.bottom, 28)

                    // Hero — avatar + name + level badge
                    VStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.qBubble1, Color.qGrape1], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: Color.qInk.opacity(0.35), radius: 0, x: 0, y: 6)
                                .shadow(color: Color.qGrape2.opacity(0.45), radius: 24, x: 0, y: 12)
                            Text("R")
                                .font(.system(size: 54, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: Color.qInk.opacity(0.4), radius: 0, x: 0, y: 2)
                        }
                        .frame(width: 114, height: 114)
                        .floatingAnimation(delay: 0, duration: 3.2, distance: 5)

                        VStack(spacing: 6) {
                            Text("Riley")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: Color.qInk.opacity(0.35), radius: 0, x: 0, y: 2)
                            Text("⚡  LEVEL \(level)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(Color.white.opacity(0.95))
                                .padding(.horizontal, 14).padding(.vertical, 5)
                                .background(Capsule().fill(Color.white.opacity(0.22)))
                        }
                    }
                    .padding(.bottom, 28)

                    // XP progress card
                    VStack(spacing: 10) {
                        HStack {
                            Text("PROGRESS TO LEVEL \(level + 1)")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .tracking(0.8)
                            Spacer()
                            Text("\(xpInLevel) / \(xpPerLevel) XP")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.85))
                        }
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 999)
                                .fill(Color.white.opacity(0.25))
                                .frame(height: 14)
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(LinearGradient(colors: [Color.qSun1, Color.qBubble2, Color.qGrape1], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: max(geo.size.width * progress, progress > 0 ? 14 : 0), height: 14)
                                    .shadow(color: Color.qBubble2.opacity(0.5), radius: 4, x: 0, y: 0)
                            }
                            .frame(height: 14)
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.18))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.35), lineWidth: 1))
                    )
                    .padding(.horizontal, 22)
                    .padding(.bottom, 18)

                    // Stats grid 2 × 3
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        profileStatCard(icon: "trophy.fill",        iconColor: Color.qSun2,    label: "Best",    value: "\(bestScore)")
                        profileStatCard(icon: "flame.fill",         iconColor: Color.qCoral1,  label: "Streak",  value: "\(streak)d")
                        profileStatCard(icon: "circle.fill",        iconColor: Color.qSun1,    label: "Coins",   value: "\(coins)")
                        profileStatCard(icon: "gamecontroller.fill", iconColor: Color.qGrape1, label: "Games",   value: "48")
                        profileStatCard(icon: "text.word.spacing",  iconColor: Color.qMint2,   label: "Words",   value: "324")
                        profileStatCard(icon: "textformat.size",    iconColor: Color.qBubble2, label: "Longest", value: "QUIBLY")
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 20)

                    // Achievements
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("ACHIEVEMENTS")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .tracking(0.8)
                            Spacer()
                            Text("3 / 5 unlocked")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.65))
                        }
                        HStack(spacing: 0) {
                            ForEach(badges.indices, id: \.self) { i in
                                badgeCell(badges[i])
                            }
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.18))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.35), lineWidth: 1))
                    )
                    .padding(.horizontal, 22)
                    .padding(.bottom, 28)

                    Button { dismiss() } label: {
                        Text("Close Profile")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.qInk)
                    }
                    .buttonStyle(PuffyButtonStyle(variant: .ghost))
                    .padding(.horizontal, 44)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private func profileStatCard(icon: String, iconColor: Color, label: String, value: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(iconColor)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.72))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.32), lineWidth: 1))
        )
    }

    private func badgeCell(_ badge: Badge) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(badge.unlocked
                        ? LinearGradient(colors: badge.color, startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: badge.unlocked ? badge.color.last!.opacity(0.45) : Color.clear, radius: 0, x: 0, y: 3)
                Image(systemName: badge.unlocked ? badge.icon : "lock.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(badge.unlocked ? .white : Color.white.opacity(0.35))
            }
            .frame(width: 48, height: 48)
            Text(badge.name)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(badge.unlocked ? Color.white.opacity(0.9) : Color.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
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

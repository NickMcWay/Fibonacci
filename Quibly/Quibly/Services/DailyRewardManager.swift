// DailyRewardManager.swift
// Tracks 7-day login reward streaks and applies rewards to UserDefaults.

import Foundation

final class DailyRewardManager {
    static let shared = DailyRewardManager()
    private init() {}

    private let streakKey      = "DailyReward_Streak"
    private let lastClaimedKey = "DailyReward_LastClaimed"

    var streak: Int {
        get { UserDefaults.standard.integer(forKey: streakKey) }
        set { UserDefaults.standard.set(newValue, forKey: streakKey) }
    }

    var lastClaimedDate: Date? {
        get { UserDefaults.standard.object(forKey: lastClaimedKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastClaimedKey) }
    }

    var hasClaimedToday: Bool {
        guard let last = lastClaimedDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private var isStreakAlive: Bool {
        guard let last = lastClaimedDate else { return false }
        return Calendar.current.isDateInToday(last) ||
               Calendar.current.isDateInYesterday(last)
    }

    // Which day (1–7) in the cycle is highlighted as "today".
    var currentDayInCycle: Int {
        if hasClaimedToday  { return ((streak - 1) % 7) + 1 }
        if isStreakAlive     { return (streak % 7) + 1 }
        return 1
    }

    func isClaimed(dayNumber: Int) -> Bool {
        if hasClaimedToday { return dayNumber <= currentDayInCycle }
        return dayNumber < currentDayInCycle
    }

    // MARK: - Reward definitions (0-indexed, matching dayNumber 1-7)

    struct DayConfig {
        let displayText: String
        let icon: String?
    }

    struct Reward {
        let coins: Int
        let hintCharges: Int
        let shuffleCharges: Int
        let bombCharges: Int
        let wildCharges: Int
    }

    let dayConfigs: [DayConfig] = [
        .init(displayText: "+25",     icon: nil),
        .init(displayText: "+50",     icon: nil),
        .init(displayText: "+75",     icon: "lightbulb.fill"),
        .init(displayText: "+100",    icon: nil),
        .init(displayText: "Shuffle", icon: "shuffle"),
        .init(displayText: "+200",    icon: nil),
        .init(displayText: "Chest",   icon: "gift.fill"),
    ]

    private let rewards: [Reward] = [
        .init(coins: 25,  hintCharges: 0, shuffleCharges: 0, bombCharges: 0, wildCharges: 0),
        .init(coins: 50,  hintCharges: 0, shuffleCharges: 0, bombCharges: 0, wildCharges: 0),
        .init(coins: 75,  hintCharges: 1, shuffleCharges: 0, bombCharges: 0, wildCharges: 0),
        .init(coins: 100, hintCharges: 0, shuffleCharges: 0, bombCharges: 0, wildCharges: 0),
        .init(coins: 50,  hintCharges: 0, shuffleCharges: 1, bombCharges: 0, wildCharges: 0),
        .init(coins: 200, hintCharges: 0, shuffleCharges: 0, bombCharges: 0, wildCharges: 0),
        .init(coins: 150, hintCharges: 1, shuffleCharges: 1, bombCharges: 1, wildCharges: 1),
    ]

    var todayRewardIndex: Int {
        if hasClaimedToday  { return (streak - 1) % 7 }
        if isStreakAlive     { return streak % 7 }
        return 0
    }

    var todayReward: Reward { rewards[todayRewardIndex] }

    func todayRewardDescription() -> String {
        let r = todayReward
        let cfg = dayConfigs[todayRewardIndex]
        if cfg.icon == "gift.fill" {
            return "+\(r.coins) coins + Hint + Shuffle + Bomb + Joker"
        }
        var parts: [String] = []
        if r.coins > 0          { parts.append("+\(r.coins) coins") }
        if r.hintCharges > 0    { parts.append("\(r.hintCharges > 1 ? "\(r.hintCharges)×" : "")Hint power-up") }
        if r.shuffleCharges > 0 { parts.append("Shuffle") }
        if r.bombCharges > 0    { parts.append("Bomb") }
        if r.wildCharges > 0    { parts.append("Joker") }
        return parts.joined(separator: " + ")
    }

    @discardableResult
    func claimTodayReward() -> Reward? {
        guard !hasClaimedToday else { return nil }
        if !isStreakAlive { streak = 0 }

        let rewardIndex = streak % 7
        let reward = rewards[rewardIndex]
        let d = UserDefaults.standard

        d.set((d.object(forKey: "SlideWords_Coins")          as? Int ?? 125) + reward.coins,          forKey: "SlideWords_Coins")
        if reward.hintCharges > 0    { d.set((d.object(forKey: "SlideWords_HintCharges")    as? Int ?? 2) + reward.hintCharges,    forKey: "SlideWords_HintCharges") }
        if reward.shuffleCharges > 0 { d.set((d.object(forKey: "SlideWords_ShuffleCharges") as? Int ?? 1) + reward.shuffleCharges, forKey: "SlideWords_ShuffleCharges") }
        if reward.bombCharges > 0    { d.set((d.object(forKey: "SlideWords_BombCharges")    as? Int ?? 1) + reward.bombCharges,    forKey: "SlideWords_BombCharges") }
        if reward.wildCharges > 0    { d.set((d.object(forKey: "SlideWords_WildCharges")    as? Int ?? 1) + reward.wildCharges,    forKey: "SlideWords_WildCharges") }

        streak += 1
        lastClaimedDate = Date()
        return reward
    }
}

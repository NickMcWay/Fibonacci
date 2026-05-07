// QuestManager.swift
// Tracks daily quest progress and weekly completion count.
// All data resets at midnight; weekly count resets on Monday.

import Foundation

final class QuestManager {
    static let shared = QuestManager()
    private init() {}

    // MARK: - UserDefaults Keys (also used as @AppStorage keys in views)
    static let questDayKey          = "Quest_Day"
    static let scoreGoalKey         = "Quest_DailyBestScore"
    static let longWordsKey         = "Quest_DailyLongWords"
    static let gamesPlayedKey       = "Quest_DailyGamesPlayed"
    static let weekStartKey         = "Quest_WeekStart"
    static let weekCompletionsKey   = "Quest_WeeklyCompletions"

    // MARK: - Quest Targets
    static let scoreTarget     = 500
    static let longWordsTarget = 5
    static let gamesTarget     = 3
    static let weeklyTarget    = 21   // 3 quests × 7 days

    // MARK: - Internal

    private var todayString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    private var currentWeekStartString: String {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        guard let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start else { return todayString }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: start)
    }

    func checkAndResetIfNeeded() {
        let defaults = UserDefaults.standard
        let today = todayString

        if (defaults.string(forKey: Self.questDayKey) ?? "") != today {
            defaults.set(today, forKey: Self.questDayKey)
            defaults.set(0, forKey: Self.scoreGoalKey)
            defaults.set(0, forKey: Self.longWordsKey)
            defaults.set(0, forKey: Self.gamesPlayedKey)
        }

        let weekStart = currentWeekStartString
        if (defaults.string(forKey: Self.weekStartKey) ?? "") != weekStart {
            defaults.set(weekStart, forKey: Self.weekStartKey)
            defaults.set(0, forKey: Self.weekCompletionsKey)
        }
    }

    // MARK: - Time Until Reset

    var timeUntilResetString: String {
        let now = Date()
        guard let midnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else { return "" }
        let total = Int(midnight.timeIntervalSince(now))
        let h = total / 3600
        let m = (total % 3600) / 60
        return "\(h)h \(m)m"
    }

    // MARK: - Record Events

    func recordScore(_ score: Int) {
        checkAndResetIfNeeded()
        let defaults = UserDefaults.standard
        let current = defaults.integer(forKey: Self.scoreGoalKey)
        guard score > current else { return }
        let wasComplete = current >= Self.scoreTarget
        defaults.set(score, forKey: Self.scoreGoalKey)
        if !wasComplete && score >= Self.scoreTarget { addWeeklyCompletion() }
    }

    func recordLongWord() {
        checkAndResetIfNeeded()
        let defaults = UserDefaults.standard
        let current = defaults.integer(forKey: Self.longWordsKey)
        let wasComplete = current >= Self.longWordsTarget
        let newValue = current + 1
        defaults.set(newValue, forKey: Self.longWordsKey)
        if !wasComplete && newValue >= Self.longWordsTarget { addWeeklyCompletion() }
    }

    func recordGameCompleted() {
        checkAndResetIfNeeded()
        let defaults = UserDefaults.standard
        let current = defaults.integer(forKey: Self.gamesPlayedKey)
        let wasComplete = current >= Self.gamesTarget
        let newValue = current + 1
        defaults.set(newValue, forKey: Self.gamesPlayedKey)
        if !wasComplete && newValue >= Self.gamesTarget { addWeeklyCompletion() }
    }

    private func addWeeklyCompletion() {
        let defaults = UserDefaults.standard
        let current = defaults.integer(forKey: Self.weekCompletionsKey)
        defaults.set(min(Self.weeklyTarget, current + 1), forKey: Self.weekCompletionsKey)
    }
}

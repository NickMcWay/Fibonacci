import Foundation

final class StreakManager {
    static let shared = StreakManager()

    private let streakKey     = "Quibly_Streak"
    private let bestStreakKey = "Quibly_BestStreak"
    private let lastPlayedKey = "Quibly_LastPlayedDate"

    var currentStreak: Int { max(1, UserDefaults.standard.integer(forKey: streakKey)) }
    var bestStreak: Int    { UserDefaults.standard.integer(forKey: bestStreakKey) }

    private init() {
        if UserDefaults.standard.integer(forKey: streakKey) == 0 {
            UserDefaults.standard.set(1, forKey: streakKey)
        }
        if UserDefaults.standard.integer(forKey: bestStreakKey) == 0 {
            UserDefaults.standard.set(1, forKey: bestStreakKey)
        }
    }

    /// Call at the start of each game session.
    /// Returns true if today is a new day and the streak count just increased (or was reset).
    @discardableResult
    func recordPlay() -> Bool {
        let cal      = Calendar.current
        let today    = cal.startOfDay(for: Date())
        let defaults = UserDefaults.standard

        let lastPlayed = defaults.object(forKey: lastPlayedKey) as? Date

        defer { defaults.set(Date(), forKey: lastPlayedKey) }

        guard let last = lastPlayed else {
            defaults.set(1, forKey: streakKey)
            defaults.set(1, forKey: bestStreakKey)
            return true
        }

        let lastDay = cal.startOfDay(for: last)

        if cal.isDate(lastDay, inSameDayAs: today) {
            return false  // already played today, no change
        }

        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        if cal.isDate(lastDay, inSameDayAs: yesterday) {
            let newStreak = currentStreak + 1
            defaults.set(newStreak, forKey: streakKey)
            if newStreak > bestStreak { defaults.set(newStreak, forKey: bestStreakKey) }
        } else {
            defaults.set(1, forKey: streakKey)
        }

        return true
    }
}

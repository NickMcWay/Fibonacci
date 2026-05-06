// GameSettings.swift
// Language selection, scrabble letter values, and board size configuration.

import Foundation

enum GameLanguage: String, CaseIterable, Identifiable {
    case english = "English"
    case dutch = "Dutch"
    case german = "German"
    case french = "French"
    case spanish = "Spanish"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .dutch:   return "🇳🇱"
        case .german:  return "🇩🇪"
        case .french:  return "🇫🇷"
        case .spanish: return "🇪🇸"
        }
    }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .dutch:   return "Nederlands"
        case .german:  return "Deutsch"
        case .french:  return "Français"
        case .spanish: return "Español"
        }
    }

    // Standard Scrabble letter point values, keyed by lowercase Character.
    var scrabbleValues: [Character: Int] {
        switch self {
        case .english:
            return [
                "a":1,"b":3,"c":3,"d":2,"e":1,"f":4,"g":2,"h":4,
                "i":1,"j":8,"k":5,"l":1,"m":3,"n":1,"o":1,"p":3,
                "q":10,"r":1,"s":1,"t":1,"u":1,"v":4,"w":4,"x":8,
                "y":4,"z":10
            ]
        case .dutch:
            return [
                "a":1,"b":3,"c":5,"d":2,"e":1,"f":4,"g":3,"h":4,
                "i":1,"j":4,"k":3,"l":3,"m":3,"n":1,"o":1,"p":3,
                "q":10,"r":2,"s":2,"t":2,"u":4,"v":4,"w":5,"x":8,
                "y":8,"z":4
            ]
        case .german:
            return [
                "a":1,"b":3,"c":4,"d":1,"e":1,"f":4,"g":2,"h":2,
                "i":1,"j":6,"k":4,"l":2,"m":3,"n":1,"o":2,"p":4,
                "q":10,"r":1,"s":1,"t":1,"u":1,"v":6,"w":3,"x":8,
                "y":10,"z":3
            ]
        case .french:
            return [
                "a":1,"b":3,"c":3,"d":2,"e":1,"f":4,"g":2,"h":4,
                "i":1,"j":8,"k":10,"l":1,"m":2,"n":1,"o":1,"p":3,
                "q":8,"r":1,"s":1,"t":1,"u":1,"v":4,"w":10,"x":10,
                "y":10,"z":10
            ]
        case .spanish:
            return [
                "a":1,"b":3,"c":3,"d":2,"e":1,"f":4,"g":2,"h":4,
                "i":1,"j":8,"k":8,"l":1,"m":3,"n":1,"o":1,"p":3,
                "q":5,"r":1,"s":1,"t":1,"u":1,"v":4,"w":8,"x":8,
                "y":4,"z":10
            ]
        }
    }

    /// Sum of scrabble letter values for a word, multiplied by the word's letter count.
    func wordScore(for word: String) -> Int {
        let baseScore = word.lowercased().reduce(0) { $0 + (scrabbleValues[Character(String($1))] ?? 1) }
        let letterMultiplier = max(1, word.count)
        return baseScore * letterMultiplier
    }
}

enum BoardVariant: Int, CaseIterable, Identifiable {
    case small  = 4
    case medium = 5
    case large  = 6

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .small:  return "4 × 4"
        case .medium: return "5 × 5"
        case .large:  return "6 × 6"
        }
    }

    var label: String {
        switch self {
        case .small:  return "Classic"
        case .medium: return "Extended"
        case .large:  return "Challenge"
        }
    }
}

// MARK: - Game Mode

enum GameMode {
    case classic
    case zen
    case blitz
    case daily
    case swipeLimited
}

// MARK: - Game Settings

struct GameSettings {
    var language: GameLanguage = .english
    var boardVariant: BoardVariant = .small
    var gameMode: GameMode = .classic

    static let `default` = GameSettings()
}

// MARK: - Seeded RNG (for Daily Puzzle)

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

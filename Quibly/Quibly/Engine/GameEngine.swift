// GameEngine.swift
// Orchestrates a complete turn: slide → spawn → detect words → clear → collapse → repeat.
//
// Scoring uses Scrabble letter values (passed via GameLanguage) so that rare letters
// reward more points. Each word's score = (sum of its letter values × letter count) × combo multiplier.
//
// Post-clear rule:
//   After clearing matched word tiles the board re-slides in the SAME direction as the
//   original swipe. Chain reactions are detected after each collapse until no matches
//   remain. Each chain increases the combo multiplier.

import Foundation

struct TurnResult {
    var board: BoardModel
    var clearedWords: [String]
    var pointsEarned: Int
    var comboCount: Int
    var isGameOver: Bool
    var spawnedPosition: (row: Int, col: Int)?
}

enum GameEngine {

    // MARK: - Scoring helper

    static func wordScore(_ word: String, language: GameLanguage) -> Int {
        let values = language.scrabbleValues
        let baseScore = word.lowercased().reduce(0) { $0 + (values[Character(String($1))] ?? 1) }
        let letterMultiplier = max(1, word.count)
        return baseScore * letterMultiplier
    }

    static func score(for match: WordValidator.WordMatch, on board: BoardModel, language: GameLanguage) -> Int {
        let values = language.scrabbleValues
        let wordChars = Array(match.word.lowercased())
        var baseScore = 0

        for (index, pos) in match.positions.enumerated() {
            guard index < wordChars.count else { continue }
            guard let tile = board.tile(row: pos.row, col: pos.col) else { continue }
            if tile.isJoker { continue }
            baseScore += values[wordChars[index]] ?? 1
        }

        let letterMultiplier = max(1, match.word.count)
        return baseScore * letterMultiplier
    }

    // MARK: - Main Turn Entry Point

    static func processTurn(board: BoardModel, direction: SwipeDirection, language: GameLanguage = .english) -> TurnResult? {
        let (slid, moved) = board.sliding(direction: direction)
        guard moved else { return nil }

        guard let spawnedTile = LetterSpawnEngine.spawnTile(for: slid, language: language) else {
            let isOver = isGameOver(board: slid)
            return TurnResult(board: slid, clearedWords: [], pointsEarned: 0,
                              comboCount: 0, isGameOver: isOver, spawnedPosition: nil)
        }

        var current = slid
        current.setTile(spawnedTile, row: spawnedTile.row, col: spawnedTile.col)
        let spawnPos = (row: spawnedTile.row, col: spawnedTile.col)

        if let secondTile = LetterSpawnEngine.spawnTile(for: current, language: language) {
            current.setTile(secondTile, row: secondTile.row, col: secondTile.col)
        }

        var totalPoints = 0
        var allWords: [String] = []
        var comboCount = 0

        while true {
            let matches = WordValidator.findMatches(in: current, language: language)
            guard !matches.isEmpty else { break }

            var toRemove = Set<Int>()
            for match in matches {
                allWords.append(match.word)
                for pos in match.positions { toRemove.insert(current.index(pos.row, pos.col)) }
            }

            let multiplier = comboCount + 1
            let roundPoints = matches.reduce(0) { $0 + score(for: $1, on: current, language: language) } * multiplier
            totalPoints += roundPoints
            comboCount += 1

            for idx in toRemove { current.cells[idx] = nil }
            let (collapsed, _) = current.sliding(direction: direction)
            current = collapsed
        }

        let isOver = current.isFull && !canAnySwipeMove(board: current)
        return TurnResult(
            board: current,
            clearedWords: allWords,
            pointsEarned: totalPoints,
            comboCount: max(0, comboCount - 1),
            isGameOver: isOver,
            spawnedPosition: spawnPos
        )
    }

    // MARK: - Two-phase turn helpers (slide-then-confirm flow)

    static func slideAndSpawn(board: BoardModel, direction: SwipeDirection, language: GameLanguage = .english)
        -> (board: BoardModel, matches: [WordValidator.WordMatch], spawnedPosition: (row: Int, col: Int)?)?
    {
        let (slid, moved) = board.sliding(direction: direction)
        guard moved else { return nil }

        guard let spawnedTile = LetterSpawnEngine.spawnTile(for: slid, language: language) else {
            return (slid, [], nil)
        }
        var current = slid
        current.setTile(spawnedTile, row: spawnedTile.row, col: spawnedTile.col)

        if let secondTile = LetterSpawnEngine.spawnTile(for: current, language: language) {
            current.setTile(secondTile, row: secondTile.row, col: secondTile.col)
        }

        let matches = WordValidator.findMatches(in: current, language: language)
        return (current, matches, (spawnedTile.row, spawnedTile.col))
    }

    static func clearMatches(board: BoardModel, matches: [WordValidator.WordMatch],
                              direction: SwipeDirection, language: GameLanguage = .english)
        -> (board: BoardModel, clearedWords: [String], pointsEarned: Int, comboCount: Int, isGameOver: Bool)
    {
        var current = board
        var totalPoints = 0
        var allWords: [String] = []
        var comboCount = 0

        var toRemove = Set<Int>()
        for match in matches {
            allWords.append(match.word)
            for pos in match.positions { toRemove.insert(current.index(pos.row, pos.col)) }
        }
        let firstRoundScore = matches.reduce(0) { $0 + score(for: $1, on: current, language: language) }
        totalPoints += firstRoundScore * (comboCount + 1)
        comboCount += 1

        for idx in toRemove { current.cells[idx] = nil }
        let (collapsed, _) = current.sliding(direction: direction)
        current = collapsed

        while true {
            let chain = WordValidator.findMatches(in: current, language: language)
            guard !chain.isEmpty else { break }
            var chainRemove = Set<Int>()
            for match in chain {
                allWords.append(match.word)
                for pos in match.positions { chainRemove.insert(current.index(pos.row, pos.col)) }
            }
            let chainScore = chain.reduce(0) { $0 + score(for: $1, on: current, language: language) }
            totalPoints += chainScore * (comboCount + 1)
            comboCount += 1
            for idx in chainRemove { current.cells[idx] = nil }
            let (chainCollapsed, _) = current.sliding(direction: direction)
            current = chainCollapsed
        }

        let isOver = isGameOver(board: current)
        return (current, allWords, totalPoints, max(0, comboCount - 1), isOver)
    }

    // MARK: - Game Over Detection

    static func isGameOver(board: BoardModel) -> Bool {
        guard board.isFull else { return false }
        return !canAnySwipeMove(board: board)
    }

    private static func canAnySwipeMove(board: BoardModel) -> Bool {
        for direction in [SwipeDirection.left, .right, .up, .down] {
            let (_, moved) = board.sliding(direction: direction)
            if moved { return true }
        }
        return false
    }

    // MARK: - Debug Board Presets

    static let debugBoards: [String: BoardModel] = [
        "immediateWord": BoardModel.fromString("care" + "...." + "...." + "...."),
        "nearWord":      BoardModel.fromString("...." + "sta." + "...." + "...."),
        "chainReaction": BoardModel.fromString("love" + "dove" + "...." + "...."),
        "almostFull":    BoardModel.fromString("abcd" + "efgh" + "ijkl" + "mn.."),
    ]
}

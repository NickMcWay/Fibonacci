// GameEngine.swift
// Orchestrates a complete turn: slide → spawn → detect words → clear → collapse → repeat.
//
// Post-clear rule (documented here):
//   After clearing matched word tiles, the board is re-slid in the SAME direction
//   as the original swipe. This feels natural: tiles "fall" the same way they moved,
//   filling gaps left by cleared words. Chain reactions are detected after each collapse
//   until no more matches exist. This avoids the need for a separate "gravity" direction.
//
// Chain reaction handling:
//   We loop: detect matches → mark clearing → collapse in original direction →
//   detect new matches. Continues until a scan finds no matches.
//   Each chain adds a combo multiplier (1x, 2x, 3x, ...) to the word score.

import Foundation

struct TurnResult {
    var board: BoardModel
    var clearedWords: [String]
    var pointsEarned: Int
    var comboCount: Int    // how many chain clears happened this turn
    var isGameOver: Bool
    var spawnedPosition: (row: Int, col: Int)?
}

enum GameEngine {

    static let baseWordScore = 100

    // MARK: - Main Turn Entry Point

    /// Process one complete turn given a swipe direction.
    /// Returns nil if the swipe was invalid (no board change).
    static func processTurn(board: BoardModel, direction: SwipeDirection) -> TurnResult? {
        // 1. Slide
        let (slid, moved) = board.sliding(direction: direction)
        guard moved else { return nil }   // invalid swipe — nothing happens

        // 2. Spawn one new letter tile
        guard let spawnedTile = LetterSpawnEngine.spawnTile(for: slid) else {
            // Board is full after slide — check game over
            let isOver = isGameOver(board: slid)
            return TurnResult(board: slid, clearedWords: [], pointsEarned: 0,
                              comboCount: 0, isGameOver: isOver, spawnedPosition: nil)
        }

        var current = slid
        current.setTile(spawnedTile, row: spawnedTile.row, col: spawnedTile.col)
        let spawnPos = (row: spawnedTile.row, col: spawnedTile.col)

        // 3. Resolve chain reactions
        var totalPoints = 0
        var allWords: [String] = []
        var comboCount = 0

        // Loop: find words → clear → re-slide → repeat
        var continueChain = true
        while continueChain {
            let matches = WordValidator.findMatches(in: current)
            guard !matches.isEmpty else { break }

            // Collect all unique positions across all matches (clear all at once)
            var toRemove = Set<Int>()
            for match in matches {
                allWords.append(match.word)
                for pos in match.positions {
                    toRemove.insert(current.index(pos.row, pos.col))
                }
            }

            // Score: base × combo multiplier × word count this chain
            let multiplier = comboCount + 1
            let roundPoints = matches.count * baseWordScore * multiplier
            totalPoints += roundPoints
            comboCount += 1

            // Clear matched tiles
            for idx in toRemove {
                current.cells[idx] = nil
            }

            // Re-slide in same direction to fill gaps (post-clear rule)
            let (collapsed, _) = current.sliding(direction: direction)
            current = collapsed

            // Continue loop to check for new matches formed by collapse
        }

        let isOver = current.isFull && !canAnySwipeMove(board: current)
        return TurnResult(
            board: current,
            clearedWords: allWords,
            pointsEarned: totalPoints,
            comboCount: max(0, comboCount - 1),  // 0 = single clear, 1+ = chain
            isGameOver: isOver,
            spawnedPosition: spawnPos
        )
    }

    // MARK: - Game Over Detection

    /// Board is game-over when it's full and no swipe in any direction changes it.
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

    /// Pre-set boards for testing. Pass one of these into GameViewModel for debugging.
    static let debugBoards: [String: BoardModel] = [

        // "immediateWord": swipe left → "CARE" appears in row 0
        "immediateWord": BoardModel.fromString(
            "care" +
            "...." +
            "...." +
            "...."
        ),

        // "nearWord": one letter away from forming "STAR" in row 1
        "nearWord": BoardModel.fromString(
            "...." +
            "sta." +
            "...." +
            "...."
        ),

        // "chainReaction": "LOVE" in row 0, "DOVE" in row 1 (both clear at once)
        "chainReaction": BoardModel.fromString(
            "love" +
            "dove" +
            "...." +
            "...."
        ),

        // "almostFull": board nearly full, limited moves
        "almostFull": BoardModel.fromString(
            "abcd" +
            "efgh" +
            "ijkl" +
            "mn.."
        ),
    ]
}

// LetterSpawnEngine.swift
// Board-aware weighted letter spawner.
//
// Instead of uniform random letters, this engine scores each candidate letter
// by how useful it would be given the current board state, then uses weighted
// randomness to pick from the scored candidates.
//
// Scoring algorithm (per candidate letter):
//   +100  if placing it at ANY empty cell immediately completes a valid 4-letter word
//   +25   if it creates a 3-of-4 near-word (any position, any empty on the board)
//   +8    if it creates a useful bigram adjacency from common English pairs
//   +1–10 base frequency weight (common English letters score higher)
//   -5    for each occurrence beyond 2 of that letter already on the board
//         (avoids flooding the board with repeated letters)
//
// The winner is NOT always the top scorer — scores are used as weights in
// a weighted random draw, so lower-scoring letters still appear occasionally.
// This keeps the game feeling random to the player while quietly improving odds.

import Foundation

enum LetterSpawnEngine {

    // MARK: - Restricted alphabet for MVP playability
    // Using a curated 14-letter set that generates many 4-letter word combinations.
    // Every letter here participates in at least ~20 words from our dictionary.
    static let alphabet: [Character] = [
        "a", "e", "i", "o",           // vowels (essential)
        "r", "t", "n", "s", "l",      // most common consonants
        "c", "d", "h", "m", "p",      // secondary consonants
        "b", "f", "g", "k", "w"       // tertiary consonants for variety
    ]

    // Base frequency weights — reflect rough English letter frequency,
    // tuned for 4-letter word playability.
    static let baseWeight: [Character: Int] = [
        "a": 9, "e": 10, "i": 7, "o": 8,
        "r": 8, "t": 8,  "n": 7, "s": 9, "l": 6,
        "c": 5, "d": 5,  "h": 5, "m": 5, "p": 4,
        "b": 3, "f": 3,  "g": 3, "k": 3, "w": 3
    ]

    // Common English bigrams that are useful starters/connectors in 4-letter words.
    static let usefulBigrams: Set<String> = [
        "th", "he", "in", "er", "an", "re", "on", "at", "en", "nd",
        "ti", "es", "or", "te", "of", "ed", "is", "it", "al", "ar",
        "st", "to", "nt", "ha", "ng", "ea", "hi", "is", "ou", "tr",
        "se", "ca", "ne", "le", "ow", "la", "ld", "me", "ro", "nd",
        "sh", "ch", "wh", "ph", "dr", "gr", "br", "fr", "cr", "pr",
        "sl", "sp", "sm", "sn", "sc", "sk", "sw", "bl", "cl", "fl",
        "gl", "pl", "ck", "ng", "nk", "mp", "nt", "nd", "rm", "rn",
        "rt", "rd", "lt", "ld", "lk", "lm", "lp", "lf", "ls", "lw"
    ]

    // MARK: - Public API

    /// Choose a letter to spawn given the current board state.
    /// Returns the chosen letter.
    static func chooseLetter(for board: BoardModel) -> Character {
        let scores = scoredCandidates(for: board)
        return weightedRandom(scores)
    }

    /// Spawn a tile at a random empty cell with the best letter choice.
    /// Returns the new Tile, or nil if board is full.
    static func spawnTile(for board: BoardModel) -> Tile? {
        guard !board.emptyPositions.isEmpty else { return nil }
        let letter = chooseLetter(for: board)
        // Pick empty cell — prefer cells that would help form words
        let position = choosePosition(for: board, letter: letter)
        var tile = Tile(letter: letter, row: position.row, col: position.col)
        tile.isNew = true
        return tile
    }

    // MARK: - Scoring

    /// Returns a dictionary of letter → score for all candidate letters.
    static func scoredCandidates(for board: BoardModel) -> [Character: Int] {
        // Count existing letters on board for penalty calculation
        var letterCounts: [Character: Int] = [:]
        for tile in board.cells.compactMap({ $0 }) {
            letterCounts[tile.letter, default: 0] += 1
        }

        var scores: [Character: Int] = [:]

        for letter in alphabet {
            var score = baseWeight[letter] ?? 1

            // Penalty: -5 for each occurrence beyond 2 already on board
            let count = letterCounts[letter] ?? 0
            if count > 2 {
                score -= (count - 2) * 5
            }

            // Score how useful this letter is at each empty position
            let emptyPos = board.emptyPositions
            var bestPositionBonus = 0

            for pos in emptyPos {
                let bonus = scoreLetterAtPosition(letter: letter, row: pos.row, col: pos.col, board: board)
                if bonus > bestPositionBonus {
                    bestPositionBonus = bonus
                }
            }
            score += bestPositionBonus

            // Clamp to at least 1 so every letter has some chance
            scores[letter] = max(1, score)
        }

        return scores
    }

    /// Score how valuable placing `letter` at (row,col) would be.
    private static func scoreLetterAtPosition(letter: Character, row: Int, col: Int, board: BoardModel) -> Int {
        var score = 0

        // Temporarily place tile to test words
        var testBoard = board
        let testTile = Tile(letter: letter, row: row, col: col)
        testBoard.setTile(testTile, row: row, col: col)

        // +100 if this immediately completes a valid word
        let matches = WordValidator.findMatches(in: testBoard)
        let completesWord = matches.contains { match in
            match.positions.contains { $0.row == row && $0.col == col }
        }
        if completesWord { score += 100 }

        // +25 for each 3/4 near-word found (3 tiles present in a row of 4)
        score += scoreNearWords(letter: letter, row: row, col: col, board: board) * 25

        // +8 for useful bigrams with adjacent tiles
        score += scoreBigrams(letter: letter, row: row, col: col, board: board) * 8

        return score
    }

    /// Count how many 3-of-4 windows this letter would participate in,
    /// where the 4th slot is empty (possible future completion).
    private static func scoreNearWords(letter: Character, row: Int, col: Int, board: BoardModel) -> Int {
        var count = 0
        let size = BoardModel.size

        // Check all horizontal windows that include (row, col)
        let horizStart = max(0, col - 3)
        let horizEnd = min(size - 4, col)
        for startC in horizStart...horizEnd {
            if startC + 3 >= size { continue }
            var letters: [Character?] = []
            var hasEmpty = false
            for c in startC..<startC+4 {
                if c == col {
                    letters.append(letter)
                } else if let t = board.tile(row: row, col: c) {
                    letters.append(t.letter)
                } else {
                    letters.append(nil)
                    hasEmpty = true
                }
            }
            let present = letters.compactMap { $0 }
            if present.count == 3 && hasEmpty {
                // Check if filling the gap could form a word
                if couldFormWord(letters: letters) { count += 1 }
            }
        }

        // Check vertical windows that include (row, col)
        let vertStart = max(0, row - 3)
        let vertEnd = min(size - 4, row)
        for startR in vertStart...vertEnd {
            if startR + 3 >= size { continue }
            var letters: [Character?] = []
            var hasEmpty = false
            for r in startR..<startR+4 {
                if r == row {
                    letters.append(letter)
                } else if let t = board.tile(row: r, col: col) {
                    letters.append(t.letter)
                } else {
                    letters.append(nil)
                    hasEmpty = true
                }
            }
            let present = letters.compactMap { $0 }
            if present.count == 3 && hasEmpty {
                if couldFormWord(letters: letters) { count += 1 }
            }
        }

        return count
    }

    /// Returns true if any word in the dictionary matches the given partial letters
    /// (nil = any letter).
    private static func couldFormWord(letters: [Character?]) -> Bool {
        guard letters.count == 4 else { return false }
        for word in WordValidator.wordSet {
            let wChars = Array(word)
            guard wChars.count == 4 else { continue }
            var matches = true
            for i in 0..<4 {
                if let needed = letters[i], needed != wChars[i] {
                    matches = false
                    break
                }
            }
            if matches { return true }
        }
        return false
    }

    /// Count how many useful bigrams (letter, neighbor) or (neighbor, letter) form.
    private static func scoreBigrams(letter: Character, row: Int, col: Int, board: BoardModel) -> Int {
        var count = 0
        let neighbors = [
            (row-1, col), (row+1, col), (row, col-1), (row, col+1)
        ]
        for (nr, nc) in neighbors {
            guard nr >= 0, nr < BoardModel.size, nc >= 0, nc < BoardModel.size else { continue }
            guard let neighbor = board.tile(row: nr, col: nc) else { continue }
            let bigram1 = "\(letter)\(neighbor.letter)"
            let bigram2 = "\(neighbor.letter)\(letter)"
            if usefulBigrams.contains(bigram1) || usefulBigrams.contains(bigram2) {
                count += 1
            }
        }
        return count
    }

    // MARK: - Position Selection
    // Choose which empty cell to place the tile in.
    // Prefers cells that would make the new tile most useful.
    private static func choosePosition(for board: BoardModel, letter: Character) -> (row: Int, col: Int) {
        let empty = board.emptyPositions
        guard !empty.isEmpty else { return (0, 0) }

        // Score each empty position for this letter
        var best = empty[0]
        var bestScore = -999

        for pos in empty {
            let s = scoreLetterAtPosition(letter: letter, row: pos.row, col: pos.col, board: board)
            if s > bestScore {
                bestScore = s
                best = pos
            }
        }

        // 70% chance to use best position, 30% random (keeps it feeling natural)
        if Double.random(in: 0..<1) < 0.70 {
            return best
        } else {
            return empty.randomElement() ?? best
        }
    }

    // MARK: - Weighted Random

    private static func weightedRandom(_ weights: [Character: Int]) -> Character {
        let total = weights.values.reduce(0, +)
        guard total > 0 else { return alphabet.randomElement() ?? "e" }
        var roll = Int.random(in: 0..<total)
        for (letter, weight) in weights {
            roll -= weight
            if roll < 0 { return letter }
        }
        return weights.keys.first ?? "e"
    }
}

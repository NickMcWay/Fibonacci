// LetterSpawnEngine.swift
// Board-aware weighted letter spawner.
//
// Scores each candidate letter by how useful it would be given the current board
// state, then uses weighted randomness to pick from the scored candidates.
// Supports boards of any size (4×4, 5×5, 6×6) by checking windows of all
// relevant lengths (3 up to board.size).

import Foundation

enum LetterSpawnEngine {

    // MARK: - Alphabet

    static let alphabet: [Character] = [
        "a", "e", "i", "o",
        "r", "t", "n", "s", "l",
        "c", "d", "h", "m", "p",
        "b", "f", "g", "k", "w"
    ]

    static let baseWeight: [Character: Int] = [
        "a": 9, "e": 10, "i": 7, "o": 8,
        "r": 8, "t": 8,  "n": 7, "s": 9, "l": 6,
        "c": 5, "d": 5,  "h": 5, "m": 5, "p": 4,
        "b": 3, "f": 3,  "g": 3, "k": 3, "w": 3
    ]

    static let usefulBigrams: Set<String> = [
        "th","he","in","er","an","re","on","at","en","nd",
        "ti","es","or","te","of","ed","is","it","al","ar",
        "st","to","nt","ha","ng","ea","hi","ou","tr",
        "se","ca","ne","le","ow","la","ld","me","ro",
        "sh","ch","wh","dr","gr","br","fr","cr","pr",
        "sl","sp","sm","sn","sc","sk","sw","bl","cl","fl",
        "gl","pl","ck","nk","mp","rm","rn","rt","rd",
        "lt","lk","lm","lp","lf","ls",
    ]

    // MARK: - Public API

    static func chooseLetter(for board: BoardModel) -> Character {
        let scores = scoredCandidates(for: board)
        return weightedRandom(scores)
    }

    static func spawnTile(for board: BoardModel) -> Tile? {
        guard !board.emptyPositions.isEmpty else { return nil }
        let letter = chooseLetter(for: board)
        let position = choosePosition(for: board, letter: letter)
        var tile = Tile(letter: letter, row: position.row, col: position.col)
        tile.hasCoin = Double.random(in: 0..<1) < 0.18
        tile.isJoker = Double.random(in: 0..<1) < 0.08
        tile.isNew = true
        return tile
    }

    // MARK: - Scoring

    static func scoredCandidates(for board: BoardModel) -> [Character: Int] {
        var letterCounts: [Character: Int] = [:]
        for tile in board.cells.compactMap({ $0 }) {
            letterCounts[tile.letter, default: 0] += 1
        }

        var scores: [Character: Int] = [:]
        for letter in alphabet {
            var score = baseWeight[letter] ?? 1
            let count = letterCounts[letter] ?? 0
            if count > 2 { score -= (count - 2) * 5 }

            let emptyPos = board.emptyPositions
            var bestPositionBonus = 0
            for pos in emptyPos {
                let bonus = scoreLetterAtPosition(letter: letter, row: pos.row, col: pos.col, board: board)
                if bonus > bestPositionBonus { bestPositionBonus = bonus }
            }
            score += bestPositionBonus
            scores[letter] = max(1, score)
        }
        return scores
    }

    private static func scoreLetterAtPosition(letter: Character, row: Int, col: Int, board: BoardModel) -> Int {
        var score = 0
        var testBoard = board
        let testTile = Tile(letter: letter, row: row, col: col)
        testBoard.setTile(testTile, row: row, col: col)

        let matches = WordValidator.findMatches(in: testBoard)
        let completesWord = matches.contains { match in
            match.positions.contains { $0.row == row && $0.col == col }
        }
        if completesWord { score += 100 }
        score += scoreNearWords(letter: letter, row: row, col: col, board: board) * 25
        score += scoreBigrams(letter: letter, row: row, col: col, board: board) * 8
        return score
    }

    /// Count how many (windowSize-1)-of-windowSize near-word windows this letter
    /// participates in, across all window sizes from 3 to board.size.
    private static func scoreNearWords(letter: Character, row: Int, col: Int, board: BoardModel) -> Int {
        var count = 0
        let size = board.size

        for windowSize in 3...size {
            // Horizontal windows that include (row, col)
            let hStart = max(0, col - (windowSize - 1))
            let hEnd   = min(size - windowSize, col)
            for startC in hStart...hEnd {
                guard startC + windowSize <= size else { continue }
                var letters: [Character?] = []
                var hasEmpty = false
                for c in startC..<startC+windowSize {
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
                if present.count == windowSize - 1 && hasEmpty, couldFormWord(letters: letters) {
                    count += 1
                }
            }

            // Vertical windows that include (row, col)
            let vStart = max(0, row - (windowSize - 1))
            let vEnd   = min(size - windowSize, row)
            for startR in vStart...vEnd {
                guard startR + windowSize <= size else { continue }
                var letters: [Character?] = []
                var hasEmpty = false
                for r in startR..<startR+windowSize {
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
                if present.count == windowSize - 1 && hasEmpty, couldFormWord(letters: letters) {
                    count += 1
                }
            }
        }
        return count
    }

    private static func couldFormWord(letters: [Character?]) -> Bool {
        let length = letters.count
        let set = WordValidator.wordSetForLength(length)
        guard !set.isEmpty else { return false }
        for word in set {
            let wChars = Array(word)
            guard wChars.count == length else { continue }
            var matches = true
            for i in 0..<length {
                if let needed = letters[i], needed != wChars[i] { matches = false; break }
            }
            if matches { return true }
        }
        return false
    }

    private static func scoreBigrams(letter: Character, row: Int, col: Int, board: BoardModel) -> Int {
        var count = 0
        let neighbors = [(row-1,col),(row+1,col),(row,col-1),(row,col+1)]
        for (nr,nc) in neighbors {
            guard nr >= 0, nr < board.size, nc >= 0, nc < board.size else { continue }
            guard let neighbor = board.tile(row: nr, col: nc) else { continue }
            let b1 = "\(letter)\(neighbor.letter)"
            let b2 = "\(neighbor.letter)\(letter)"
            if usefulBigrams.contains(b1) || usefulBigrams.contains(b2) { count += 1 }
        }
        return count
    }

    // MARK: - Position Selection

    private static func choosePosition(for board: BoardModel, letter: Character) -> (row: Int, col: Int) {
        let empty = board.emptyPositions
        guard !empty.isEmpty else { return (0, 0) }
        var best = empty[0]
        var bestScore = -999
        for pos in empty {
            let s = scoreLetterAtPosition(letter: letter, row: pos.row, col: pos.col, board: board)
            if s > bestScore { bestScore = s; best = pos }
        }
        return Double.random(in: 0..<1) < 0.70 ? best : (empty.randomElement() ?? best)
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

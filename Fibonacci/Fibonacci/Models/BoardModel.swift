// BoardModel.swift
// Owns the 4x4 grid as a flat array of optional Tiles.
// Provides slide operations and board-state queries.
// Pure value type — no UI dependencies.

import Foundation

enum SwipeDirection {
    case up, down, left, right
}

struct BoardModel {
    static let size = 4
    // Row-major: index = row * size + col
    var cells: [Tile?]

    init() {
        cells = Array(repeating: nil, count: Self.size * Self.size)
    }

    // MARK: - Accessors

    func tile(row: Int, col: Int) -> Tile? {
        cells[index(row, col)]
    }

    mutating func setTile(_ tile: Tile?, row: Int, col: Int) {
        cells[index(row, col)] = tile
    }

    func index(_ row: Int, _ col: Int) -> Int {
        row * Self.size + col
    }

    var emptyPositions: [(row: Int, col: Int)] {
        var result: [(Int, Int)] = []
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if tile(row: r, col: c) == nil { result.append((r, c)) }
            }
        }
        return result
    }

    var isFull: Bool { emptyPositions.isEmpty }

    // MARK: - Slide

    // Returns a new board after sliding in direction.
    // Also returns whether anything moved.
    // No merging (unlike 2048) — tiles pack as far as they can go.
    func sliding(direction: SwipeDirection) -> (board: BoardModel, moved: Bool) {
        var result = self
        var moved = false

        switch direction {
        case .left:
            for r in 0..<Self.size {
                let (row, didMove) = packed(row: rowTiles(r))
                if didMove { moved = true }
                for c in 0..<Self.size {
                    var t = row[c]
                    t?.row = r
                    t?.col = c
                    result.setTile(t, row: r, col: c)
                }
            }
        case .right:
            for r in 0..<Self.size {
                let (row, didMove) = packed(row: rowTiles(r).reversed(), thenReverse: true)
                if didMove { moved = true }
                for c in 0..<Self.size {
                    var t = row[c]
                    t?.row = r
                    t?.col = c
                    result.setTile(t, row: r, col: c)
                }
            }
        case .up:
            for c in 0..<Self.size {
                let (col, didMove) = packed(row: colTiles(c))
                if didMove { moved = true }
                for r in 0..<Self.size {
                    var t = col[r]
                    t?.row = r
                    t?.col = c
                    result.setTile(t, row: r, col: c)
                }
            }
        case .down:
            for c in 0..<Self.size {
                let (col, didMove) = packed(row: colTiles(c).reversed(), thenReverse: true)
                if didMove { moved = true }
                for r in 0..<Self.size {
                    var t = col[r]
                    t?.row = r
                    t?.col = c
                    result.setTile(t, row: r, col: c)
                }
            }
        }
        return (result, moved)
    }

    // Pack non-nil tiles to the front of the slice (index 0).
    // thenReverse=true used for right/down so we pack toward far edge.
    private func packed(row: [Tile?], thenReverse: Bool = false) -> ([Tile?], Bool) {
        let nonNil = row.compactMap { $0 }
        var result = nonNil.map { Optional($0) }
        while result.count < Self.size { result.append(nil) }
        if thenReverse { result.reverse() }
        let moved = result.map { $0?.id } != row.map { $0?.id }
        return (result, moved)
    }

    private func rowTiles(_ r: Int) -> [Tile?] {
        (0..<Self.size).map { tile(row: r, col: $0) }
    }

    private func colTiles(_ c: Int) -> [Tile?] {
        (0..<Self.size).map { tile(row: $0, col: c) }
    }

    // MARK: - Debug helpers

    // Inject an arbitrary board for testing.
    // Pass a 16-char string, '.' for empty.
    static func fromString(_ s: String) -> BoardModel {
        var board = BoardModel()
        let chars = Array(s)
        for i in 0..<min(chars.count, size * size) {
            let ch = chars[i]
            if ch != "." {
                let r = i / size, c = i % size
                board.setTile(Tile(letter: ch, row: r, col: c), row: r, col: c)
            }
        }
        return board
    }

    func debugString() -> String {
        var lines: [String] = []
        for r in 0..<Self.size {
            let row = (0..<Self.size).map { tile(row: r, col: $0)?.letter.description ?? "." }
            lines.append(row.joined(separator: " "))
        }
        return lines.joined(separator: "\n")
    }
}

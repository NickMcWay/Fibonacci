// BoardModel.swift
// Owns the board grid as a flat array of optional Tiles.
// Provides slide operations and board-state queries.
// Pure value type — no UI dependencies.
//
// Bug fix: the .down and .right swipe directions previously compared the packed
// result against the *reversed* input rather than the original column/row order,
// causing tiles already at the top/left edge to report "not moved" on a down/right
// swipe even though they would travel to the bottom/right.

import Foundation

enum SwipeDirection {
    case up, down, left, right
}

struct BoardModel {
    let size: Int
    var cells: [Tile?]

    init(size: Int = 4) {
        self.size = size
        cells = Array(repeating: nil, count: size * size)
    }

    // MARK: - Accessors

    func tile(row: Int, col: Int) -> Tile? {
        cells[index(row, col)]
    }

    mutating func setTile(_ tile: Tile?, row: Int, col: Int) {
        cells[index(row, col)] = tile
    }

    func index(_ row: Int, _ col: Int) -> Int {
        row * size + col
    }

    var emptyPositions: [(row: Int, col: Int)] {
        var result: [(Int, Int)] = []
        for r in 0..<size {
            for c in 0..<size {
                if tile(row: r, col: c) == nil { result.append((r, c)) }
            }
        }
        return result
    }

    var isFull: Bool  { emptyPositions.isEmpty }
    var isEmpty: Bool { cells.allSatisfy { $0 == nil } }

    // MARK: - Slide

    // Returns a new board after sliding in direction plus a flag indicating
    // whether any tile actually changed position.
    func sliding(direction: SwipeDirection) -> (board: BoardModel, moved: Bool) {
        var result = self
        var moved = false

        switch direction {
        case .left:
            for r in 0..<size {
                let original = rowTiles(r)
                let (row, didMove) = packedLeft(original)
                if didMove { moved = true }
                for c in 0..<size {
                    var t = row[c]; t?.row = r; t?.col = c
                    result.setTile(t, row: r, col: c)
                }
            }

        case .right:
            // Pack toward the right: reverse, pack left, reverse back.
            // Compare final IDs against *original* (not the intermediate reversed slice)
            // to correctly detect movement.
            for r in 0..<size {
                let original = rowTiles(r)
                let (row, _) = packedLeft(original.reversed())
                let finalRow = row.reversed() as [Tile?]
                let didMove = finalRow.map { $0?.id } != original.map { $0?.id }
                if didMove { moved = true }
                for c in 0..<size {
                    var t = finalRow[c]; t?.row = r; t?.col = c
                    result.setTile(t, row: r, col: c)
                }
            }

        case .up:
            for c in 0..<size {
                let original = colTiles(c)
                let (col, didMove) = packedLeft(original)
                if didMove { moved = true }
                for r in 0..<size {
                    var t = col[r]; t?.row = r; t?.col = c
                    result.setTile(t, row: r, col: c)
                }
            }

        case .down:
            // Same fix as .right: compare against *original* column order.
            for c in 0..<size {
                let original = colTiles(c)
                let (col, _) = packedLeft(original.reversed())
                let finalCol = col.reversed() as [Tile?]
                let didMove = finalCol.map { $0?.id } != original.map { $0?.id }
                if didMove { moved = true }
                for r in 0..<size {
                    var t = finalCol[r]; t?.row = r; t?.col = c
                    result.setTile(t, row: r, col: c)
                }
            }
        }
        return (result, moved)
    }

    /// Pack non-nil tiles to the front (index 0) of the slice.
    /// Returns the packed slice and whether any tile ID changed position.
    private func packedLeft(_ row: some Collection<Tile?>) -> ([Tile?], Bool) {
        let input = Array(row)
        let nonNil = input.compactMap { $0 }
        var result = nonNil.map { Optional($0) }
        while result.count < size { result.append(nil) }
        let moved = result.map { $0?.id } != input.map { $0?.id }
        return (result, moved)
    }

    private func rowTiles(_ r: Int) -> [Tile?] {
        (0..<size).map { tile(row: r, col: $0) }
    }

    private func colTiles(_ c: Int) -> [Tile?] {
        (0..<size).map { tile(row: $0, col: c) }
    }

    // MARK: - Debug helpers

    /// Inject an arbitrary board for testing. Pass a (size×size)-char string, '.' for empty.
    static func fromString(_ s: String, size: Int = 4) -> BoardModel {
        var board = BoardModel(size: size)
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
        for r in 0..<size {
            let row = (0..<size).map { tile(row: r, col: $0)?.letter.description ?? "." }
            lines.append(row.joined(separator: " "))
        }
        return lines.joined(separator: "\n")
    }
}

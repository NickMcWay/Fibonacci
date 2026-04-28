// Tile.swift
// Represents a single letter tile on the board.
// Tiles have a stable UUID so SwiftUI can animate them by identity across moves.

import Foundation

struct Tile: Identifiable, Equatable {
    let id: UUID
    var letter: Character
    var row: Int
    var col: Int
    var hasCoin: Bool

    // Animation state flags — set by the engine, read by the view
    var isNew: Bool = false        // just spawned → scale-in animation
    var isClearing: Bool = false   // matched word → pop-out animation

    var isJoker: Bool {
        letter == "*"
    }

    init(letter: Character, row: Int, col: Int, hasCoin: Bool = false) {
        self.id = UUID()
        self.letter = letter
        self.row = row
        self.col = col
        self.hasCoin = hasCoin
    }

    static func == (lhs: Tile, rhs: Tile) -> Bool {
        lhs.id == rhs.id
    }
}

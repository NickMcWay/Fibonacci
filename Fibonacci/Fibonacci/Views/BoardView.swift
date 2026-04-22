// BoardView.swift
// Renders the 4x4 game board.
// Tiles are positioned absolutely using offset calculations from board geometry
// so SwiftUI can animate their movement using tile.id as stable identity.
// Empty cells are shown as subtle background squares.
// Swipe gestures are detected on the board container.

import SwiftUI

struct BoardView: View {
    @ObservedObject var vm: GameViewModel

    // Minimum drag distance to register as a swipe (avoids accidental taps)
    private let swipeThreshold: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let boardSize = min(geo.size.width, geo.size.height)
            let gap: CGFloat = boardSize * 0.03
            let tileSize = (boardSize - gap * CGFloat(BoardModel.size + 1)) / CGFloat(BoardModel.size)

            ZStack {
                // Background grid (empty cell slots)
                boardBackground(gap: gap, tileSize: tileSize, boardSize: boardSize)

                // Live tiles positioned by row/col
                ForEach(vm.tiles) { tile in
                    TileView(tile: tile, size: tileSize)
                        .position(
                            x: tileX(col: tile.col, gap: gap, tileSize: tileSize),
                            y: tileY(row: tile.row, gap: gap, tileSize: tileSize)
                        )
                        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: tile.col)
                        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: tile.row)
                }
            }
            .frame(width: boardSize, height: boardSize)
            .background(
                RoundedRectangle(cornerRadius: boardSize * 0.05)
                    .fill(Color(red: 0.87, green: 0.87, blue: 0.90))
            )
            .gesture(
                DragGesture(minimumDistance: swipeThreshold)
                    .onEnded { value in
                        let dir = swipeDirection(translation: value.translation)
                        vm.handleSwipe(dir)
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Background Slots

    private func boardBackground(gap: CGFloat, tileSize: CGFloat, boardSize: CGFloat) -> some View {
        ZStack {
            ForEach(0..<BoardModel.size, id: \.self) { r in
                ForEach(0..<BoardModel.size, id: \.self) { c in
                    RoundedRectangle(cornerRadius: tileSize * 0.18)
                        .fill(Color(red: 0.80, green: 0.80, blue: 0.84).opacity(0.6))
                        .frame(width: tileSize, height: tileSize)
                        .position(
                            x: tileX(col: c, gap: gap, tileSize: tileSize),
                            y: tileY(row: r, gap: gap, tileSize: tileSize)
                        )
                }
            }
        }
    }

    // MARK: - Position Helpers

    private func tileX(col: Int, gap: CGFloat, tileSize: CGFloat) -> CGFloat {
        gap + tileSize / 2 + CGFloat(col) * (tileSize + gap)
    }

    private func tileY(row: Int, gap: CGFloat, tileSize: CGFloat) -> CGFloat {
        gap + tileSize / 2 + CGFloat(row) * (tileSize + gap)
    }

    // MARK: - Swipe Direction Detection

    private func swipeDirection(translation: CGSize) -> SwipeDirection {
        let dx = translation.width
        let dy = translation.height
        if abs(dx) > abs(dy) {
            return dx > 0 ? .right : .left
        } else {
            return dy > 0 ? .down : .up
        }
    }
}

#Preview("Board") {
    let vm = GameViewModel()
    BoardView(vm: vm)
        .padding()
        .background(Color(red: 0.97, green: 0.97, blue: 0.98))
}

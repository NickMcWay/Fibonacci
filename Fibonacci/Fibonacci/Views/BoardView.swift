// BoardView.swift
// Renders the 4×4 game board with two interaction modes:
//
//   Swipe  — fast drag anywhere → slides all tiles in that direction.
//   Draw   — slow press-and-drag through adjacent tiles → spells a word.
//            Valid words glow and wait for a single tap anywhere on the
//            board before clearing. Invalid paths are silently discarded.
//
// Disambiguation uses DragGesture.Value.velocity (iOS 17+):
//   speed < 900 px/s when crossing into an adjacent tile → draw mode
//   speed ≥ 900 px/s                                    → slide mode
//
// Drawing rules:
//   • Path may only pass through cells that actually contain a tile.
//   • Each cell may be visited at most once.
//   • Backtracking (returning to the previous cell) removes the last step.
//   • Minimum word length for acceptance: 3 letters.

import SwiftUI

struct BoardView: View {
    @ObservedObject var vm: GameViewModel

    private let swipeThreshold: CGFloat = 20
    private let drawSpeedCap: CGFloat = 900   // px/s; above this = slide

    private enum DragMode { case undecided, draw, slide }
    @State private var dragMode: DragMode = .undecided
    /// Tiles highlighted while the finger is actively tracing.
    @State private var drawPath: [(row: Int, col: Int)] = []
    /// A valid word the user has drawn; glowing and waiting for a confirmation tap.
    @State private var confirmedPath: [(row: Int, col: Int)] = []

    var body: some View {
        GeometryReader { geo in
            let boardSize = min(geo.size.width, geo.size.height)
            let gap: CGFloat = boardSize * 0.03
            let tileSize = (boardSize - gap * CGFloat(BoardModel.size + 1)) / CGFloat(BoardModel.size)

            ZStack {
                boardBackground(gap: gap, tileSize: tileSize)

                ForEach(vm.tiles) { tile in
                    let sel  = inPath(tile, drawPath)
                    let pend = inPath(tile, confirmedPath)
                    TileView(tile: tile, size: tileSize, isSelected: sel, isPending: pend)
                        .position(
                            x: tileX(col: tile.col, gap: gap, tileSize: tileSize),
                            y: tileY(row: tile.row, gap: gap, tileSize: tileSize)
                        )
                        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: tile.col)
                        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: tile.row)
                }

                if !drawPath.isEmpty || !confirmedPath.isEmpty {
                    wordPreview(boardSize: boardSize)
                }
            }
            .frame(width: boardSize, height: boardSize)
            .background(
                RoundedRectangle(cornerRadius: boardSize * 0.05)
                    .fill(Color(red: 0.87, green: 0.87, blue: 0.90))
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in onChanged(v, gap: gap, tileSize: tileSize) }
                    .onEnded   { v in onEnded(v,   gap: gap, tileSize: tileSize) }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Word Preview

    @ViewBuilder
    private func wordPreview(boardSize: CGFloat) -> some View {
        let activePath = confirmedPath.isEmpty ? drawPath : confirmedPath
        let letters = activePath.compactMap { pos in
            vm.tiles.first(where: { $0.row == pos.row && $0.col == pos.col })?.letter
        }
        let word      = String(letters).uppercased()
        let isPending = !confirmedPath.isEmpty
        let isValid   = WordValidator.isValidWord(word.lowercased())
        let wordColor: Color = (isPending || isValid)
            ? Color(red: 0.10, green: 0.72, blue: 0.42)
            : Color(red: 0.35, green: 0.35, blue: 0.40)

        VStack(spacing: 2) {
            Text(word)
                .font(.system(size: boardSize * 0.10, weight: .heavy, design: .rounded))
                .foregroundColor(wordColor)
            if isPending {
                Text("tap to confirm")
                    .font(.system(size: boardSize * 0.055, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.92))
                .shadow(color: .black.opacity(0.14), radius: 6, x: 0, y: 3)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, boardSize * 0.06)
        .allowsHitTesting(false)
    }

    // MARK: - Gesture: onChanged

    private func onChanged(_ v: DragGesture.Value, gap: CGFloat, tileSize: CGFloat) {
        guard !vm.isGameOver else { return }

        let distance = hypot(v.translation.width, v.translation.height)

        // Any real movement cancels a pending (glowing) confirmation
        if !confirmedPath.isEmpty && distance > swipeThreshold * 0.5 {
            confirmedPath = []
        }

        guard !vm.isAnimating else { return }

        let startCell   = tileAt(v.startLocation, gap: gap, tileSize: tileSize)
        let currentCell = tileAt(v.location,      gap: gap, tileSize: tileSize)

        switch dragMode {

        case .undecided:
            // Highlight the pressed tile immediately so there's instant feedback
            if drawPath.isEmpty, let s = startCell {
                drawPath = [s]
            }

            guard let s = startCell else {
                // Started in a gap — switch to slide once moved enough
                if distance > swipeThreshold { dragMode = .slide }
                return
            }

            guard let c = currentCell, !(c.row == s.row && c.col == s.col) else { return }

            // Finger crossed into a different tile — use velocity to decide mode
            let speed = hypot(v.velocity.width, v.velocity.height)
            if adjacent(s, c) && speed < drawSpeedCap {
                dragMode = .draw
                drawPath = [s, c]
            } else {
                dragMode = .slide
                drawPath = []
            }

        case .draw:
            guard let c = currentCell, let last = drawPath.last else { return }
            guard !(c.row == last.row && c.col == last.col) else { return }

            // Backtrack: moving back to the second-to-last tile removes the last
            if drawPath.count >= 2 {
                let prev = drawPath[drawPath.count - 2]
                if c.row == prev.row && c.col == prev.col {
                    drawPath.removeLast()
                    return
                }
            }

            if adjacent(last, c) && !contains(c, drawPath) {
                drawPath.append(c)
            }

        case .slide:
            break
        }
    }

    // MARK: - Gesture: onEnded

    private func onEnded(_ v: DragGesture.Value, gap: CGFloat, tileSize: CGFloat) {
        defer { dragMode = .undecided }

        switch dragMode {

        case .draw:
            let letters = drawPath.compactMap { pos in
                vm.tiles.first(where: { $0.row == pos.row && $0.col == pos.col })?.letter
            }
            let word = String(letters)
            if drawPath.count >= 3 && WordValidator.isValidWord(word) {
                confirmedPath = drawPath   // hand off to glow state
            }
            drawPath = []

        case .slide:
            confirmedPath = []
            drawPath = []
            guard !vm.isAnimating, !vm.isGameOver else { return }
            vm.handleSwipe(swipeDir(v.translation))

        case .undecided:
            // No real movement — treat as a tap
            let tapDist = hypot(v.translation.width, v.translation.height)
            drawPath = []

            if !confirmedPath.isEmpty && tapDist <= swipeThreshold {
                // ── Confirm the pending word ──
                let path = confirmedPath
                confirmedPath = []
                vm.submitDrawnWord(path: path)
            } else if tapDist > swipeThreshold {
                // Tiny slide that never locked into a mode
                confirmedPath = []
                guard !vm.isAnimating, !vm.isGameOver else { return }
                vm.handleSwipe(swipeDir(v.translation))
            }
            // pure tap with no pending word: do nothing
        }
    }

    // MARK: - Hit Testing

    /// Returns the (row, col) of the tile physically located at `point`.
    /// Returns nil if the point is in a gap or the cell is empty (no tile).
    private func tileAt(_ point: CGPoint, gap: CGFloat, tileSize: CGFloat) -> (row: Int, col: Int)? {
        let c = Int((point.x - gap) / (tileSize + gap))
        let r = Int((point.y - gap) / (tileSize + gap))
        guard r >= 0, r < BoardModel.size, c >= 0, c < BoardModel.size else { return nil }
        // Reject points that fall inside the gap between tiles
        let left = gap + CGFloat(c) * (tileSize + gap)
        let top  = gap + CGFloat(r) * (tileSize + gap)
        guard point.x >= left, point.x <= left + tileSize,
              point.y >= top,  point.y <= top  + tileSize else { return nil }
        // Only accept cells that actually hold a letter tile
        guard vm.tiles.contains(where: { $0.row == r && $0.col == c }) else { return nil }
        return (r, c)
    }

    // MARK: - Path Helpers

    private func inPath(_ tile: Tile, _ path: [(row: Int, col: Int)]) -> Bool {
        path.contains { $0.row == tile.row && $0.col == tile.col }
    }

    private func contains(_ cell: (row: Int, col: Int), _ path: [(row: Int, col: Int)]) -> Bool {
        path.contains { $0.row == cell.row && $0.col == cell.col }
    }

    private func adjacent(_ a: (row: Int, col: Int), _ b: (row: Int, col: Int)) -> Bool {
        (abs(a.row - b.row) == 1 && a.col == b.col) ||
        (a.row == b.row && abs(a.col - b.col) == 1)
    }

    // MARK: - Background Grid

    private func boardBackground(gap: CGFloat, tileSize: CGFloat) -> some View {
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

    private func swipeDir(_ t: CGSize) -> SwipeDirection {
        abs(t.width) > abs(t.height)
            ? (t.width  > 0 ? .right : .left)
            : (t.height > 0 ? .down  : .up)
    }
}

#Preview("Board") {
    BoardView(vm: GameViewModel())
        .padding()
        .background(Color(red: 0.97, green: 0.97, blue: 0.98))
}

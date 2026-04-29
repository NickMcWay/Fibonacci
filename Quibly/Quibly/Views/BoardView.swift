// BoardView.swift
// Renders the game board with two interaction modes:
//
//   Swipe  — fast drag anywhere → slides all tiles in that direction.
//   Draw   — slow press-and-drag through adjacent tiles → spells a word.
//
// Board size is read from vm.boardSize (4, 5, or 6) so the same view handles all
// board variants.
//
// Hint / word-highlight behaviour:
//   Pending swipe matches are stored in vm.pendingSwipeMatches but tiles only
//   receive the pulsing green glow (isPending) once vm.showMatchHighlights is true.
//   Until then the player sees no visual indication of which tiles form a word.
//   The word preview at the bottom stays minimal while a match is pending
//   but not yet revealed.

import SwiftUI

struct BoardView: View {
    @ObservedObject var vm: GameViewModel
    @EnvironmentObject private var audio: AudioManager

    private let swipeThreshold: CGFloat = 20
    private let drawSpeedCap: CGFloat = 900

    private enum DragMode { case undecided, draw, slide }
    @State private var dragMode: DragMode = .undecided
    @State private var drawPath: [(row: Int, col: Int)] = []
    @State private var confirmedPath: [(row: Int, col: Int)] = []
    @State private var acceptedWord: String?
    @State private var acceptedScore: Int?
    @State private var acceptedWordTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            let boardSize = min(geo.size.width, geo.size.height)
            let gap: CGFloat = boardSize * 0.03
            let n = CGFloat(vm.boardSize)
            let tileSize = (boardSize - gap * (n + 1)) / n

            ZStack {
                boardBackground(gap: gap, tileSize: tileSize)

                ForEach(vm.tiles) { tile in
                    let sel  = inPath(tile, drawPath)
                    let pend = (inPath(tile, confirmedPath) || isPendingSwipeTile(tile))
                    TileView(
                        tile: tile,
                        size: tileSize,
                        isSelected: sel,
                        isPending: pend,
                        scrabbleValue: tile.isJoker ? nil : vm.scrabbleValue(for: tile.letter)
                    )
                    .position(
                        x: tileX(col: tile.col, gap: gap, tileSize: tileSize),
                        y: tileY(row: tile.row, gap: gap, tileSize: tileSize)
                    )
                    .animation(.spring(response: 0.22, dampingFraction: 0.78), value: tile.col)
                    .animation(.spring(response: 0.22, dampingFraction: 0.78), value: tile.row)
                }
                
                drawPathConnector(gap: gap, tileSize: tileSize)
                pendingSwipeConnector(gap: gap, tileSize: tileSize)

                // Word preview / confirmation hint at the bottom of the board
                if !drawPath.isEmpty || !confirmedPath.isEmpty || acceptedWord != nil || (vm.showMatchHighlights && !vm.pendingSwipeMatches.isEmpty) {
                    wordPreview(boardSize: boardSize)
                }
            }
            .frame(width: boardSize, height: boardSize)
            .background(
                RoundedRectangle(cornerRadius: boardSize * 0.05)
                    .fill(Color.white.opacity(0.08))
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

    private func wordPreview(boardSize: CGFloat) -> some View {
        let hasPendingSwipe = !vm.pendingSwipeMatches.isEmpty
        let revealed = vm.showMatchHighlights

        let text: String
        let isGreen: Bool

        if let acceptedWord, let acceptedScore {
            text = "\(acceptedWord)  +\(acceptedScore)"
            isGreen = true
        } else if hasPendingSwipe {
            if revealed {
                text = vm.pendingSwipeMatches.map { $0.word.uppercased() }.joined(separator: " · ")
                isGreen = true
            } else {
                text = ""
                isGreen = false
            }
        } else {
            let activePath = confirmedPath.isEmpty ? drawPath : confirmedPath
            let letters = activePath.compactMap { pos in
                vm.tiles.first(where: { $0.row == pos.row && $0.col == pos.col })?.letter
            }
            let word = String(letters).uppercased()
            let isDrawPending = !confirmedPath.isEmpty
            let isValid = WordValidator.isValidWord(word.lowercased(), language: vm.language)
            text = word
            isGreen = isDrawPending || isValid
        }

        let wordColor: Color = isGreen
            ? Color(red: 0.10, green: 0.72, blue: 0.42)
            : Color(red: 0.35, green: 0.35, blue: 0.40)

        return VStack(spacing: 2) {
            Text(text)
                .font(.system(size: boardSize * 0.10, weight: .heavy, design: .rounded))
                .foregroundColor(wordColor)
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

        if !confirmedPath.isEmpty && distance > swipeThreshold * 0.5 {
            confirmedPath = []
        }

        guard !vm.isAnimating else { return }

        let startCell   = tileAt(v.startLocation, gap: gap, tileSize: tileSize)
        let currentCell = tileAt(v.location,      gap: gap, tileSize: tileSize)

        switch dragMode {

        case .undecided:
            if drawPath.isEmpty, let s = startCell {
                drawPath = [s]
            }

            guard let s = startCell else {
                if distance > swipeThreshold { dragMode = .slide }
                return
            }

            guard let c = currentCell, !(c.row == s.row && c.col == s.col) else { return }

            let speed = hypot(v.velocity.width, v.velocity.height)
            if adjacent(s, c) && speed < drawSpeedCap {
                dragMode = .draw
                drawPath = [s, c]
                vm.pendingSwipeMatches = []
            } else {
                dragMode = .slide
                drawPath = []
            }

        case .draw:
            guard let c = currentCell, let last = drawPath.last else { return }
            guard !(c.row == last.row && c.col == last.col) else { return }

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
            let isValidSelection = drawPath.count >= 3 && WordValidator.isValidWord(word, language: vm.language)

            if isValidSelection {
                let path = drawPath
                let letters = path.compactMap { pos in
                    vm.tiles.first(where: { $0.row == pos.row && $0.col == pos.col })?.letter
                }
                acceptedWord = String(letters).uppercased()
                acceptedScore = vm.pointsForDrawnWord(path: path)
                audio.playCorrectSelectionFeedback()
                confirmedPath = []
                drawPath = []
                vm.submitDrawnWord(path: path)
                acceptedWordTask?.cancel()
                acceptedWordTask = Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    acceptedWord = nil
                    acceptedScore = nil
                }
            } else if drawPath.count >= 3 {
                confirmedPath = []
                audio.playWrongSelectionFeedback()
                drawPath = []
            } else {
                drawPath = []
            }

        case .slide:
            confirmedPath = []
            drawPath = []
            guard !vm.isAnimating, !vm.isGameOver else { return }
            vm.handleSwipe(swipeDir(v.translation))

        case .undecided:
            let tapDist = hypot(v.translation.width, v.translation.height)
            drawPath = []

            if tapDist <= swipeThreshold {
                if vm.isBombArmed, let tapped = tileAt(v.location, gap: gap, tileSize: tileSize) {
                    confirmedPath = []
                    vm.triggerBomb(at: tapped.row, col: tapped.col)
                    return
                }
                if vm.showMatchHighlights && !vm.pendingSwipeMatches.isEmpty {
                    vm.confirmPendingSwipeWords()
                }
            } else {
                confirmedPath = []
                guard !vm.isAnimating, !vm.isGameOver else { return }
                vm.handleSwipe(swipeDir(v.translation))
            }
        }
    }

    // MARK: - Hit Testing

    private func tileAt(_ point: CGPoint, gap: CGFloat, tileSize: CGFloat) -> (row: Int, col: Int)? {
        let c = Int((point.x - gap) / (tileSize + gap))
        let r = Int((point.y - gap) / (tileSize + gap))
        guard r >= 0, r < vm.boardSize, c >= 0, c < vm.boardSize else { return nil }
        let left = gap + CGFloat(c) * (tileSize + gap)
        let top  = gap + CGFloat(r) * (tileSize + gap)
        guard point.x >= left, point.x <= left + tileSize,
              point.y >= top,  point.y <= top  + tileSize else { return nil }
        guard vm.tiles.contains(where: { $0.row == r && $0.col == c }) else { return nil }
        return (r, c)
    }

    // MARK: - Path Helpers

    private func inPath(_ tile: Tile, _ path: [(row: Int, col: Int)]) -> Bool {
        path.contains { $0.row == tile.row && $0.col == tile.col }
    }

    private func isPendingSwipeTile(_ tile: Tile) -> Bool {
        guard vm.showMatchHighlights else { return false }
        return vm.pendingSwipeMatches.contains { match in
            match.positions.contains { $0.row == tile.row && $0.col == tile.col }
        }
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
            ForEach(0..<vm.boardSize, id: \.self) { r in
                ForEach(0..<vm.boardSize, id: \.self) { c in
                    RoundedRectangle(cornerRadius: tileSize * 0.18)
                        .fill(Color.white.opacity(0.20))
                        .frame(width: tileSize, height: tileSize)
                        .position(
                            x: tileX(col: c, gap: gap, tileSize: tileSize),
                            y: tileY(row: r, gap: gap, tileSize: tileSize)
                        )
                }
            }
        }
    }


    private func drawPathConnector(gap: CGFloat, tileSize: CGFloat) -> some View {
        let activePath = confirmedPath.isEmpty ? drawPath : confirmedPath
        let points = activePath.map {
            CGPoint(
                x: tileX(col: $0.col, gap: gap, tileSize: tileSize),
                y: tileY(row: $0.row, gap: gap, tileSize: tileSize)
            )
        }

        return Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
        }
        .stroke(
            Color(red: 0.08, green: 0.52, blue: 0.95).opacity(0.88),
            style: StrokeStyle(lineWidth: tileSize * 0.12, lineCap: .round, lineJoin: .round)
        )
        .allowsHitTesting(false)
    }

    private func pendingSwipeConnector(gap: CGFloat, tileSize: CGFloat) -> some View {
        let points: [CGPoint] = vm.showMatchHighlights
            ? vm.pendingSwipeMatches.flatMap(\.positions).map {
                CGPoint(x: tileX(col: $0.col, gap: gap, tileSize: tileSize), y: tileY(row: $0.row, gap: gap, tileSize: tileSize))
            }
            : []

        return Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() { path.addLine(to: point) }
        }
        .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: tileSize * 0.10, lineCap: .round, lineJoin: .round))
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

#Preview("Board 4×4") {
    BoardView(vm: GameViewModel(settings: .default))
        .padding()
        .background(Color(red: 0.97, green: 0.97, blue: 0.98))
}

#Preview("Board 5×5") {
    BoardView(vm: GameViewModel(settings: GameSettings(language: .english, boardVariant: .medium)))
        .padding()
        .background(Color(red: 0.97, green: 0.97, blue: 0.98))
}

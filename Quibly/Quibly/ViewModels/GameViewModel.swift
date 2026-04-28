// GameViewModel.swift
// ObservableObject between GameEngine (pure logic) and SwiftUI views.
//
// Hint system:
//   After a swipe finds word(s) the tiles are stored in pendingSwipeMatches but NOT
//   highlighted. A hint timer starts:
//     5 s  → showHintButton = true  (the power-up button starts pulsing)
//    10 s  → showMatchHighlights = true  (tile glows + word preview appear)
//   The player can tap the hint button at any time after 5 s to reveal early.
//   Any new swipe/draw/confirmation cancels and resets the timer.

import SwiftUI
import Combine
import UIKit

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published State

    @Published var tiles: [Tile] = []
    @Published var score: Int = 0
    @Published var bestScore: Int = 0
    @Published var isGameOver: Bool = false
    @Published var lastWords: [String] = []
    @Published var lastPointsEarned: Int = 0
    @Published var comboCount: Int = 0
    @Published var showWordOverlay: Bool = false
    @Published var isAnimating: Bool = false
    @Published var pendingSwipeMatches: [WordValidator.WordMatch] = []
    @Published var showEmptyBoardEffect: Bool = false
    @Published var showBoardFullWarning: Bool = false
    @Published var coins: Int = 125
    @Published var dayStreak: Int = 3
    @Published var hintCharges: Int = 2
    @Published var goalTarget: Int = 5
    @Published var goalProgress: Int = 0

    // Hint system
    @Published var showHintButton: Bool = false       // power-up glows after 5 s
    @Published var showMatchHighlights: Bool = false  // tile glows after 10 s

    // MARK: - Accessors for Views

    var boardSize: Int { board.size }
    var language: GameLanguage { settings.language }

    func scrabbleValue(for letter: Character) -> Int {
        let lower = Character(String(letter).lowercased())
        return settings.language.scrabbleValues[lower] ?? 1
    }

    // MARK: - Private

    private let settings: GameSettings
    private var board: BoardModel
    private let bestScoreKey = "SlideWords_BestScore"
    private var pendingSwipeDirection: SwipeDirection = .left
    private var hintTimerTask: Task<Void, Never>?
    private let shuffleCost: Int = 50
    private let hintCost: Int = 25

    // MARK: - Init

    init(settings: GameSettings) {
        self.settings = settings
        self.board = BoardModel(size: settings.boardVariant.rawValue)
        self.bestScore = UserDefaults.standard.integer(forKey: "SlideWords_BestScore")
        startNewGame()
    }

    convenience init() {
        self.init(settings: .default)
    }

    // MARK: - Game Lifecycle

    func startNewGame() {
        board = BoardModel(size: settings.boardVariant.rawValue)
        score = 0
        isGameOver = false
        lastWords = []
        lastPointsEarned = 0
        comboCount = 0
        showWordOverlay = false
        isAnimating = false
        pendingSwipeMatches = []
        showEmptyBoardEffect = false
        showBoardFullWarning = false
        goalProgress = 0
        resetHintState()

        for _ in 0..<2 {
            if let t = LetterSpawnEngine.spawnTile(for: board) {
                board.setTile(t, row: t.row, col: t.col)
            }
        }
        syncTiles()
    }

    func loadDebugBoard(_ name: String) {
        guard let preset = GameEngine.debugBoards[name] else { return }
        board = preset
        score = 0
        isGameOver = false
        pendingSwipeMatches = []
        resetHintState()
        syncTiles()
    }

    // MARK: - Swipe Handling

    func handleSwipe(_ direction: SwipeDirection) {
        guard !isAnimating, !isGameOver else { return }

        pendingSwipeMatches = []
        resetHintState()

        guard let slideResult = GameEngine.slideAndSpawn(board: board, direction: direction, language: settings.language) else {
            triggerHaptic(.error)
            return
        }

        isAnimating = true
        board = slideResult.board

        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            syncTiles()
        }

        triggerHaptic(.light)

        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            isAnimating = false

            if slideResult.spawnedPosition == nil {
                if GameEngine.isGameOver(board: board) {
                    isGameOver = true
                } else {
                    showBoardFullWarning = true
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        showBoardFullWarning = false
                    }
                }
            } else if slideResult.matches.isEmpty {
                if GameEngine.isGameOver(board: board) { isGameOver = true }
            } else {
                // Store matches but don't reveal them yet — start the hint timer
                pendingSwipeMatches = slideResult.matches
                pendingSwipeDirection = direction
                startHintTimer()
            }
        }
    }

    /// User taps the hint / power-up button to reveal the word early.
    func usePowerUpHint() {
        guard !pendingSwipeMatches.isEmpty, hintCharges > 0 else { return }
        hintTimerTask?.cancel()
        hintTimerTask = nil
        hintCharges -= 1
        showMatchHighlights = true
        // Leave showHintButton true (it will dim after highlights are shown)
    }

    func confirmPendingSwipeWords() {
        guard !pendingSwipeMatches.isEmpty, !isAnimating, !isGameOver else { return }
        let matches = pendingSwipeMatches
        let direction = pendingSwipeDirection
        pendingSwipeMatches = []
        resetHintState()

        isAnimating = true

        for match in matches {
            for pos in match.positions {
                board.cells[board.index(pos.row, pos.col)]?.isClearing = true
            }
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            syncTiles()
        }

        Task {
            try? await Task.sleep(nanoseconds: 280_000_000)
            let result = GameEngine.clearMatches(board: board, matches: matches,
                                                  direction: direction, language: settings.language)
            board = result.board
            score += result.pointsEarned
            lastPointsEarned = result.pointsEarned
            if score > bestScore {
                bestScore = score
                UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
            }

            lastWords = result.clearedWords
            comboCount = result.comboCount
            goalProgress = min(goalTarget, goalProgress + result.clearedWords.count)

            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                syncTiles()
            }

            showBoardFullWarning = false

            if !result.clearedWords.isEmpty {
                showWordOverlay = true
                Task {
                    try? await Task.sleep(nanoseconds: 1_200_000_000)
                    showWordOverlay = false
                }
            }

            triggerHaptic(result.comboCount > 0 ? .heavy : .medium)

            try? await Task.sleep(nanoseconds: 120_000_000)
            isAnimating = false

            if board.isEmpty {
                triggerEmptyBoardEffect()
            } else if result.isGameOver {
                isGameOver = true
            }
        }
    }

    // MARK: - Drawn Word Submission

    func submitDrawnWord(path: [(row: Int, col: Int)]) {
        guard !isAnimating, !isGameOver else { return }
        resetHintState()

        let pathTiles = path.compactMap { board.tile(row: $0.row, col: $0.col) }
        guard pathTiles.count == path.count else { return }

        let word = String(pathTiles.map { $0.letter })
        guard WordValidator.isValidWord(word, language: settings.language) else {
            triggerHaptic(.error)
            return
        }

        isAnimating = true

        for pos in path {
            board.cells[board.index(pos.row, pos.col)]?.isClearing = true
        }

        let earned = GameEngine.wordScore(word, language: settings.language)
        score += earned
        lastPointsEarned = earned
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
        }

        lastWords = [word]
        comboCount = 0
        goalProgress = min(goalTarget, goalProgress + 1)

        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            syncTiles()
        }

        showWordOverlay = true
        triggerHaptic(.medium)

        Task {
            try? await Task.sleep(nanoseconds: 280_000_000)
            for pos in path { board.cells[board.index(pos.row, pos.col)] = nil }
            showBoardFullWarning = false
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                syncTiles()
            }
            try? await Task.sleep(nanoseconds: 120_000_000)
            isAnimating = false

            if board.isEmpty {
                triggerEmptyBoardEffect()
            } else if GameEngine.isGameOver(board: board) {
                isGameOver = true
            }
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            showWordOverlay = false
        }
    }

    // MARK: - Hint Timer

    private func startHintTimer() {
        hintTimerTask?.cancel()
        showHintButton = false
        showMatchHighlights = false

        hintTimerTask = Task {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)   // 5 s
                showHintButton = true
                try await Task.sleep(nanoseconds: 5_000_000_000)   // 10 s total
                showMatchHighlights = true
            } catch {
                // Task cancelled — leave state as-is (resetHintState will clean up)
            }
        }
    }

    private func resetHintState() {
        hintTimerTask?.cancel()
        hintTimerTask = nil
        showHintButton = false
        showMatchHighlights = false
    }

    // MARK: - Empty Board Effect

    private func triggerEmptyBoardEffect() {
        showWordOverlay = false
        showEmptyBoardEffect = true
        triggerHaptic(.heavy)

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if let newTile = LetterSpawnEngine.spawnTile(for: board) {
                board.setTile(newTile, row: newTile.row, col: newTile.col)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    syncTiles()
                }
            }
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            showEmptyBoardEffect = false
        }
    }

    // MARK: - Tile Sync

    private func syncTiles() {
        tiles = board.cells.compactMap { $0 }
    }

    // MARK: - Economy Actions

    var shufflePrice: Int { shuffleCost }
    var hintPrice: Int { hintCost }
    var canAffordShuffle: Bool { coins >= shuffleCost && !isAnimating && !isGameOver }
    var canAffordHint: Bool { coins >= hintCost && !isAnimating && !isGameOver }

    func buyHints() {
        guard canAffordHint else { return }
        coins -= hintCost
        hintCharges += 1
        triggerHaptic(.light)
    }

    func shuffleBoard() {
        guard canAffordShuffle else { return }
        let tiles = board.cells.compactMap { $0 }
        guard tiles.count > 1 else { return }

        coins -= shuffleCost
        let positions = board.cells.indices.shuffled()
        var shuffled = board
        shuffled.cells = Array(repeating: nil, count: board.size * board.size)

        var tileIndex = 0
        for index in positions where tileIndex < tiles.count {
            let row = index / board.size
            let col = index % board.size
            var tile = tiles[tileIndex]
            tile.row = row
            tile.col = col
            tile.isNew = false
            shuffled.cells[index] = tile
            tileIndex += 1
        }

        board = shuffled
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            syncTiles()
        }
        triggerHaptic(.medium)
    }

    // MARK: - Haptic Feedback

    private enum HapticStyle { case light, medium, heavy, error }

    private func triggerHaptic(_ style: HapticStyle) {
        #if os(iOS)
        switch style {
        case .light:  UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:  UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .error:  UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        #endif
    }
}

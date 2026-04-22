// GameViewModel.swift
// ObservableObject that sits between GameEngine (pure logic) and SwiftUI views.
// All game state exposed to the UI lives here.
// Animation sequencing is managed here using async delays.

import SwiftUI
import Combine

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published State

    @Published var tiles: [Tile] = []           // flat list of all live tiles
    @Published var score: Int = 0
    @Published var bestScore: Int = 0
    @Published var isGameOver: Bool = false
    @Published var lastWords: [String] = []     // words found this turn (for overlay)
    @Published var comboCount: Int = 0          // chain multiplier count
    @Published var showWordOverlay: Bool = false
    @Published var isAnimating: Bool = false    // lock swipes during animation

    // MARK: - Board (private, source of truth)

    private var board: BoardModel = BoardModel()
    private let bestScoreKey = "SlideWords_BestScore"

    // MARK: - Init

    init() {
        bestScore = UserDefaults.standard.integer(forKey: bestScoreKey)
        startNewGame()
    }

    // MARK: - Game Lifecycle

    func startNewGame() {
        board = BoardModel()
        score = 0
        isGameOver = false
        lastWords = []
        comboCount = 0
        showWordOverlay = false
        isAnimating = false

        // Seed board with 2 random tiles (like 2048 start feel)
        for _ in 0..<2 {
            if let t = LetterSpawnEngine.spawnTile(for: board) {
                board.setTile(t, row: t.row, col: t.col)
            }
        }
        syncTiles()
    }

    // Inject a debug board preset by name
    func loadDebugBoard(_ name: String) {
        guard let preset = GameEngine.debugBoards[name] else { return }
        board = preset
        score = 0
        isGameOver = false
        syncTiles()
    }

    // MARK: - Swipe Handling

    func handleSwipe(_ direction: SwipeDirection) {
        guard !isAnimating, !isGameOver else { return }

        guard let result = GameEngine.processTurn(board: board, direction: direction) else {
            // Invalid swipe — haptic feedback (stub)
            triggerHaptic(.error)
            return
        }

        isAnimating = true

        // Apply new board state
        board = result.board
        score += result.pointsEarned

        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
        }

        lastWords = result.clearedWords
        comboCount = result.comboCount

        // Sync tiles — SwiftUI animates by tile.id identity
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            syncTiles()
        }

        // Show word overlay if words were cleared
        if !result.clearedWords.isEmpty {
            showWordOverlay = true
            Task {
                try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s
                showWordOverlay = false
            }
        }

        // Haptic
        if result.pointsEarned > 0 {
            triggerHaptic(result.comboCount > 0 ? .heavy : .medium)
        } else {
            triggerHaptic(.light)
        }

        // Release animation lock
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000) // 0.35s
            isAnimating = false
            if result.isGameOver {
                isGameOver = true
            }
        }
    }

    // MARK: - Tile Sync

    // Convert board cells to flat tile list for SwiftUI.
    // Using tile.id as stable identity lets SwiftUI track movement.
    private func syncTiles() {
        tiles = board.cells.compactMap { $0 }
    }

    // MARK: - Haptic Feedback (stubs — wire up UIImpactFeedbackGenerator on iOS)

    private enum HapticStyle { case light, medium, heavy, error }

    private func triggerHaptic(_ style: HapticStyle) {
        // On a real device, use UIImpactFeedbackGenerator or UINotificationFeedbackGenerator.
        // Example:
        // let gen = UIImpactFeedbackGenerator(style: .medium)
        // gen.impactOccurred()
    }
}

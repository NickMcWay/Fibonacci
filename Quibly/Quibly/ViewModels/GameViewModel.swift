// GameViewModel.swift
import SwiftUI
import Combine
import UIKit

enum PowerUpAnimation: Equatable {
    case hint, shuffle, bomb, wild
}

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
    @Published var coins: Int = 125 {
        didSet { UserDefaults.standard.set(coins, forKey: coinsKey) }
    }
    @Published var hintCharges: Int = 2 {
        didSet { UserDefaults.standard.set(hintCharges, forKey: hintChargesKey) }
    }
    @Published var bombCharges: Int = 1 {
        didSet { UserDefaults.standard.set(bombCharges, forKey: bombChargesKey) }
    }
    @Published var shuffleCharges: Int = 1 {
        didSet { UserDefaults.standard.set(shuffleCharges, forKey: shuffleChargesKey) }
    }
    @Published var wildCharges: Int = 1 {
        didSet { UserDefaults.standard.set(wildCharges, forKey: wildChargesKey) }
    }
    @Published var isBombArmed: Bool = false
    @Published var isWildArmed: Bool = false

    // Hint system
    @Published var showHintButton: Bool = false
    @Published var showMatchHighlights: Bool = false

    // Animation events
    @Published var powerUpAnimation: PowerUpAnimation? = nil

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
    private let bestScoreKey      = "SlideWords_BestScore"
    private let coinsKey          = "SlideWords_Coins"
    private let hintChargesKey    = "SlideWords_HintCharges"
    private let bombChargesKey    = "SlideWords_BombCharges"
    private let shuffleChargesKey = "SlideWords_ShuffleCharges"
    private let wildChargesKey    = "SlideWords_WildCharges"
    private var pendingSwipeDirection: SwipeDirection = .left
    private var hintTimerTask: Task<Void, Never>?

    let shuffleCost: Int = 50
    let hintCost: Int   = 25
    let bombCost: Int   = 75
    let wildCost: Int   = 60
    private let coinPerCoinTile: Int = 10

    // MARK: - Init

    init(settings: GameSettings) {
        self.settings = settings
        self.board = BoardModel(size: settings.boardVariant.rawValue)
        self.bestScore = UserDefaults.standard.integer(forKey: bestScoreKey)
        self.coins         = (UserDefaults.standard.object(forKey: "SlideWords_Coins")          as? Int) ?? 125
        self.hintCharges   = (UserDefaults.standard.object(forKey: "SlideWords_HintCharges")    as? Int) ?? 2
        self.bombCharges   = (UserDefaults.standard.object(forKey: "SlideWords_BombCharges")    as? Int) ?? 1
        self.shuffleCharges = (UserDefaults.standard.object(forKey: "SlideWords_ShuffleCharges") as? Int) ?? 1
        self.wildCharges   = (UserDefaults.standard.object(forKey: "SlideWords_WildCharges")    as? Int) ?? 1
        startNewGame()
    }

    convenience init() { self.init(settings: .default) }

    // MARK: - Sync from external changes (e.g. Shop sheet)

    func syncFromDefaults() {
        if let v = UserDefaults.standard.object(forKey: coinsKey)          as? Int { coins = v }
        if let v = UserDefaults.standard.object(forKey: hintChargesKey)    as? Int { hintCharges = v }
        if let v = UserDefaults.standard.object(forKey: bombChargesKey)    as? Int { bombCharges = v }
        if let v = UserDefaults.standard.object(forKey: shuffleChargesKey) as? Int { shuffleCharges = v }
        if let v = UserDefaults.standard.object(forKey: wildChargesKey)    as? Int { wildCharges = v }
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
        isBombArmed = false
        isWildArmed = false
        resetHintState()

        for _ in 0..<2 {
            if let t = LetterSpawnEngine.spawnTile(for: board, language: settings.language) {
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
        isBombArmed = false
        isWildArmed = false
        resetHintState()
        syncTiles()
    }

    // MARK: - Swipe Handling

    func handleSwipe(_ direction: SwipeDirection) {
        guard !isAnimating, !isGameOver else { return }

        pendingSwipeMatches = []
        isBombArmed = false
        isWildArmed = false
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
                pendingSwipeMatches = slideResult.matches
                pendingSwipeDirection = direction
                startHintTimer()
            }
        }
    }

    func usePowerUpHint() {
        guard !pendingSwipeMatches.isEmpty, hintCharges > 0 else { return }
        hintTimerTask?.cancel()
        hintTimerTask = nil
        hintCharges -= 1
        showMatchHighlights = true
        powerUpAnimation = .hint
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            powerUpAnimation = nil
        }
    }

    func confirmPendingSwipeWords() {
        guard !pendingSwipeMatches.isEmpty, !isAnimating, !isGameOver else { return }
        let matches = pendingSwipeMatches
        let direction = pendingSwipeDirection
        let coinTilesUsed = matches.flatMap(\.positions).filter { pos in
            board.tile(row: pos.row, col: pos.col)?.hasCoin == true
        }.count
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
            coins += coinTilesUsed * coinPerCoinTile

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

        let word = String(pathTiles.map { $0.isJoker ? "*" : $0.letter })
        guard WordValidator.isValidWord(word, language: settings.language) else {
            triggerHaptic(.error)
            return
        }

        isAnimating = true

        let resolvedWord = WordValidator.resolveWord(for: word, language: settings.language) ?? word.lowercased()
        let resolvedChars = Array(resolvedWord)

        for (index, pos) in path.enumerated() {
            guard let tile = board.cells[board.index(pos.row, pos.col)] else { continue }
            board.cells[board.index(pos.row, pos.col)]?.isClearing = true
            if tile.isJoker, index < resolvedChars.count {
                board.cells[board.index(pos.row, pos.col)]?.jokerResolvedLetter = resolvedChars[index]
            }
        }

        let earned = scoreForDrawnWord(pathTiles: pathTiles, validatedWord: word)
        let coinTilesUsed = pathTiles.filter(\.hasCoin).count
        score += earned
        coins += coinTilesUsed * coinPerCoinTile
        lastPointsEarned = earned
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
        }

        lastWords = [word]
        comboCount = 0

        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            syncTiles()
        }

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
    }

    func pointsForDrawnWord(path: [(row: Int, col: Int)]) -> Int? {
        let pathTiles = path.compactMap { board.tile(row: $0.row, col: $0.col) }
        guard pathTiles.count == path.count else { return nil }
        let word = String(pathTiles.map { $0.isJoker ? "*" : $0.letter })
        guard WordValidator.isValidWord(word, language: settings.language) else { return nil }
        return scoreForDrawnWord(pathTiles: pathTiles, validatedWord: word)
    }

    private func scoreForDrawnWord(pathTiles: [Tile], validatedWord: String) -> Int {
        let values = settings.language.scrabbleValues
        let resolved = WordValidator.resolveWord(for: validatedWord, language: settings.language) ?? validatedWord.lowercased()
        let chars = Array(resolved)

        var baseScore = 0
        for (index, tile) in pathTiles.enumerated() {
            guard index < chars.count else { continue }
            if tile.isJoker { continue }
            baseScore += values[chars[index]] ?? 1
        }

        let letterMultiplier = max(1, resolved.count)
        return baseScore * letterMultiplier
    }

    // MARK: - Hint Timer

    private func startHintTimer() {
        hintTimerTask?.cancel()
        showHintButton = false
        showMatchHighlights = false

        hintTimerTask = Task {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                showHintButton = true
                try await Task.sleep(nanoseconds: 5_000_000_000)
                showMatchHighlights = true
            } catch {}
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
            if let newTile = LetterSpawnEngine.spawnTile(for: board, language: settings.language) {
                board.setTile(newTile, row: newTile.row, col: newTile.col)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    syncTiles()
                }
            }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showEmptyBoardEffect = false
        }
    }

    // MARK: - Tile Sync

    private func syncTiles() {
        tiles = board.cells.compactMap { $0 }
    }

    // MARK: - Economy: computed

    var canUseBomb: Bool    { bombCharges > 0 && !isAnimating && !isGameOver }
    var canAffordBomb: Bool { coins >= bombCost && !isAnimating && !isGameOver }
    var canAffordHint: Bool { coins >= hintCost && !isAnimating && !isGameOver }
    var canUseShuffle: Bool { (shuffleCharges > 0 || coins >= shuffleCost) && !isAnimating && !isGameOver }
    var canUseHintButton: Bool { (hintCharges > 0 || coins >= hintCost) && !isAnimating && !isGameOver }
    var canUseWild: Bool    { wildCharges > 0 && !isAnimating && !isGameOver }
    var canAffordWild: Bool { coins >= wildCost && !isAnimating && !isGameOver }

    // MARK: - Economy: actions

    func shuffleBoard() {
        guard !isAnimating, !isGameOver else { return }
        let tiles = board.cells.compactMap { $0 }
        guard tiles.count > 1 else { return }

        if shuffleCharges > 0 {
            shuffleCharges -= 1
        } else {
            guard coins >= shuffleCost else { return }
            coins -= shuffleCost
        }

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
        powerUpAnimation = .shuffle
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            syncTiles()
        }
        triggerHaptic(.medium)
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            powerUpAnimation = nil
        }
    }

    func toggleBombArm() {
        guard canUseBomb else { return }
        isBombArmed.toggle()
        if isBombArmed { isWildArmed = false }
        triggerHaptic(.light)
    }

    func triggerBomb(at row: Int, col: Int) {
        guard canUseBomb, isBombArmed else { return }

        isBombArmed = false
        bombCharges -= 1
        isAnimating = true

        var toClear: [(row: Int, col: Int)] = []
        for c in 0..<board.size where board.tile(row: row, col: c) != nil {
            toClear.append((row, c))
        }
        for r in 0..<board.size where board.tile(row: r, col: col) != nil {
            if !toClear.contains(where: { $0.row == r && $0.col == col }) {
                toClear.append((r, col))
            }
        }

        for pos in toClear {
            board.cells[board.index(pos.row, pos.col)]?.isClearing = true
        }

        let bombScore = toClear.compactMap { board.tile(row: $0.row, col: $0.col) }
            .reduce(0) { $0 + scrabbleValue(for: $1.letter) }
        score += bombScore
        lastPointsEarned = bombScore
        lastWords = ["Bomb"]

        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
        }

        powerUpAnimation = .bomb
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            syncTiles()
        }

        Task {
            try? await Task.sleep(nanoseconds: 260_000_000)
            for pos in toClear {
                board.cells[board.index(pos.row, pos.col)] = nil
            }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                syncTiles()
            }
            triggerHaptic(.heavy)
            try? await Task.sleep(nanoseconds: 120_000_000)
            isAnimating = false
            powerUpAnimation = nil

            if board.isEmpty {
                triggerEmptyBoardEffect()
            } else if GameEngine.isGameOver(board: board) {
                isGameOver = true
            }
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            showWordOverlay = false
        }
    }

    // MARK: - Wild Powerup

    func toggleWildArm() {
        guard canUseWild else { return }
        isWildArmed.toggle()
        if isWildArmed { isBombArmed = false }
        triggerHaptic(.light)
    }

    func convertTileToJoker(at row: Int, col: Int) {
        guard isWildArmed, wildCharges > 0 else { return }
        guard board.tile(row: row, col: col) != nil else { return }

        isWildArmed = false
        wildCharges -= 1

        board.cells[board.index(row, col)]?.isJoker = true

        powerUpAnimation = .wild
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            syncTiles()
        }
        triggerHaptic(.medium)
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            powerUpAnimation = nil
        }
    }

    // MARK: - Shop Purchases

    func shopBuyHints(count: Int = 1) {
        let cost = hintCost * count
        guard coins >= cost else { return }
        coins -= cost
        hintCharges += count
        triggerHaptic(.light)
    }

    func shopBuyShuffles(count: Int = 1) {
        let cost = shuffleCost * count
        guard coins >= cost else { return }
        coins -= cost
        shuffleCharges += count
        triggerHaptic(.light)
    }

    func shopBuyBombs(count: Int = 1) {
        let cost = bombCost * count
        guard coins >= cost else { return }
        coins -= cost
        bombCharges += count
        triggerHaptic(.light)
    }

    func shopBuyWilds(count: Int = 1) {
        let cost = wildCost * count
        guard coins >= cost else { return }
        coins -= cost
        wildCharges += count
        triggerHaptic(.light)
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

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
    @Published var isGameOver: Bool = false {
        didSet {
            if isGameOver && !oldValue {
                let played = UserDefaults.standard.integer(forKey: gamesPlayedKey) + 1
                UserDefaults.standard.set(played, forKey: gamesPlayedKey)
                if settings.gameMode == .daily {
                    recordDailyPuzzleCompletion()
                } else if settings.gameMode == .sweep {
                    levelComplete = true
                }
            }
        }
    }
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

    // Campaign / Sweep level state
    @Published var campaignLevel: Int = 1
    @Published var levelComplete: Bool = false
    @Published var sweepTilesCleared: Int = 0
    @Published var sweepTotalTiles: Int = 0

    // Streak / session
    @Published var wordsFoundThisSession: Int = 0
    @Published var streakExtendedThisSession: Bool = false

    // Score milestones (2048-style escalation)
    @Published var currentMilestone: Int? = nil
    @Published var isNewPersonalBest: Bool = false
    private var lastTriggeredMilestone: Int = 0
    private static let milestones = [100, 250, 500, 1_000, 2_000, 5_000]

    // Blitz mode
    @Published var timeRemaining: Int = 90
    private var blitzTimerTask: Task<Void, Never>?

    // Swipe-limited mode
    @Published var swipesRemaining: Int = 30
    let swipeLimitTotal: Int = 30
    // Inactivity timer: 15 s total — 10 s silent, then 5 s visible countdown → game over
    // Resets on every valid action. Pauses while purchase sheet is open.
    @Published var noWordCountdown: Int? = nil
    private var noWordTimerTask: Task<Void, Never>?
    private var noWordTimerPhaseStart: Date? = nil
    private var noWordTimerIsPaused: Bool = false
    private var noWordPausedRemainingNanos: UInt64? = nil
    private var noWordPausedCountdown: Int? = nil

    // Hint system
    @Published var showHintButton: Bool = false
    @Published var showMatchHighlights: Bool = false
    @Published var hintedMatches: [WordValidator.WordMatch] = []

    // Animation events
    @Published var powerUpAnimation: PowerUpAnimation? = nil

    // MARK: - Accessors for Views

    var boardSize: Int { board.size }
    var language: GameLanguage { settings.language }
    var gameMode: GameMode { settings.gameMode }

    var isCampaign: Bool { settings.gameMode == .campaign }
    var isSweep: Bool    { settings.gameMode == .sweep }

    var campaignTargetScore: Int { LevelDifficulty.campaignTargetScore(level: campaignLevel) }
    var campaignProgress: Double { min(1.0, Double(score) / Double(campaignTargetScore)) }

    var currentSpawnConfig: SpawnConfig {
        if isCampaign { return LevelDifficulty.spawnConfig(level: campaignLevel) }
        return SpawnConfig()
    }

    var sweepStars: Int {
        let thresholds = LevelDifficulty.sweepStarThresholds(totalTiles: sweepTotalTiles)
        if sweepTilesCleared >= thresholds.three { return 3 }
        if sweepTilesCleared >= thresholds.two   { return 2 }
        if sweepTilesCleared > 0                 { return 1 }
        return 0
    }

    // Joker spawn probability decreases as more words are found this session.
    // Starts at 8%, drops by 1% for every 10 words, flooring at 1%.
    var jokerProbability: Double {
        max(0.01, 0.08 - Double(wordsFoundThisSession / 10) * 0.01)
    }

    func scrabbleValue(for letter: Character) -> Int {
        let lower = Character(String(letter).lowercased())
        return settings.language.scrabbleValues[lower] ?? 1
    }

    // MARK: - Private

    private let settings: GameSettings
    private var board: BoardModel
    private let bestScoreKey         = "SlideWords_BestScore"
    private let coinsKey             = "SlideWords_Coins"
    private let totalXPKey           = "SlideWords_TotalXP"
    static let xpPerLevel: Int       = 500
    private let hintChargesKey       = "SlideWords_HintCharges"
    private let bombChargesKey       = "SlideWords_BombCharges"
    private let shuffleChargesKey    = "SlideWords_ShuffleCharges"
    private let wildChargesKey       = "SlideWords_WildCharges"
    private let gamesPlayedKey       = "SlideWords_GamesPlayed"
    private let totalWordsKey        = "SlideWords_TotalWords"
    private let longestWordKey       = "SlideWords_LongestWord"
    private let dailyCompletedKey    = "DailyPuzzle_CompletedDate"
    private let dailyBestScoreKey    = "DailyPuzzle_BestScore"
    private let campaignLevelKey     = "SlideWords_CampaignLevel"
    private let sweepLevelKey        = "SlideWords_SweepLevel"

    var hasDailyPuzzleBeenCompletedToday: Bool {
        guard let date = UserDefaults.standard.object(forKey: dailyCompletedKey) as? Date else { return false }
        return Calendar.current.isDateInToday(date)
    }

    var dailyPuzzleBestScore: Int {
        UserDefaults.standard.integer(forKey: dailyBestScoreKey)
    }

    private func recordDailyPuzzleCompletion() {
        UserDefaults.standard.set(Date(), forKey: dailyCompletedKey)
        let existing = UserDefaults.standard.integer(forKey: dailyBestScoreKey)
        if score > existing {
            UserDefaults.standard.set(score, forKey: dailyBestScoreKey)
        }
    }
    private var pendingSwipeDirection: SwipeDirection = .left
    private var hintTimerTask: Task<Void, Never>?

    // Settings read from UserDefaults on each action (no need to observe changes live)
    private var isHapticsEnabled: Bool {
        UserDefaults.standard.object(forKey: "SlideWords_HapticsEnabled") as? Bool ?? true
    }
    private var isAutoHintsEnabled: Bool {
        UserDefaults.standard.object(forKey: "SlideWords_AutoHints") as? Bool ?? true
    }

    let shuffleCost: Int = 500
    let hintCost: Int   = 250
    let bombCost: Int   = 750
    let wildCost: Int   = 600
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
        if settings.gameMode == .campaign {
            self.campaignLevel = max(1, UserDefaults.standard.integer(forKey: campaignLevelKey))
        } else if settings.gameMode == .sweep {
            self.campaignLevel = max(1, UserDefaults.standard.integer(forKey: sweepLevelKey))
        }
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
        blitzTimerTask?.cancel()
        blitzTimerTask = nil

        board = BoardModel(size: settings.boardVariant.rawValue)
        score = 0
        isGameOver = false
        timeRemaining = 90
        swipesRemaining = swipeLimitTotal
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
        wordsFoundThisSession = 0
        streakExtendedThisSession = StreakManager.shared.recordPlay()
        currentMilestone = nil
        isNewPersonalBest = false
        lastTriggeredMilestone = 0
        cancelNoWordTimer()
        resetHintState()

        levelComplete = false
        sweepTilesCleared = 0

        if settings.gameMode == .daily {
            spawnDailyTiles()
        } else if settings.gameMode == .sweep {
            spawnSweepTiles()
        } else {
            let config = currentSpawnConfig
            for _ in 0..<2 {
                if let t = LetterSpawnEngine.spawnTile(for: board, language: settings.language, jokerProbability: jokerProbability, allowedLetters: config.allowedLetters) {
                    board.setTile(t, row: t.row, col: t.col)
                }
            }
        }
        syncTiles()

        if settings.gameMode == .blitz {
            startBlitzTimer()
        }
    }

    private func startBlitzTimer() {
        blitzTimerTask = Task {
            while timeRemaining > 0 && !isGameOver {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                if timeRemaining > 0 { timeRemaining -= 1 }
                if timeRemaining == 0 { isGameOver = true }
            }
        }
    }

    private func spawnDailyTiles() {
        let cal = Calendar.current
        let now = Date()
        let seed = UInt64(
            cal.component(.year,  from: now) * 1_000_000 +
            cal.component(.month, from: now) * 10_000 +
            cal.component(.day,   from: now) * 100 +
            settings.boardVariant.rawValue
        )
        var rng = SeededRNG(seed: seed)

        // Simple weighted letter pool weighted toward common letters
        let pool: [Character] = Array(
            "eeeeeeeeaaaaaaaaiiiiioooooouuurrrrrssssttttllllnnnnndddddcccchhhpppggmmbbffwwvvyykjxqz"
        )

        var positions = board.emptyPositions
        for i in stride(from: positions.count - 1, through: 1, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            positions.swapAt(i, j)
        }
        for i in 0..<min(2, positions.count) {
            let letter = pool[Int(rng.next() % UInt64(pool.count))]
            let pos = positions[i]
            var tile = Tile(letter: letter, row: pos.row, col: pos.col)
            tile.isNew = true
            board.setTile(tile, row: pos.row, col: pos.col)
        }
    }

    private func spawnSweepTiles() {
        let size = board.size
        let total = size * size
        let config = LevelDifficulty.spawnConfig(level: campaignLevel)
        let fillCount = Int((LevelDifficulty.sweepFillRatio(level: campaignLevel) * Double(total)).rounded())
        sweepTotalTiles = fillCount
        sweepTilesCleared = 0
        for _ in 0..<fillCount {
            if let t = LetterSpawnEngine.spawnTile(for: board, language: settings.language, jokerProbability: 0.0, allowedLetters: config.allowedLetters) {
                board.setTile(t, row: t.row, col: t.col)
            }
        }
    }

    func loadDebugBoard(_ name: String) {
        guard let preset = GameEngine.debugBoards[name] else { return }
        board = preset
        score = 0
        isGameOver = false
        pendingSwipeMatches = []
        isBombArmed = false
        isWildArmed = false
        cancelNoWordTimer()
        resetHintState()
        syncTiles()
    }

    // MARK: - Swipe Handling

    func handleSwipe(_ direction: SwipeDirection) {
        guard !isAnimating, !isGameOver else { return }

        pendingSwipeMatches = []
        isBombArmed = false
        isWildArmed = false
        cancelNoWordTimer()
        resetHintState()

        if isSweep {
            guard let slideResult = GameEngine.slideOnly(board: board, direction: direction, language: settings.language) else {
                triggerHaptic(.error)
                return
            }
            isAnimating = true
            board = slideResult.board
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) { syncTiles() }
            triggerHaptic(.light)
            Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                isAnimating = false
                if slideResult.matches.isEmpty {
                    if GameEngine.isGameOver(board: board) { isGameOver = true; return }
                } else {
                    pendingSwipeMatches = slideResult.matches
                    pendingSwipeDirection = direction
                    startHintTimer()
                }
                startInactivityTimer()
            }
            return
        }
        guard let slideResult = GameEngine.slideAndSpawn(board: board, direction: direction, language: settings.language, spawnConfig: currentSpawnConfig) else {
            triggerHaptic(.error)
            return
        }

        if settings.gameMode == .swipeLimited {
            swipesRemaining = max(0, swipesRemaining - 1)
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

            if settings.gameMode == .swipeLimited && swipesRemaining == 0 {
                isGameOver = true
                return
            }

            if slideResult.spawnedPosition == nil {
                if settings.gameMode != .zen && GameEngine.isGameOver(board: board) {
                    isGameOver = true
                    return
                }
                showBoardFullWarning = true
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    showBoardFullWarning = false
                }
            } else if slideResult.matches.isEmpty {
                if settings.gameMode != .zen && GameEngine.isGameOver(board: board) {
                    isGameOver = true
                    return
                }
            } else {
                pendingSwipeMatches = slideResult.matches
                pendingSwipeDirection = direction
                startHintTimer()
            }

            startInactivityTimer()
        }
    }

    func usePowerUpHint() {
        guard !pendingSwipeMatches.isEmpty, hintCharges > 0 else { return }
        hintTimerTask?.cancel()
        hintTimerTask = nil
        hintCharges -= 1
        hintedMatches = Array(pendingSwipeMatches.prefix(2))
        showMatchHighlights = true
        powerUpAnimation = .hint
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            powerUpAnimation = nil
        }
        startInactivityTimer()
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
            let totalXP = UserDefaults.standard.integer(forKey: totalXPKey) + result.pointsEarned
            UserDefaults.standard.set(totalXP, forKey: totalXPKey)

            lastWords = result.clearedWords
            wordsFoundThisSession += result.clearedWords.count
            comboCount = result.comboCount

            let newTotal = UserDefaults.standard.integer(forKey: totalWordsKey) + result.clearedWords.count
            UserDefaults.standard.set(newTotal, forKey: totalWordsKey)
            let prevLongest = UserDefaults.standard.string(forKey: longestWordKey) ?? ""
            if let best = result.clearedWords.max(by: { $0.count < $1.count }), best.count > prevLongest.count {
                UserDefaults.standard.set(best.uppercased(), forKey: longestWordKey)
            }
            coins += coinTilesUsed * coinPerCoinTile
            checkMilestones()

            if isCampaign && score >= campaignTargetScore && !levelComplete {
                levelComplete = true
            }
            if isSweep {
                sweepTilesCleared += matches.flatMap(\.positions).count
            }

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

            if isSweep {
                if board.isEmpty || result.isGameOver {
                    isGameOver = true
                } else {
                    startInactivityTimer()
                }
            } else if board.isEmpty {
                triggerEmptyBoardEffect()
            } else if result.isGameOver && settings.gameMode != .zen {
                isGameOver = true
            } else {
                startInactivityTimer()
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

        if settings.gameMode == .swipeLimited {
            swipesRemaining = max(0, swipesRemaining - 1)
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
        let totalXP2 = UserDefaults.standard.integer(forKey: totalXPKey) + earned
        UserDefaults.standard.set(totalXP2, forKey: totalXPKey)

        lastWords = [word]
        wordsFoundThisSession += 1
        comboCount = 0
        checkMilestones()
        if isCampaign && score >= campaignTargetScore && !levelComplete {
            levelComplete = true
        }
        if isSweep {
            sweepTilesCleared += path.count
        }

        let newTotal = UserDefaults.standard.integer(forKey: totalWordsKey) + 1
        UserDefaults.standard.set(newTotal, forKey: totalWordsKey)
        let prevLongest = UserDefaults.standard.string(forKey: longestWordKey) ?? ""
        if resolvedWord.count > prevLongest.count {
            UserDefaults.standard.set(resolvedWord.uppercased(), forKey: longestWordKey)
        }

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

            if settings.gameMode == .swipeLimited && swipesRemaining == 0 {
                isGameOver = true
            } else if isSweep {
                if board.isEmpty || GameEngine.isGameOver(board: board) {
                    isGameOver = true
                } else {
                    startInactivityTimer()
                }
            } else if board.isEmpty {
                triggerEmptyBoardEffect()
            } else if settings.gameMode != .zen && GameEngine.isGameOver(board: board) {
                isGameOver = true
            } else {
                startInactivityTimer()
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

    // MARK: - Score Milestones

    private func checkMilestones() {
        if score > bestScore && !isNewPersonalBest {
            isNewPersonalBest = true
        }
        for m in GameViewModel.milestones.reversed() {
            if score >= m && lastTriggeredMilestone < m {
                lastTriggeredMilestone = m
                currentMilestone = m
                Task {
                    try? await Task.sleep(nanoseconds: 1_800_000_000)
                    if currentMilestone == m { currentMilestone = nil }
                }
                break
            }
        }
    }

    // MARK: - Hint Timer

    private func startHintTimer() {
        guard isAutoHintsEnabled else { return }
        hintTimerTask?.cancel()
        showHintButton = false
        showMatchHighlights = false

        hintTimerTask = Task {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                showHintButton = true
                try await Task.sleep(nanoseconds: 5_000_000_000)
                hintedMatches = Array(pendingSwipeMatches.prefix(2))
                showMatchHighlights = true
            } catch {}
        }
    }

    private func resetHintState() {
        hintTimerTask?.cancel()
        hintTimerTask = nil
        showHintButton = false
        showMatchHighlights = false
        hintedMatches = []
    }

    // MARK: - Inactivity timer

    func cancelNoWordTimer() {
        noWordTimerTask?.cancel()
        noWordTimerTask = nil
        noWordCountdown = nil
        noWordTimerPhaseStart = nil
        noWordTimerIsPaused = false
        noWordPausedRemainingNanos = nil
        noWordPausedCountdown = nil
    }

    func pauseNoWordTimer() {
        guard noWordTimerTask != nil, !noWordTimerIsPaused else { return }
        noWordTimerIsPaused = true
        noWordTimerTask?.cancel()
        noWordTimerTask = nil
        if let countdown = noWordCountdown {
            noWordPausedCountdown = countdown
            noWordPausedRemainingNanos = nil
        } else if let start = noWordTimerPhaseStart {
            let remaining = max(0, 5.0 - Date().timeIntervalSince(start))
            noWordPausedRemainingNanos = UInt64(remaining * 1_000_000_000)
            noWordPausedCountdown = nil
        }
    }

    func resumeNoWordTimer() {
        guard noWordTimerIsPaused else { return }
        noWordTimerIsPaused = false
        let remainingNanos = noWordPausedRemainingNanos ?? 0
        let startCountdown = noWordPausedCountdown
        noWordPausedRemainingNanos = nil
        noWordPausedCountdown = nil
        noWordTimerTask = Task {
            do {
                if let fromCountdown = startCountdown {
                    for seconds in stride(from: fromCountdown, through: 1, by: -1) {
                        guard !Task.isCancelled else { return }
                        noWordCountdown = seconds
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                } else {
                    if remainingNanos > 0 {
                        try await Task.sleep(nanoseconds: remainingNanos)
                    }
                    for seconds in stride(from: 10, through: 1, by: -1) {
                        guard !Task.isCancelled else { return }
                        noWordCountdown = seconds
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                }
                guard !Task.isCancelled else { return }
                noWordCountdown = nil
                isGameOver = true
            } catch {}
        }
    }

    private func startInactivityTimer() {
        guard settings.gameMode != .zen else { return }
        cancelNoWordTimer()
        noWordTimerPhaseStart = Date()
        noWordTimerTask = Task {
            do {
                // 5 s silent window
                try await Task.sleep(nanoseconds: 5_000_000_000)
                // 10 s visible countdown
                for seconds in stride(from: 10, through: 1, by: -1) {
                    guard !Task.isCancelled else { return }
                    noWordCountdown = seconds
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
                guard !Task.isCancelled else { return }
                noWordCountdown = nil
                isGameOver = true
            } catch {}
        }
    }

    // MARK: - Empty Board Effect

    private func triggerEmptyBoardEffect() {
        showWordOverlay = false
        showEmptyBoardEffect = true
        triggerHaptic(.heavy)

        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            let spawnCount = (board.size * board.size) / 2
            for _ in 0..<spawnCount {
                guard let newTile = LetterSpawnEngine.spawnTile(for: board, language: settings.language, jokerProbability: jokerProbability) else { break }
                board.setTile(newTile, row: newTile.row, col: newTile.col)
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                syncTiles()
            }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showEmptyBoardEffect = false
            startInactivityTimer()
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
        cancelNoWordTimer()

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
        startInactivityTimer()
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
        cancelNoWordTimer()
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
        checkMilestones()

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
            } else {
                startInactivityTimer()
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
        startInactivityTimer()
    }

    // MARK: - Shop Purchases

    func shopBuyHints(count: Int = 1) {
        let cost = hintCost * count
        guard coins >= cost else { return }
        cancelNoWordTimer()
        coins -= cost
        hintCharges += count
        triggerHaptic(.light)
    }

    func shopBuyShuffles(count: Int = 1) {
        let cost = shuffleCost * count
        guard coins >= cost else { return }
        cancelNoWordTimer()
        coins -= cost
        shuffleCharges += count
        triggerHaptic(.light)
    }

    func shopBuyBombs(count: Int = 1) {
        let cost = bombCost * count
        guard coins >= cost else { return }
        cancelNoWordTimer()
        coins -= cost
        bombCharges += count
        triggerHaptic(.light)
    }

    func shopBuyWilds(count: Int = 1) {
        let cost = wildCost * count
        guard coins >= cost else { return }
        cancelNoWordTimer()
        coins -= cost
        wildCharges += count
        triggerHaptic(.light)
    }

    // MARK: - Haptic Feedback

    // MARK: - Campaign / Sweep Level Progression

    func advanceCampaignLevel() {
        campaignLevel += 1
        let key = isSweep ? sweepLevelKey : campaignLevelKey
        UserDefaults.standard.set(campaignLevel, forKey: key)
        levelComplete = false
        withAnimation { startNewGame() }
    }

    func retryCampaignLevel() {
        levelComplete = false
        withAnimation { startNewGame() }
    }

    private enum HapticStyle { case light, medium, heavy, error }

    private func triggerHaptic(_ style: HapticStyle) {
        guard isHapticsEnabled else { return }
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

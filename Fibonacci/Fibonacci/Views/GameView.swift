// GameView.swift
// Main game screen. Composes: title, score panels, board, overlays, hint button.
// All game state comes from GameViewModel. This view is purely presentational.
//
// Hint power-up:
//   A lightbulb button sits in the footer. For the first 5 s after a word is found
//   it is dim/disabled. At 5 s it starts pulsing (vm.showHintButton = true).
//   Tapping it immediately reveals the matching tiles (vm.showMatchHighlights).

import SwiftUI

struct GameView: View {
    let settings: GameSettings
    let onReturnToMenu: () -> Void

    @StateObject private var vm: GameViewModel
    @EnvironmentObject private var audio: AudioManager

    @State private var hintGlow: Double = 0.6

    init(settings: GameSettings, onReturnToMenu: @escaping () -> Void) {
        self.settings = settings
        self.onReturnToMenu = onReturnToMenu
        _vm = StateObject(wrappedValue: GameViewModel(settings: settings))
    }

    var body: some View {
        ZStack {
            Color(red: 0.97, green: 0.97, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                Spacer(minLength: 16)

                BoardView(vm: vm)
                    .padding(.horizontal, 16)

                Spacer(minLength: 12)

                footerRow
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }

            // Board full warning
            if vm.showBoardFullWarning {
                VStack {
                    boardFullWarningBanner
                        .padding(.top, 80)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4), value: vm.showBoardFullWarning)
                .zIndex(1)
            }

            // Word cleared overlay
            if vm.showWordOverlay {
                wordClearedOverlay
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: vm.showWordOverlay)
            }

            // Empty board celebration
            if vm.showEmptyBoardEffect {
                clearBoardCelebrationOverlay
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: vm.showEmptyBoardEffect)
                    .zIndex(2)
            }

            // Game over overlay
            if vm.isGameOver {
                gameOverOverlay
                    .transition(.opacity)
                    .animation(.easeIn(duration: 0.4), value: vm.isGameOver)
                    .zIndex(3)
            }
        }
        .onAppear { audio.play() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Quibly")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.22))
                        Text(settings.language.flag)
                            .font(.system(size: 22))
                    }
                    Text("\(settings.boardVariant.displayName) · \(settings.language.rawValue)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 10) {
                    scoreCard(title: "SCORE", value: vm.score)
                    scoreCard(title: "BEST", value: vm.bestScore)
                }
            }

            HStack {
                Spacer()
                // Mute toggle
                Button(action: { audio.toggleMute() }) {
                    Image(systemName: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color(red: 0.92, green: 0.92, blue: 0.95))
                        )
                }
                // New game button
                Button(action: { withAnimation { vm.startNewGame() } }) {
                    Label("New Game", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color(red: 0.40, green: 0.55, blue: 0.85)))
                }
                // Return to menu
                Button(action: onReturnToMenu) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color(red: 0.92, green: 0.92, blue: 0.95))
                        )
                }
                #if DEBUG
                debugMenuButton
                #endif
            }
        }
    }

    // MARK: - Score Card

    private func scoreCard(title: String, value: Int) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            Text("\(value)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.spring(), value: value)
        }
        .frame(minWidth: 70)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.30, green: 0.42, blue: 0.70))
        )
    }

    // MARK: - Footer Row (hint + instructions)

    private var footerRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Swipe to slide · drag slowly to draw a word")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            hintButton
        }
    }

    // MARK: - Hint Power-Up Button

    private var hintButton: some View {
        let available = vm.showHintButton && !vm.pendingSwipeMatches.isEmpty && !vm.showMatchHighlights
        let hasPending = !vm.pendingSwipeMatches.isEmpty && !vm.showMatchHighlights

        return Button(action: {
            guard available else { return }
            vm.usePowerUpHint()
        }) {
            ZStack {
                Circle()
                    .fill(available
                          ? Color(red: 0.95, green: 0.75, blue: 0.20)
                          : Color(red: 0.88, green: 0.88, blue: 0.92))
                    .frame(width: 42, height: 42)

                if available {
                    Circle()
                        .fill(Color(red: 0.95, green: 0.75, blue: 0.20).opacity(0.35))
                        .frame(width: 52, height: 52)
                        .opacity(hintGlow)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                                hintGlow = 1.0
                            }
                        }
                        .onDisappear { hintGlow = 0.6 }
                }

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(available ? .white : Color(red: 0.70, green: 0.70, blue: 0.75))
            }
        }
        .disabled(!hasPending)
        .animation(.spring(response: 0.25), value: available)
    }

    // MARK: - Word Cleared Overlay

    private var wordClearedOverlay: some View {
        VStack(spacing: 6) {
            if vm.comboCount > 0 {
                Text("COMBO ×\(vm.comboCount + 1)!")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.95, green: 0.65, blue: 0.15))
            }
            ForEach(vm.lastWords, id: \.self) { word in
                Text(word.uppercased())
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            Text("+\(vm.lastPointsEarned) pts")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.20, green: 0.55, blue: 0.40).opacity(0.93))
                .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 6)
        )
        .padding(.horizontal, 40)
    }

    // MARK: - Game Over Overlay

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Game Over")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("Final Score: \(vm.score)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))

                if vm.score >= vm.bestScore && vm.score > 0 {
                    Text("New Best!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.95, green: 0.85, blue: 0.30))
                }

                Button(action: { withAnimation { vm.startNewGame() } }) {
                    Text("Play Again")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.40, green: 0.55, blue: 0.85))
                        )
                }
                .padding(.horizontal, 40)

                Button(action: onReturnToMenu) {
                    Text("Main Menu")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
            )
            .padding(.horizontal, 30)
        }
    }

    // MARK: - Board Full Warning

    private var boardFullWarningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.white)
            Text("Board full — clear a word to continue!")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(
            Capsule()
                .fill(Color(red: 0.85, green: 0.45, blue: 0.10))
                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Clear Board Celebration

    private var clearBoardCelebrationOverlay: some View {
        VStack(spacing: 10) {
            Text("✨").font(.system(size: 52))
            Text("Board Cleared!")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            Text("A new tile spawns!")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.52, blue: 0.88),
                            Color(red: 0.38, green: 0.22, blue: 0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.30), radius: 24, x: 0, y: 8)
        )
    }

    // MARK: - Debug Menu (DEBUG builds only)

    #if DEBUG
    private var debugMenuButton: some View {
        Menu {
            ForEach(Array(GameEngine.debugBoards.keys.sorted()), id: \.self) { name in
                Button(name) { vm.loadDebugBoard(name) }
            }
        } label: {
            Image(systemName: "ladybug")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(8)
        }
    }
    #endif
}

// MARK: - Preview

#Preview("Game Screen") {
    GameView(settings: .default, onReturnToMenu: {})
        .environmentObject(AudioManager())
}

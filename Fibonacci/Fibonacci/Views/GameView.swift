// GameView.swift
// Main game screen. Composes: title, score panels, board, word overlay, game over overlay.
// All game state comes from GameViewModel. This view is purely presentational.

import SwiftUI

struct GameView: View {
    @StateObject private var vm = GameViewModel()

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.97, green: 0.97, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                Spacer(minLength: 16)

                BoardView(vm: vm)
                    .padding(.horizontal, 16)

                Spacer(minLength: 16)

                footerHint
                    .padding(.bottom, 24)
            }

            // Word cleared overlay
            if vm.showWordOverlay {
                wordClearedOverlay
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: vm.showWordOverlay)
            }

            // Game over overlay
            if vm.isGameOver {
                gameOverOverlay
                    .transition(.opacity)
                    .animation(.easeIn(duration: 0.4), value: vm.isGameOver)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                // Title
                VStack(alignment: .leading, spacing: 2) {
                    Text("SlideWords")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.22))
                    Text("slide tiles · form words")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Spacer()
                // Score cards
                HStack(spacing: 10) {
                    scoreCard(title: "SCORE", value: vm.score)
                    scoreCard(title: "BEST", value: vm.bestScore)
                }
            }

            // New game button
            HStack {
                Spacer()
                Button(action: { withAnimation { vm.startNewGame() } }) {
                    Label("New Game", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.40, green: 0.55, blue: 0.85))
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

    // MARK: - Footer Hint

    private var footerHint: some View {
        Text("Swipe to slide tiles · press & drag letters to draw a word")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)
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

            Text("+\(pointsDisplay()) pts")
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

    private func pointsDisplay() -> String {
        // Show the last scored amount — pulled from score delta isn't tracked separately,
        // so we show word count × base × combo as a display hint.
        let base = vm.lastWords.count * GameEngine.baseWordScore
        let multiplier = vm.comboCount > 0 ? vm.comboCount + 1 : 1
        return "\(base * multiplier)"
    }

    // MARK: - Game Over Overlay

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

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
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
            )
            .padding(.horizontal, 30)
        }
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
    GameView()
}

#Preview("Near Word State") {
    let vm = GameViewModel()
    vm.loadDebugBoard("nearWord")
    return GameView()
}

import SwiftUI

struct GameView: View {
    let settings: GameSettings
    let onReturnToMenu: () -> Void

    @StateObject private var vm: GameViewModel
    @EnvironmentObject private var audio: AudioManager
    private let uiTint = Color(red: 0.93, green: 0.88, blue: 0.99)
    private let uiTintSecondary = Color(red: 0.86, green: 0.93, blue: 0.99)
    private let uiInk = Color(red: 0.24, green: 0.20, blue: 0.49)

    init(settings: GameSettings, onReturnToMenu: @escaping () -> Void) {
        self.settings = settings
        self.onReturnToMenu = onReturnToMenu
        _vm = StateObject(wrappedValue: GameViewModel(settings: settings))
    }

    var body: some View {
        ZStack {
            dreamyBackground

            VStack(spacing: 14) {
                topBar
                    .padding(.horizontal, 26)
                    .padding(.top, 20)
                
                Spacer(minLength: 8)

                VStack(spacing: 14) {
                    scoreBar
                        .padding(.horizontal, 26)
                    
                    BoardView(vm: vm)
                        .padding(.horizontal, 8)
                        .padding()
                }
                .padding(.horizontal)
                .padding(.top)

                actionBar
                    .padding(.horizontal, 50)
                    .padding(.bottom, 56)
            }
            
            if vm.showWordOverlay {
                celebrateChip
                    .padding(.horizontal, 48)
            }

            if vm.isGameOver {
                gameOverOverlay
            }
        }
        .onAppear { audio.play() }
    }

    private var dreamyBackground: some View {
        Image("Quibly Background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            circleButton(system: "arrow.left", action: onReturnToMenu)
            
            Spacer()

            circleButton(system: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill") {
                audio.toggleMute()
            }
        }
        .padding(.top, 12)
    }

    private var celebrateChip: some View {
        VStack(spacing: 0) {
            Text(vm.lastWords.isEmpty ? "Great!" : vm.lastWords.joined(separator: " · ").uppercased())
                .font(.system(size: 24, weight: .heavy, design: .rounded))
            Text("+\(vm.lastPointsEarned)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.yellow)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(LinearGradient(colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.9)], startPoint: .leading, endPoint: .trailing))
        )
    }

    private var scoreBar: some View {
        HStack(spacing: 16) {
            scoreStat(label: "Score", value: "\(vm.score)")
            Divider()
                .overlay(uiInk.opacity(0.25))
            scoreStat(label: "Best", value: "\(vm.bestScore)")
        }
        .frame(height: 50)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(uiTint.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.6), lineWidth: 1)
                )
        )
    }

    private func scoreStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(uiInk.opacity(0.75))
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(uiInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            actionPill(title: "Goal", subtitle: "\(vm.goalProgress)/\(vm.goalTarget)", icon: "target", enabled: false) {}

            actionPill(title: "Shuffle", subtitle: "⭐️ \(vm.shufflePrice)", icon: "shuffle", enabled: vm.canAffordShuffle) {
                vm.shuffleBoard()
            }

            actionPill(title: "Hint", subtitle: "⭐️ \(vm.hintPrice)", icon: "lightbulb.fill", enabled: vm.canAffordHint) {
                if vm.showHintButton && !vm.pendingSwipeMatches.isEmpty {
                    vm.usePowerUpHint()
                } else {
                    vm.buyHints()
                }
            }
        }
    }

    private func actionPill(title: String, subtitle: String, icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(uiInk)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(uiTintSecondary.opacity(0.96))
                            .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
                    )

                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.56, green: 0.36, blue: 0.08))
            }
            .foregroundColor(uiInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(uiTint.opacity(0.8))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.55), lineWidth: 1))
            )
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.65)
    }

    private func circleButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(uiInk)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(uiTint.opacity(0.92))
                        .overlay(Circle().stroke(.white.opacity(0.55), lineWidth: 1))
                )
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("Game Over")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("Final score: \(vm.score)")
                    .foregroundColor(.white)

                Button("Play Again") {
                    withAnimation { vm.startNewGame() }
                }
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.18)))
                .foregroundColor(.white)
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color.black.opacity(0.35)))
        }
    }
}

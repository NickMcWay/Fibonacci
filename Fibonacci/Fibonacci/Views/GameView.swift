import SwiftUI

struct GameView: View {
    let settings: GameSettings
    let onReturnToMenu: () -> Void

    @StateObject private var vm: GameViewModel
    @EnvironmentObject private var audio: AudioManager

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
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                progressCard
                    .padding(.horizontal, 16)

                BoardView(vm: vm)
                    .padding(.horizontal, 16)

                if vm.showWordOverlay {
                    celebrateChip
                        .padding(.horizontal, 48)
                }

                Spacer(minLength: 0)

                actionBar
                    .padding(.horizontal, 14)
                    .padding(.bottom, 16)
            }

            if vm.isGameOver {
                gameOverOverlay
            }
        }
        .onAppear { audio.play() }
    }

    private var dreamyBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.20, green: 0.29, blue: 0.90),
                Color(red: 0.52, green: 0.38, blue: 0.86),
                Color(red: 0.98, green: 0.82, blue: 0.74)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            circleButton(system: "arrow.left", action: onReturnToMenu)

            Spacer()

            Text("Quibly")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                Text("\(vm.coins)")
                    .contentTransition(.numericText())
            }
            .font(.system(size: 26, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(.white.opacity(0.16)))

            circleButton(system: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill") {
                audio.toggleMute()
            }
        }
    }

    private var progressCard: some View {
        HStack {
            Label("\(vm.dayStreak) Day Streak", systemImage: "flame.fill")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            VStack(spacing: 8) {
                Text("Find the word!")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.27, green: 0.22, blue: 0.63))

                HStack(spacing: 10) {
                    ForEach(0..<vm.goalTarget, id: \.self) { i in
                        Circle()
                            .fill(i < vm.goalProgress ? Color.yellow : Color.white.opacity(0.65))
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Capsule().fill(.white.opacity(0.9)))

            Spacer()

            Button(action: { vm.buyHints() }) {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Circle().fill(.white.opacity(0.22)))

                    Text("\(vm.hintCharges)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.black.opacity(0.7))
                        .padding(7)
                        .background(Circle().fill(Color.yellow))
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.14)))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.25), lineWidth: 1))
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
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(Color.white.opacity(0.22)))

                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.15)))
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.65)
    }

    private func circleButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Circle().fill(.white.opacity(0.15)))
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

#Preview {
    GameView(settings: .default, onReturnToMenu: {})
        .environmentObject(AudioManager())
}

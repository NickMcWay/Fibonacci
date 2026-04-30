import SwiftUI

struct GameView: View {
    let settings: GameSettings
    let onReturnToMenu: () -> Void

    @StateObject private var vm: GameViewModel
    @EnvironmentObject private var audio: AudioManager
    @State private var showRestartAlert  = false
    @State private var showShop          = false
    @State private var showBuyHintSheet  = false
    @State private var showBuyShuffleSheet = false
    @State private var showBuyBombSheet  = false
    @State private var showBuyWildSheet  = false

    // Power-up animation states
    @State private var shuffleBounce: CGFloat = 1.0
    @State private var hintFlash: Double   = 0
    @State private var bombShake: CGFloat  = 0
    @State private var wildFlash: Double   = 0

    private let uiTint          = Color(red: 0.93, green: 0.88, blue: 0.99)
    private let uiTintSecondary = Color(red: 0.86, green: 0.93, blue: 0.99)
    private let uiInk           = Color(red: 0.24, green: 0.20, blue: 0.49)

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
                    scoreBar.padding(.horizontal, 26)

                    BoardView(vm: vm)
                        .padding(.horizontal, 8)
                        .padding()
                        .offset(x: bombShake)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(red: 1, green: 0.93, blue: 0.3).opacity(hintFlash))
                                .allowsHitTesting(false)
                                .padding(.horizontal, 8).padding()
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(red: 0.72, green: 0.4, blue: 1.0).opacity(wildFlash))
                                .allowsHitTesting(false)
                                .padding(.horizontal, 8).padding()
                        )
                        .scaleEffect(shuffleBounce)
                }
                .padding(.horizontal)
                .padding(.top)

                if vm.showBoardFullWarning {
                    stuckBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 30)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: vm.showBoardFullWarning)
                }

                actionBar
                    .padding(.horizontal, 26)
                    .padding(.bottom, 40)
            }

            if vm.showEmptyBoardEffect {
                BoardClearedCelebration()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            if vm.isGameOver {
                gameOverOverlay
            }
        }
        .onAppear { audio.play() }
        .onChange(of: vm.powerUpAnimation) { _, anim in
            guard let anim else { return }
            switch anim {
            case .hint:    playHintAnimation()
            case .shuffle: playShuffleAnimation()
            case .bomb:    playBombAnimation()
            case .wild:    playWildAnimation()
            }
        }
        .sheet(isPresented: $showShop, onDismiss: { vm.syncFromDefaults() }) {
            ShopView()
        }
        .confirmationDialog("Restart game?", isPresented: $showRestartAlert, titleVisibility: .visible) {
            Button("Restart", role: .destructive) { withAnimation { vm.startNewGame() } }
            Button("Return to Menu", role: .destructive) { onReturnToMenu() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your current progress will be lost.")
        }
        .sheet(isPresented: $showBuyHintSheet) {
            BuyChargeSheet(
                title: "Buy Hints", icon: "lightbulb.fill",
                iconColor: Color(red: 1, green: 0.78, blue: 0.1),
                singleCost: vm.hintCost, coins: vm.coins
            ) { vm.shopBuyHints(count: 1) }
            .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showBuyShuffleSheet) {
            BuyChargeSheet(
                title: "Buy Shuffles", icon: "shuffle",
                iconColor: Color(red: 0.2, green: 0.6, blue: 1),
                singleCost: vm.shuffleCost, coins: vm.coins
            ) { vm.shopBuyShuffles(count: 1) }
            .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showBuyBombSheet) {
            BuyChargeSheet(
                title: "Buy Bombs", icon: "burst.fill",
                iconColor: Color(red: 1, green: 0.35, blue: 0.25),
                singleCost: vm.bombCost, coins: vm.coins
            ) { vm.shopBuyBombs(count: 1) }
            .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showBuyWildSheet) {
            BuyChargeSheet(
                title: "Buy Wilds", icon: "wand.and.stars",
                iconColor: Color(red: 0.55, green: 0.25, blue: 0.95),
                singleCost: vm.wildCost, coins: vm.coins
            ) { vm.shopBuyWilds(count: 1) }
            .presentationDetents([.height(300)])
        }
    }

    // MARK: - Animations

    private func playHintAnimation() {
        withAnimation(.easeIn(duration: 0.15))       { hintFlash = 0.55 }
        withAnimation(.easeOut(duration: 0.35).delay(0.15)) { hintFlash = 0 }
    }

    private func playShuffleAnimation() {
        withAnimation(.spring(response: 0.18, dampingFraction: 0.35)) { shuffleBounce = 1.06 }
        withAnimation(.spring(response: 0.30, dampingFraction: 0.55).delay(0.18)) { shuffleBounce = 1.0 }
    }

    private func playBombAnimation() {
        let seq: [CGFloat] = [10, -10, 8, -8, 5, -5, 0]
        var delay: Double = 0
        for offset in seq {
            withAnimation(.easeInOut(duration: 0.07).delay(delay)) { bombShake = offset }
            delay += 0.07
        }
    }

    private func playWildAnimation() {
        withAnimation(.easeIn(duration: 0.12))        { wildFlash = 0.5 }
        withAnimation(.easeOut(duration: 0.4).delay(0.12)) { wildFlash = 0 }
    }

    // MARK: - Views

    private var dreamyBackground: some View {
        Image("Quibly Background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            circleButton(system: "arrow.left") { showRestartAlert = true }
            Spacer()
            circleButton(system: "cart.fill") { showShop = true }
            circleButton(system: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill") {
                audio.toggleMute()
            }
        }
        .padding(.top, 12)
    }

    private var scoreBar: some View {
        HStack(spacing: 16) {
            scoreStat(label: "Score", value: "\(vm.score)")
            Divider().overlay(uiInk.opacity(0.25))
            scoreStat(label: "Best",  value: "\(vm.bestScore)")
            Divider().overlay(uiInk.opacity(0.25))
            scoreStat(label: "Coins", value: "\(vm.coins)")
        }
        .frame(height: 50)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(uiTint.opacity(0.88))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.6), lineWidth: 1))
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

    private var stuckBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(Color(red: 1, green: 0.75, blue: 0.1))
            Text("Stuck? Try Shuffle or Bomb to clear tiles!")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(uiInk)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(uiTint.opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.6), lineWidth: 1))
        )
    }

    // MARK: - 2×2 Action Grid

    private var actionBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                bombPill
                shufflePill
            }
            HStack(spacing: 10) {
                hintPill
                wildPill
            }
        }
    }

    private var bombPill: some View {
        actionPill(
            title: "Bomb",
            subtitle: vm.bombCharges > 0 ? "💣 \(vm.bombCharges)" : "\(vm.bombCost)🪙",
            icon: "burst.fill",
            isArmed: vm.isBombArmed,
            armedColor: Color(red: 1, green: 0.35, blue: 0.25),
            enabled: vm.canUseBomb || vm.canAffordBomb
        ) {
            if vm.bombCharges > 0 { vm.toggleBombArm() } else { showBuyBombSheet = true }
        }
    }

    private var shufflePill: some View {
        actionPill(
            title: "Shuffle",
            subtitle: vm.shuffleCharges > 0 ? "🔀 \(vm.shuffleCharges)" : "\(vm.shuffleCost)🪙",
            icon: "shuffle",
            isArmed: false,
            armedColor: .clear,
            enabled: vm.canUseShuffle
        ) {
            if vm.shuffleCharges > 0 || vm.coins >= vm.shuffleCost { vm.shuffleBoard() }
            else { showBuyShuffleSheet = true }
        }
    }

    private var hintPill: some View {
        actionPill(
            title: "Hint",
            subtitle: vm.hintCharges > 0 ? "💡 \(vm.hintCharges)" : "\(vm.hintCost)🪙",
            icon: "lightbulb.fill",
            isArmed: false,
            armedColor: .clear,
            enabled: vm.canUseHintButton,
            isPulsing: vm.showHintButton && vm.hintCharges > 0
        ) {
            if vm.hintCharges > 0 {
                if !vm.pendingSwipeMatches.isEmpty { vm.usePowerUpHint() }
            } else if vm.coins >= vm.hintCost {
                vm.shopBuyHints(count: 1)
            } else {
                showBuyHintSheet = true
            }
        }
    }

    private var wildPill: some View {
        actionPill(
            title: "Wild",
            subtitle: vm.wildCharges > 0 ? "⭐ \(vm.wildCharges)" : "\(vm.wildCost)🪙",
            icon: "wand.and.stars",
            isArmed: vm.isWildArmed,
            armedColor: Color(red: 0.55, green: 0.25, blue: 0.95),
            enabled: vm.canUseWild || vm.canAffordWild
        ) {
            if vm.wildCharges > 0 { vm.toggleWildArm() } else { showBuyWildSheet = true }
        }
    }

    private func actionPill(
        title: String,
        subtitle: String,
        icon: String,
        isArmed: Bool,
        armedColor: Color,
        enabled: Bool,
        isPulsing: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isArmed ? armedColor.opacity(0.9) : uiTintSecondary.opacity(0.96))
                        .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
                        .frame(width: 44, height: 44)

                    if isPulsing {
                        Circle()
                            .stroke(Color(red: 1, green: 0.78, blue: 0.1), lineWidth: 2.5)
                            .frame(width: 44, height: 44)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isArmed ? .white : uiInk)
                }

                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.56, green: 0.36, blue: 0.08))
            }
            .foregroundColor(uiInk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isArmed ? armedColor.opacity(0.15) : uiTint.opacity(0.8))
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

                Button("Play Again") { withAnimation { vm.startNewGame() } }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .padding(.horizontal, 24).padding(.vertical, 10)
                    .background(Capsule().fill(Color.white.opacity(0.18)))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(RoundedRectangle(cornerRadius: 22).fill(Color.black.opacity(0.35)))
        }
    }
}

// MARK: - Board Cleared Celebration

private struct BoardClearedCelebration: View {
    @State private var burst   = false
    @State private var textIn  = false
    @State private var textOut = false

    private let particles: [(angle: Double, icon: String, color: Color, size: CGFloat)] = [
        (0,   "star.fill",     .yellow,  16), (30,  "sparkle",       .pink,    12),
        (60,  "star.fill",     .cyan,    14), (90,  "sparkle",       .green,   16),
        (120, "star.fill",     .orange,  12), (150, "sparkle",       .purple,  14),
        (180, "star.fill",     .yellow,  12), (210, "sparkle",       .pink,    16),
        (240, "star.fill",     .cyan,    12), (270, "sparkle",       .green,   14),
        (300, "star.fill",     .orange,  16), (330, "sparkle",       .purple,  12),
        (15,  "circle.fill",   .white,   8),  (75,  "circle.fill",   .yellow,  6),
        (135, "circle.fill",   .pink,    8),  (195, "circle.fill",   .cyan,    6),
        (255, "circle.fill",   .white,   8),  (315, "circle.fill",   .orange,  6),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.18).ignoresSafeArea()

            ForEach(Array(particles.enumerated()), id: \.offset) { i, p in
                let rad = p.angle * .pi / 180
                Image(systemName: p.icon)
                    .font(.system(size: burst ? p.size * 0.4 : p.size))
                    .foregroundColor(p.color)
                    .opacity(burst ? 0 : 1)
                    .offset(
                        x: burst ? CGFloat(cos(rad)) * 220 : 0,
                        y: burst ? CGFloat(sin(rad)) * 260 : 0
                    )
                    .animation(
                        .easeOut(duration: 0.85).delay(Double(i) * 0.025),
                        value: burst
                    )
            }

            VStack(spacing: 6) {
                Text("✨ Board Cleared! ✨")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)
                Text("Amazing!")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 1, green: 0.90, blue: 0.35))
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .scaleEffect(textIn ? (textOut ? 0.7 : 1.0) : 0.4)
            .opacity(textIn ? (textOut ? 0 : 1) : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.55), value: textIn)
            .animation(.easeOut(duration: 0.4), value: textOut)
        }
        .onAppear {
            withAnimation { textIn = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { burst = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1)  { withAnimation { textOut = true } }
        }
    }
}

// MARK: - Quick Buy Sheet

struct BuyChargeSheet: View {
    let title: String
    let icon: String
    let iconColor: Color
    let singleCost: Int
    let coins: Int
    let onBuy: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let uiInk = Color(red: 0.24, green: 0.20, blue: 0.49)

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            Image(systemName: icon)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(iconColor)

            Text(title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(uiInk)

            HStack(spacing: 6) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundColor(Color(red: 1, green: 0.72, blue: 0.3))
                Text("You have \(coins) coins")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Button {
                onBuy()
                dismiss()
            } label: {
                Text("Buy 1 for \(singleCost) coins")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(coins >= singleCost ? Color(red: 0.25, green: 0.55, blue: 1.0) : Color.gray)
                    )
                    .padding(.horizontal, 24)
            }
            .disabled(coins < singleCost)

            if coins < singleCost {
                Text("Not enough coins. Visit the Shop to get more!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()
        }
    }
}

import SwiftUI

struct GameView: View {
    let settings: GameSettings
    let onReturnToMenu: () -> Void

    @StateObject private var vm: GameViewModel
    @EnvironmentObject private var audio: AudioManager
    @ObservedObject private var adManager = AdManager.shared

    @State private var showPausePopup    = false
    @State private var showGameOverPopup = false
    @State private var showShop          = false
    @State private var showBuyHintSheet  = false
    @State private var showBuyShuffleSheet = false
    @State private var showBuyBombSheet  = false
    @State private var showBuyWildSheet  = false

    // Power-up animation states
    @State private var shuffleBounce: CGFloat = 1.0
    @State private var hintFlash: Double      = 0
    @State private var bombShake: CGFloat     = 0
    @State private var wildFlash: Double      = 0

    init(settings: GameSettings, onReturnToMenu: @escaping () -> Void) {
        self.settings = settings
        self.onReturnToMenu = onReturnToMenu
        _vm = StateObject(wrappedValue: GameViewModel(settings: settings))
    }

    var body: some View {
        mainGameView
            .ignoresSafeArea(edges: .top)
        .onAppear {
            audio.play()
            AdManager.shared.showBanner()
        }
        .onDisappear {
            AdManager.shared.hideBanner()
        }
        .onChange(of: vm.powerUpAnimation) {anim in
            guard let anim else { return }
            switch anim {
            case .hint:    playHintAnimation()
            case .shuffle: playShuffleAnimation()
            case .bomb:    playBombAnimation()
            case .wild:    playWildAnimation()
            }
        }
        .fullScreenCover(isPresented: $showShop, onDismiss: { vm.syncFromDefaults() }) { ShopView(onBack: { showShop = false }) }
        .sheet(isPresented: $showBuyHintSheet, onDismiss: { vm.resumeNoWordTimer() }) {
            BuyChargePopupSheet(
                powerUpName: "Hint", icon: "lightbulb.fill",
                iconGradient: [Color.qSun1, Color.qSun2],
                singleCost: vm.hintCost, tripleCost: vm.hintCost * 3, coins: vm.coins
            ) { count in vm.shopBuyHints(count: count) }
            .presentationDetents([.height(360)])
        }
        .sheet(isPresented: $showBuyShuffleSheet, onDismiss: { vm.resumeNoWordTimer() }) {
            BuyChargePopupSheet(
                powerUpName: "Shuffle", icon: "shuffle",
                iconGradient: [Color.qSky1, Color.qSky2],
                singleCost: vm.shuffleCost, tripleCost: vm.shuffleCost * 3, coins: vm.coins
            ) { count in vm.shopBuyShuffles(count: count) }
            .presentationDetents([.height(360)])
        }
        .sheet(isPresented: $showBuyBombSheet, onDismiss: { vm.resumeNoWordTimer() }) {
            BuyChargePopupSheet(
                powerUpName: "Bomb", icon: "burst.fill",
                iconGradient: [Color.qCoral1, Color.qCoral2],
                singleCost: vm.bombCost, tripleCost: vm.bombCost * 3, coins: vm.coins
            ) { count in vm.shopBuyBombs(count: count) }
            .presentationDetents([.height(360)])
        }
        .sheet(isPresented: $showBuyWildSheet, onDismiss: { vm.resumeNoWordTimer() }) {
            BuyChargePopupSheet(
                powerUpName: "Joker", icon: "wand.and.stars",
                iconGradient: [Color.qGrape1, Color.qGrape2],
                singleCost: vm.wildCost, tripleCost: vm.wildCost * 3, coins: vm.coins
            ) { count in vm.shopBuyWilds(count: count) }
            .presentationDetents([.height(360)])
        }
        .onChange(of: showShop)            { showing in
            if showing { vm.cancelNoWordTimer() }
            showing ? AdManager.shared.hideBanner() : AdManager.shared.showBanner()
        }
        .onChange(of: showPausePopup)      { showing in
            showing ? AdManager.shared.hideBanner() : AdManager.shared.showBanner()
        }
        .onChange(of: showGameOverPopup)   { showing in
            if showing { AdManager.shared.hideBanner() }
        }
        .onChange(of: showBuyHintSheet)    {showing in if showing { vm.pauseNoWordTimer() } }
        .onChange(of: showBuyShuffleSheet) {showing in if showing { vm.pauseNoWordTimer() } }
        .onChange(of: showBuyBombSheet)    {showing in if showing { vm.pauseNoWordTimer() } }
        .onChange(of: showBuyWildSheet)    {showing in if showing { vm.pauseNoWordTimer() } }
        .onChange(of: vm.noWordCountdown)  {countdown in
            if countdown == 10 {
                audio.playCountdownSound()
            } else if countdown == nil {
                audio.fadeOutCountdownSound()
            }
        }
    }

    // MARK: - Main Game View

    private var mainGameView: some View {
        DreamBackground {
            ZStack {
                mainColumn
                    .padding(.bottom, adManager.isBannerVisible ? 50 : 0)

                if let countdown = vm.noWordCountdown {
                    noWordCountdownBanner(seconds: countdown)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: countdown)
                }

                // Score milestone toast
                if vm.isNewPersonalBest && !vm.isGameOver {
                    PersonalBestBanner()
                        .allowsHitTesting(false)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                if let milestone = vm.currentMilestone {
                    MilestoneToast(points: milestone)
                        .id(milestone)
                        .allowsHitTesting(false)
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                // Board cleared celebration
                if vm.showEmptyBoardEffect {
                    BoardClearedCelebration()
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }

                // Game over popup
                if vm.isGameOver && !showGameOverPopup {
                    Color.clear
                        .onAppear { withAnimation { showGameOverPopup = true } }
                }
                if showGameOverPopup {
                    GameOverPopup(
                        score: vm.score,
                        words: vm.wordsFoundThisSession,
                        bestCombo: vm.comboCount,
                        currentStreak: StreakManager.shared.currentStreak,
                        streakJustExtended: vm.streakExtendedThisSession,
                        onMenu: {
                            showGameOverPopup = false
                            onReturnToMenu()
                        },
                        onPlayAgain: {
                            showGameOverPopup = false
                            withAnimation { vm.startNewGame() }
                        }
                    )
                    .transition(.opacity)
                }

                // Pause popup
                if showPausePopup {
                    PausePopup(
                        onResume:  { showPausePopup = false },
                        onRestart: { showPausePopup = false; withAnimation { vm.startNewGame() } },
                        onMenu:    { showPausePopup = false; onReturnToMenu() }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: showPausePopup)
            .animation(.easeOut(duration: 0.2), value: showGameOverPopup)
            .animation(.easeInOut(duration: 0.25), value: vm.comboCount > 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: vm.currentMilestone)
            .animation(.easeInOut(duration: 0.35), value: vm.isNewPersonalBest)
        }
        .overlay(alignment: .bottom) {
            if adManager.isBannerVisible {
                BannerAdView(adUnitID: AdManager.AdUnitID.banner)
                    .frame(height: 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: adManager.isBannerVisible)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack{
            HStack(spacing: 8) {
                QCircleButton(size: 40, action: { showPausePopup = true }) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.qInk)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    QCircleButton(size: 36, action: { showShop = true }) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.qInk)
                    }
                    QCircleButton(size: 36, action: { audio.toggleMute() }) {
                        Image(systemName: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.qInk)
                    }
                }
            }
            
            if settings.gameMode == .blitz || settings.gameMode == .daily || settings.gameMode == .swipeLimited {
                modePill
            }
        }
    }

    // MARK: - Mode Pill

    private var modePill: some View {
        let blitzUrgent = settings.gameMode == .blitz && vm.timeRemaining <= 15
        let sprintUrgent = settings.gameMode == .swipeLimited && vm.swipesRemaining <= 5
        let urgent = blitzUrgent || sprintUrgent
        return HStack(spacing: 6) {
            switch settings.gameMode {
            case .classic:
                EmptyView()
            case .blitz:
                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(urgent ? Color.qCoral2 : Color.qInk)
                Text(String(format: "%d:%02d", vm.timeRemaining / 60, vm.timeRemaining % 60))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(urgent ? Color.qCoral2 : Color.qInk)
            case .zen:
                EmptyView()
            case .daily:
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.qSun2)
                Text("TODAY")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qSun2)
            case .swipeLimited:
                Image(systemName: "arrow.trianglehead.2.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(urgent ? Color.qCoral2 : Color.qInk)
                Text("\(vm.swipesRemaining)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(urgent ? Color.qCoral2 : Color.qInk)
                Text("left")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(urgent ? Color.qCoral2.opacity(0.8) : Color.qInk.opacity(0.65))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 5)
        .background(
            Capsule()
                .fill(urgent ? Color.qCoral1.opacity(0.2) : Color.white.opacity(0.55))
                .overlay(Capsule().stroke(urgent ? Color.qCoral1.opacity(0.5) : Color.white.opacity(0.85), lineWidth: 1))
        )
        .animation(.easeInOut(duration: 0.3), value: urgent)
    }

    // MARK: - Score Header

    private var scoreHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                scoreColumn(label: "Score", value: "\(vm.score)")
                Divider()
                    .overlay(Color.qInk.opacity(0.18))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                scoreColumn(label: "Best", value: "\(vm.bestScore)")
                Divider()
                    .overlay(Color.qInk.opacity(0.18))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                HStack(spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Coins")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.qInkSoft)
                            .tracking(0.6)
                            .textCase(.uppercase)
                        CoinChip(amount: vm.coins)
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            // XP progress bar
            XPBarView()
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .qCard(cornerRadius: 22)
    }

    private func scoreColumn(label: LocalizedStringKey, value: String, large: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.qInkSoft)
                .tracking(0.6)
                .textCase(.uppercase)
            Text(value)
                .font(.system(size: large ? 28 : 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.qInk)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Combo Ribbon

    private var comboRibbon: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
            Text("COMBO ×\(vm.comboCount + 1)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0.71, green: 0.27, blue: 0).opacity(0.5), radius: 0, x: 0, y: 1)
        }
        .padding(.horizontal, 14).padding(.vertical, 5)
        .background(
            Capsule()
                .fill(LinearGradient(
                    colors: [Color.qSun1, Color.qSun2],
                    startPoint: .top, endPoint: .bottom
                ))
                .overlay(Capsule().stroke(Color.white.opacity(0.45), lineWidth: 1))
                .shadow(color: Color(red: 0.71, green: 0.27, blue: 0).opacity(0.4), radius: 0, x: 0, y: 3)
        )
        .wiggle(active: true)
    }

    // MARK: - Stuck Banner

    private var stuckBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Color.qSun2)
            Text("Stuck? Try Shuffle or Bomb to clear tiles!")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.qInk)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .qCard(cornerRadius: 14)
    }

    private func noWordCountdownBanner(seconds: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.red)
            Text("Swipe or act — game over in \(seconds)s!")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.qInk)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.12))
        .qCard(cornerRadius: 14)
    }

    // MARK: - Power-up Bar

    private var powerUpBar: some View {
        HStack(spacing: 8) {
            puButton(
                label: "Hint",
                icon: "lightbulb.fill",
                gradient: [Color.qSun1, Color.qSun2],
                charges: vm.hintCharges,
                cost: vm.hintCost,
                armed: false,
                pulsing: vm.showHintButton && vm.hintCharges > 0,
                enabled: vm.canUseHintButton
            ) {
                if vm.hintCharges > 0 {
                    if !vm.pendingSwipeMatches.isEmpty { vm.usePowerUpHint() }
                } else { showBuyHintSheet = true }
            }

            puButton(
                label: "Shuffle",
                icon: "shuffle",
                gradient: [Color.qSky1, Color.qSky2],
                charges: vm.shuffleCharges,
                cost: vm.shuffleCost,
                armed: false,
                pulsing: false,
                enabled: vm.canUseShuffle
            ) {
                if vm.shuffleCharges > 0 || vm.coins >= vm.shuffleCost { vm.shuffleBoard() }
                else { showBuyShuffleSheet = true }
            }

            puButton(
                label: "Joker",
                icon: "wand.and.stars",
                gradient: [Color.qGrape1, Color.qGrape2],
                charges: vm.wildCharges,
                cost: vm.wildCost,
                armed: vm.isWildArmed,
                pulsing: false,
                enabled: vm.canUseWild || vm.canAffordWild
            ) {
                if vm.wildCharges > 0 { vm.toggleWildArm() }
                else { showBuyWildSheet = true }
            }

            puButton(
                label: "Bomb",
                icon: "burst.fill",
                gradient: [Color.qCoral1, Color.qCoral2],
                charges: vm.bombCharges,
                cost: vm.bombCost,
                armed: vm.isBombArmed,
                pulsing: false,
                enabled: vm.canUseBomb || vm.canAffordBomb
            ) {
                if vm.bombCharges > 0 { vm.toggleBombArm() }
                else { showBuyBombSheet = true }
            }
        }
        .padding(8)
        .qCard(cornerRadius: 22)
    }

    private func puButton(
        label: LocalizedStringKey,
        icon: String,
        gradient: [Color],
        charges: Int,
        cost: Int,
        armed: Bool,
        pulsing: Bool,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let hasCharge = charges > 0
        return Button(action: action) {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(hasCharge
                            ? LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.white.opacity(0.5), Color.white.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                        )
                        .overlay(
                            Circle().stroke(Color.white.opacity(pulsing ? 0.9 : 0.55), lineWidth: pulsing ? 2.5 : 1)
                        )
                        .shadow(color: (hasCharge ? gradient.last ?? Color.clear : Color.clear).opacity(0.4), radius: 0, x: 0, y: 3)
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(hasCharge ? Color.white : Color.qInk.opacity(0.5))
                }

                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(hasCharge ? Color.white : Color.qInk.opacity(0.55))
                    .shadow(color: Color.qInk.opacity(hasCharge ? 0.4 : 0), radius: 0, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(hasCharge
                        ? LinearGradient(colors: gradient.map { $0.opacity(0.9) }, startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color(red: 0.86, green: 0.82, blue: 0.94).opacity(0.7), Color(red: 0.86, green: 0.82, blue: 0.94).opacity(0.55)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(armed ? 0.9 : 0.55), lineWidth: armed ? 2 : 1)
                    )
                    .shadow(color: Color.qInk.opacity(hasCharge ? 0.25 : 0.1), radius: 0, x: 0, y: 3)
            )
            .overlay(alignment: .topTrailing) {
                if hasCharge {
                    Text("×\(charges)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.qInk)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Capsule().fill(Color.white).shadow(color: Color.qInk.opacity(0.25), radius: 0, x: 0, y: 2))
                        .offset(x: 4, y: -4)
                } else {
                    HStack(spacing: 3) {
                        ZStack {
                            Circle()
                                .fill(RadialGradient(colors: [Color(red: 1, green: 0.96, blue: 0.7), Color(red: 0.94, green: 0.64, blue: 0.13)], center: .topLeading, startRadius: 0, endRadius: 8))
                            Text("$")
                                .font(.system(size: 6, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 0.71, green: 0.43, blue: 0))
                        }
                        .frame(width: 10, height: 10)
                        Text("\(cost)")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.qGoldDeep)
                    }
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [Color(red: 1, green: 0.97, blue: 0.85), Color(red: 1, green: 0.89, blue: 0.60)], startPoint: .top, endPoint: .bottom))
                            .shadow(color: Color(red: 0.71, green: 0.43, blue: 0).opacity(0.25), radius: 0, x: 0, y: 2)
                    )
                    .offset(x: 4, y: -4)
                }
            }
            .overlay(alignment: .bottom) {
                if armed {
                    Text("ARMED")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.qCoral2).shadow(color: Color(red: 0.63, green: 0.12, blue: 0).opacity(0.4), radius: 0, x: 0, y: 2))
                        .offset(y: 10)
                }
            }
            .wiggle(active: armed)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.6)
    }

    // MARK: - Animation Helpers

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

    // MARK: - Board Area

    private var boardArea: some View {
        BoardView(vm: vm)
            .padding(.horizontal, 12)
            .padding()
            .offset(x: bombShake)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.qSun1.opacity(hintFlash))
                    .allowsHitTesting(false)
                    .padding(.horizontal, 12).padding()
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.qGrape2.opacity(wildFlash))
                    .allowsHitTesting(false)
                    .padding(.horizontal, 12).padding()
            )
            .scaleEffect(shuffleBounce)
    }

    // MARK: - Main Column

    @ViewBuilder
    private var mainColumn: some View {
        VStack(spacing: 20) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 56)
                .padding(.bottom, 8)
            
            Spacer()
                .frame(height: 140)
            
            scoreHeader
                .padding(.horizontal, 18)
                .padding(.bottom, 6)
                .padding(.horizontal)
                .frame(height: 50)

            if vm.comboCount > 0 {
                comboRibbon
                    .padding(.bottom, 4)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }

            boardArea

            if vm.showBoardFullWarning {
                stuckBanner
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: vm.showBoardFullWarning)
            }

            powerUpBar
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
                .padding(.horizontal)
        }
    }
}

// MARK: - Milestone Toast

struct MilestoneToast: View {
    let points: Int
    @State private var visible = false

    private var label: String {
        points >= 1_000 ? "\(points / 1_000)K pts!" : "\(points) pts!"
    }

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.qGoldDeep)
                Text(label)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.qGoldDeep)
                Image(systemName: "star.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.qSun2)
            }
            .padding(.horizontal, 18).padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color(red: 1, green: 0.97, blue: 0.85), Color.qSun1],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .overlay(Capsule().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
                    .shadow(color: Color(red: 0.71, green: 0.43, blue: 0).opacity(0.45), radius: 0, x: 0, y: 4)
                    .shadow(color: Color(red: 0.71, green: 0.43, blue: 0).opacity(0.2), radius: 10, x: 0, y: 6)
            )
            .scaleEffect(visible ? 1.0 : 0.6)
            .opacity(visible ? 1.0 : 0)
        }
        .padding(.bottom, 100)
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.58)) { visible = true }
        }
    }
}

// MARK: - Personal Best Banner

struct PersonalBestBanner: View {
    @State private var visible = false

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.qGoldDeep)
                Text("New Personal Best!")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.qGoldDeep)
            }
            .padding(.horizontal, 18).padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color(red: 1, green: 0.97, blue: 0.85), Color.qSun1],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .overlay(Capsule().stroke(Color.white.opacity(0.8), lineWidth: 1.5))
                    .shadow(color: Color(red: 0.71, green: 0.43, blue: 0).opacity(0.45), radius: 0, x: 0, y: 4)
            )
            .offset(y: visible ? 0 : -60)
            .opacity(visible ? 1.0 : 0)

            Spacer()
        }
        .padding(.top, 60)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) { visible = true }
        }
    }
}

// MARK: - Board Cleared Celebration

struct BoardClearedCelebration: View {
    @State private var burst   = false
    @State private var textIn  = false
    @State private var textOut = false

    private let particles: [(angle: Double, icon: String, color: Color, size: CGFloat)] = [
        (0,   "star.fill",   .yellow, 16), (30,  "sparkle",     .pink,   12),
        (60,  "star.fill",   .cyan,   14), (90,  "sparkle",     .green,  16),
        (120, "star.fill",   .orange, 12), (150, "sparkle",     .purple, 14),
        (180, "star.fill",   .yellow, 12), (210, "sparkle",     .pink,   16),
        (240, "star.fill",   .cyan,   12), (270, "sparkle",     .green,  14),
        (300, "star.fill",   .orange, 16), (330, "sparkle",     .purple, 12),
        (15,  "circle.fill", .white,   8), (75,  "circle.fill", .yellow,  6),
        (135, "circle.fill", .pink,    8), (195, "circle.fill", .cyan,    6),
        (255, "circle.fill", .white,   8), (315, "circle.fill", .orange,  6),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.20).ignoresSafeArea()

            ForEach(Array(particles.enumerated()), id: \.offset) { i, p in
                let rad = p.angle * .pi / 180
                Image(systemName: p.icon)
                    .font(.system(size: burst ? p.size * 0.4 : p.size))
                    .foregroundStyle(p.color)
                    .opacity(burst ? 0 : 1)
                    .offset(
                        x: burst ? CGFloat(cos(rad)) * 220 : 0,
                        y: burst ? CGFloat(sin(rad)) * 260 : 0
                    )
                    .animation(.easeOut(duration: 0.85).delay(Double(i) * 0.025), value: burst)
            }

            VStack(spacing: 8) {
                Text("✨ Board Cleared! ✨")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.qInk.opacity(0.5), radius: 6, x: 0, y: 3)
                Text("Amazing!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.qSun1)
                    .shadow(color: Color(red: 0.71, green: 0.43, blue: 0).opacity(0.5), radius: 0, x: 0, y: 2)

                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [Color(red: 1, green: 0.96, blue: 0.7), Color(red: 0.94, green: 0.64, blue: 0.13)], center: .topLeading, startRadius: 0, endRadius: 10))
                        Text("$")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.71, green: 0.43, blue: 0))
                    }
                    .frame(width: 16, height: 16)
                    Text("+50 bonus coins")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.qInk)
                }
                .padding(.horizontal, 16).padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.95))
                        .shadow(color: Color.qInk.opacity(0.25), radius: 0, x: 0, y: 4)
                )
                .padding(.top, 4)
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


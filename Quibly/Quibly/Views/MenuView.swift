import SwiftUI

struct MenuView: View {
    var onStart: (GameSettings) -> Void

    @EnvironmentObject private var audio: AudioManager
    @AppStorage("SlideWords_BestScore")         private var bestScore: Int    = 0
    @AppStorage("SlideWords_Coins")             private var coins: Int        = 125
    @AppStorage("SlideWords_Streak")            private var streak: Int       = 7
    @AppStorage("SlideWords_SelectedLanguage")  private var selectedLanguageRawValue: String = GameLanguage.english.rawValue
    @AppStorage("SlideWords_SelectedVariant")   private var selectedVariantRawValue:  Int    = BoardVariant.small.rawValue

    @State private var selectedLanguage: GameLanguage = .english
    @State private var selectedVariant:  BoardVariant = .small
    @State private var showShop      = false
    @State private var showModes     = false
    @State private var showSettings  = false
    @State private var showProfile   = false
    @State private var showDaily     = false
    @State private var showQuests    = false
    @State private var showLocked    = false

    private let previewLetters: [[String]] = [
        ["Q","U","I","B"],
        ["L","P","A","R"],
        ["E","L","A","Y"],
        ["W","O","R","D"]
    ]

    var body: some View {
        NavigationView{
            DreamBackground {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    
                    ZStack(alignment: .top) {
                        // Board preview
                        VStack(spacing: 20){
                            Spacer()
                                .frame(height: 250)
                            // Stats row
                            HStack(spacing: 8) {
                                QStatChip(
                                    icon: "trophy.fill", iconColor: Color(red: 0.48, green: 0.27, blue: 0),
                                    label: "Best", value: "\(bestScore)",
                                    gradient: [Color(red: 1, green: 0.96, blue: 0.83), Color(red: 1, green: 0.85, blue: 0.48)]
                                )
                                QStatChip(
                                    icon: "flame.fill", iconColor: Color(red: 0.66, green: 0.24, blue: 0),
                                    label: "Streak", value: "\(streak)d",
                                    gradient: [Color(red: 1, green: 0.85, blue: 0.77), Color(red: 1, green: 0.67, blue: 0.48)]
                                )
                                QStatChip(
                                    icon: "circle.fill", iconColor: Color(red: 0.94, green: 0.65, blue: 0.13),
                                    label: "Coins", value: "\(coins)",
                                    gradient: [Color(red: 1, green: 0.97, blue: 0.85), Color(red: 1, green: 0.89, blue: 0.60)]
                                )
                            }
                            .padding(.horizontal, 30)
                            
                            boardPreview
                            
                            // Play button + mode chip
                            Button(action: startGame) {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Color.qGoldDeep)
                                    Text("PLAY")
                                        .font(.system(size: 26, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.qGoldDeep)
                                }
                            }
                            .frame(width: 240)
                            .buttonStyle(PuffyButtonStyle(variant: .gold))
                            
                            Button { showModes = true } label: {
                                HStack(spacing: 8) {
                                    Text("Mode").opacity(0.7)
                                    Text("\(selectedLanguage.flag) \(selectedVariant.label)")
                                        .fontWeight(.semibold)
                                    Text("›").opacity(0.6)
                                }
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.qInk)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.55))
                                        .overlay(Capsule().stroke(Color.white.opacity(0.85), lineWidth: 1))
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Bottom nav
                            bottomNav
                                .padding(.horizontal, 16)
                                .padding(.horizontal)
                                .padding(.bottom, geo.safeAreaInsets.bottom + 8)
                                .frame(maxWidth: .infinity)
                        }

                        // Custom top bar — avoids iOS 26 automatic glass bubble treatment on toolbar items
                        HStack(alignment: .center) {
                            profileChip
                            Spacer()
                            HStack(spacing: 8) {
                                dailyButton
                                menuToolbarButton(action: { showSettings = true }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color.qInk)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, geo.safeAreaInsets.top + 8)

                    }
                    .ignoresSafeArea(edges: .top)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                audio.play()
                selectedLanguage = GameLanguage(rawValue: selectedLanguageRawValue) ?? .english
                selectedVariant  = BoardVariant(rawValue: selectedVariantRawValue)  ?? .small
            }
            .onChange(of: selectedLanguage) { _, v in selectedLanguageRawValue = v.rawValue }
            .onChange(of: selectedVariant)  { _, v in selectedVariantRawValue  = v.rawValue }
            .fullScreenCover(isPresented: $showShop)     { ShopView(onBack: { showShop = false }) }
            .fullScreenCover(isPresented: $showModes)    {
                ModesView(
                    selectedLanguage: $selectedLanguage,
                    selectedVariant: $selectedVariant,
                    onBack: { showModes = false },
                    onStart: { settings in showModes = false; onStart(settings) }
                )
            }
            .fullScreenCover(isPresented: $showSettings) { SettingsView(onBack: { showSettings = false }) }
            .sheet(isPresented: $showProfile)  { ProfilePopupSheet() }
            .sheet(isPresented: $showDaily)    { DailyRewardPopupSheet() }
            .sheet(isPresented: $showQuests)   { QuestsPopupSheet() }
            .sheet(isPresented: $showLocked)   { LockedPopupSheet() }
        }
    }

    // MARK: - Profile Chip

    private var profileChip: some View {
        Button { showProfile = true } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.qBubble1, Color.qGrape1],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .shadow(color: Color.qInk.opacity(0.35), radius: 0, x: 0, y: 3)
                    Text("R")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 1) {
                    Text("LVL 12")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .tracking(0.6)
                    Text("Riley")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: Color.qInk.opacity(0.4), radius: 0, x: 0, y: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Daily Button

    private var dailyButton: some View {
        Button { showDaily = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 13, weight: .bold))
                Text("Daily")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color(red: 1, green: 0.70, blue: 0.85),
                                 Color(red: 1, green: 0.44, blue: 0.68)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .overlay(Capsule().stroke(Color.white.opacity(0.55), lineWidth: 1))
                    .shadow(color: Color(red: 0.63, green: 0.12, blue: 0.35).opacity(0.4), radius: 0, x: 0, y: 3)
            )
            .overlay(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(Color.qSun1)
                        .shadow(color: Color(red: 0.71, green: 0.43, blue: 0).opacity(0.4), radius: 0, x: 0, y: 2)
                    Text("3")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.qGoldDeep)
                }
                .frame(width: 18, height: 18)
                .offset(x: 6, y: -6)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar Icon Button

    private func menuToolbarButton<Content: View>(action: @escaping () -> Void, @ViewBuilder label: () -> Content) -> some View {
        Button(action: action) {
            label()
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.5))
                        .shadow(color: Color.qInk.opacity(0.18), radius: 0, x: 0, y: 3)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Board Preview

    private var boardPreview: some View {
        VStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { r in
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { c in
                        let letter = previewLetters[r][c]
                        let hl = isHighlighted(row: r, col: c)
                        previewTile(letter: letter, highlighted: hl)
                    }
                }
            }
        }
        .padding(10)
        .qCard(cornerRadius: 28)
    }

    private func isHighlighted(row: Int, col: Int) -> Bool {
        (row == 1 && col == 1) || (row == 2 && (1...3).contains(col))
    }

    private func previewTile(letter: String, highlighted: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11)
                .fill(highlighted
                    ? LinearGradient(colors: [Color.qSun1, Color.qSun2], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [Color.qCream, Color(red: 1, green: 0.95, blue: 0.88)], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(Color.white.opacity(0.75), lineWidth: 1)
                )
                .shadow(color: Color.qInk.opacity(0.18), radius: 0, x: 0, y: 2)
            Text(letter)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(highlighted ? Color.qGoldDeep : Color.qInk)
        }
        .frame(width: 50, height: 50)
    }

    // MARK: - Decorative Floating Tile

    private func decorativeTile(_ letter: String, size: CGFloat, rotation: Double) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(LinearGradient(
                    colors: [Color.qCream, Color(red: 1, green: 0.95, blue: 0.88)],
                    startPoint: .top, endPoint: .bottom
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .stroke(Color.white.opacity(0.8), lineWidth: 1.2)
                )
                .shadow(color: Color.qInk.opacity(0.22), radius: 0, x: 0, y: 3)
                .shadow(color: Color.qInk.opacity(0.10), radius: 8, x: 0, y: 5)
            Text(letter)
                .font(.system(size: size * 0.44, weight: .bold, design: .rounded))
                .foregroundStyle(Color.qInk)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(rotation))
    }

    // MARK: - Bottom Nav

    private var bottomNav: some View {
        HStack(spacing: 8) {
            navButton(
                label: "Modes",
                icon: "square.grid.2x2.fill",
                gradient: [Color(red: 0.80, green: 0.71, blue: 1.0), Color(red: 0.61, green: 0.48, blue: 0.94)]
            ) { showModes = true }

            navButton(
                label: "Shop",
                icon: "cart.fill",
                gradient: [Color(red: 1.0, green: 0.70, blue: 0.85), Color(red: 1.0, green: 0.44, blue: 0.68)]
            ) { showShop = true }

            navButton(
                label: "Quests",
                icon: "checkmark.circle.fill",
                gradient: [Color.qMint1, Color.qMint2]
            ) { showQuests = true }

            navButton(
                label: "Friends",
                icon: "person.2.fill",
                gradient: [Color.qSun1, Color.qSun2]
            ) { showLocked = true }
        }
    }

    private func navButton(label: String, icon: String, gradient: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color(red: 0.24, green: 0.12, blue: 0.47).opacity(0.4), radius: 0, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    )
                    .shadow(color: Color(red: 0.24, green: 0.12, blue: 0.47).opacity(0.35), radius: 0, x: 0, y: 4)
                    .shadow(color: Color(red: 0.24, green: 0.12, blue: 0.47).opacity(0.15), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Action

    private func startGame() {
        onStart(GameSettings(language: selectedLanguage, boardVariant: selectedVariant))
    }
}

#Preview("Menu") {
    MenuView(onStart: { _ in })
        .environmentObject(AudioManager())
}

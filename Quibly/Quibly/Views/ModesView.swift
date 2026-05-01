import SwiftUI

struct ModesView: View {
    @Binding var selectedLanguage: GameLanguage
    @Binding var selectedVariant:  BoardVariant

    var onBack:  (() -> Void)?
    var onStart: (GameSettings) -> Void

    @Environment(\.dismiss) private var dismiss

    private struct GameMode {
        let id: String
        let icon: String
        let label: String
        let desc: String
        let gradient: [Color]
        let stars: Int
        let locked: Bool
        let badge: String?
        let unlock: String?
    }

    private let modes: [GameMode] = [
        .init(id: "classic",   icon: "🟪", label: "Classic",      desc: "4×4 board · the original",       gradient: [Color.qGrape1, Color.qGrape2],     stars: 3, locked: false, badge: nil,     unlock: nil),
        .init(id: "extended",  icon: "🟫", label: "Extended",     desc: "5×5 · more room to combo",       gradient: [Color.qBubble1, Color.qBubble2],   stars: 2, locked: false, badge: nil,     unlock: nil),
        .init(id: "challenge", icon: "🟧", label: "Challenge",    desc: "6×6 · for word wizards",         gradient: [Color.qSun1, Color.qSun2],         stars: 1, locked: false, badge: nil,     unlock: nil),
        .init(id: "blitz",     icon: "⚡", label: "Blitz",        desc: "90 seconds · score sprint",      gradient: [Color.qSky1, Color.qSky2],         stars: 0, locked: false, badge: "NEW",   unlock: nil),
        .init(id: "zen",       icon: "🍃", label: "Zen",          desc: "No game-over · just vibes",      gradient: [Color.qMint1, Color.qMint2],       stars: 0, locked: false, badge: nil,     unlock: nil),
        .init(id: "daily",     icon: "📅", label: "Daily Puzzle", desc: "Same board worldwide",           gradient: [Color.qSun1, Color(red: 1, green: 0.69, blue: 0.23)], stars: 0, locked: false, badge: "TODAY", unlock: nil),
        .init(id: "duel",      icon: "⚔️", label: "Duel",         desc: "Async vs. friends",              gradient: [Color.qCoral1, Color.qCoral2],     stars: 0, locked: true,  badge: nil,     unlock: "Lvl 15"),
    ]

    private let languages: [GameLanguage] = GameLanguage.allCases

    var body: some View {
        DreamBackground {
            ZStack(alignment: .top) {
                // Scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 110)

                        VStack(spacing: 14) {
                            languagePicker
                            modeTiles
                            boardSizePicker
                            startButton
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }

                // Top bar (above scroll view so taps reach buttons)
                HStack {
                    QCircleButton(size: 40, action: { dismiss(); onBack?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.qInk)
                    }
                    Spacer()
                    Text("Modes")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.qInk.opacity(0.4), radius: 0, x: 0, y: 2)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 56)
            }
        }
    }

    // MARK: - Language Picker

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.qInk)
                Text("Language")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qInk)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(languages) { lang in
                        let selected = lang == selectedLanguage
                        Button { selectedLanguage = lang } label: {
                            HStack(spacing: 6) {
                                Text(lang.flag).font(.system(size: 16))
                                Text(lang.rawValue)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(selected ? Color.white : Color.qInk)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(selected
                                        ? LinearGradient(colors: [Color.qGrape1, Color.qGrape2], startPoint: .top, endPoint: .bottom)
                                        : LinearGradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                                    )
                                    .overlay(
                                        Capsule().stroke(
                                            selected ? Color.white.opacity(0.45) : Color.qInk.opacity(0.18),
                                            lineWidth: 1
                                        )
                                    )
                                    .shadow(color: selected ? Color.qGrape2.opacity(0.4) : Color.clear, radius: 0, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .qCard(cornerRadius: 20)
    }

    // MARK: - Mode Tiles

    private var modeTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(modes, id: \.id) { mode in
                modeTile(mode)
            }
        }
    }

    private func modeTile(_ mode: GameMode) -> some View {
        Button {
            guard !mode.locked else { return }
            switch mode.id {
            case "classic":   selectedVariant = .small
            case "extended":  selectedVariant = .medium
            case "challenge": selectedVariant = .large
            default: break
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 22)
                    .fill(LinearGradient(colors: mode.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: mode.gradient.last!.opacity(0.35), radius: 0, x: 0, y: 5)
                    .shadow(color: mode.gradient.last!.opacity(0.15), radius: 10, x: 0, y: 5)

                VStack(alignment: .leading, spacing: 6) {
                    Text(mode.icon).font(.system(size: 32))
                    Text(mode.label)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: Color.black.opacity(0.25), radius: 0, x: 0, y: 2)
                    Text(mode.desc)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.95))

                    if mode.locked, let unlock = mode.unlock {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
                            Text(unlock).font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.25)))
                    } else {
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                Text("★")
                                    .font(.system(size: 14))
                                    .foregroundStyle(i < mode.stars ? Color.qSun1 : Color.white.opacity(0.35))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .frame(minHeight: 130)

                if let badge = mode.badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.qGoldDeep)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.qSun1)
                                .shadow(color: Color(red: 0.71, green: 0.43, blue: 0).opacity(0.4), radius: 0, x: 0, y: 2)
                        )
                        .padding(8)
                }
            }
            .opacity(mode.locked ? 0.82 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(mode.locked)
    }

    // MARK: - Board Size Picker

    private var boardSizePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Board Size")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.qInk)

            HStack(spacing: 8) {
                ForEach(BoardVariant.allCases) { variant in
                    let selected = variant == selectedVariant
                    Button { selectedVariant = variant } label: {
                        VStack(spacing: 2) {
                            Text("\(variant.rawValue)×\(variant.rawValue)")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(selected ? .white : Color.qInk)
                            Text(variant.label)
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(selected ? Color.white.opacity(0.85) : Color.qInk.opacity(0.65))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selected
                                    ? LinearGradient(colors: [Color.qGrape1, Color.qGrape2], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0.40)], startPoint: .top, endPoint: .bottom)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selected ? Color.white.opacity(0.45) : Color.qInk.opacity(0.18), lineWidth: 1)
                                )
                                .shadow(color: selected ? Color.qGrape2.opacity(0.4) : Color.clear, radius: 0, x: 0, y: 3)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .qCard(cornerRadius: 20)
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button { onStart(GameSettings(language: selectedLanguage, boardVariant: selectedVariant)) } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.qGoldDeep)
                Text("Start")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.qGoldDeep)
            }
        }
        .frame(width: 220)
        .buttonStyle(PuffyButtonStyle(variant: .gold))
    }
}

#Preview("Modes") {
    ModesView(
        selectedLanguage: .constant(.english),
        selectedVariant: .constant(.small),
        onBack: {},
        onStart: { _ in }
    )
}

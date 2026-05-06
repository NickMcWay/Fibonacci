import SwiftUI

struct ModesView: View {
    @Binding var selectedLanguage: GameLanguage
    @Binding var selectedVariant:  BoardVariant

    var onBack:  (() -> Void)?
    var onStart: (GameSettings) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedModeId: String = "classic"

    private struct ModeConfig {
        let id: String
        let icon: String
        let label: LocalizedStringKey
        let desc: LocalizedStringKey
        let gradient: [Color]
        let locked: Bool
        let badge: LocalizedStringKey?
        let unlock: String?
    }

    private let modes: [ModeConfig] = [
        .init(id: "classic",   icon: "🟪", label: "Classic",      desc: "4×4 board · the original",       gradient: [Color.qGrape1, Color.qGrape2],     locked: false, badge: nil,     unlock: nil),
        .init(id: "blitz",     icon: "⚡", label: "Blitz",        desc: "90 seconds · score sprint",      gradient: [Color.qSky1, Color.qSky2],         locked: false, badge: "NEW",   unlock: nil),
        .init(id: "zen",       icon: "🍃", label: "Zen",          desc: "No game-over · just vibes",      gradient: [Color.qMint1, Color.qMint2],       locked: false, badge: nil,     unlock: nil),
        .init(id: "daily",     icon: "📅", label: "Daily Puzzle", desc: "Same board worldwide",           gradient: [Color.qSun1, Color(red: 1, green: 0.69, blue: 0.23)], locked: false, badge: "TODAY", unlock: nil),
        .init(id: "sprint",    icon: "🎯", label: "Sprint",       desc: "30 moves · max score",           gradient: [Color(red: 0.38, green: 0.88, blue: 0.82), Color(red: 0.10, green: 0.68, blue: 0.72)], locked: false, badge: "NEW",   unlock: nil),
        .init(id: "duel",      icon: "⚔️", label: "Duel",         desc: "Async vs. friends",              gradient: [Color.qCoral1, Color.qCoral2],     locked: true,  badge: nil,     unlock: "Lvl 15"),
    ]

    private let languages: [GameLanguage] = GameLanguage.allCases

    private var derivedGameMode: GameMode {
        switch selectedModeId {
        case "blitz":  return .blitz
        case "zen":    return .zen
        case "daily":  return .daily
        case "sprint": return .swipeLimited
        default:       return .classic
        }
    }

    // Board size picker only makes sense for board-size modes and zen
    private var showsBoardSizePicker: Bool {
        ["classic", "extended", "challenge", "zen"].contains(selectedModeId)
    }

    var body: some View {
        NavigationView{
            DreamBackground {
                ZStack(alignment: .top) {
                    ScrollView {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 110)
                            
                            VStack(spacing: 14) {
                                languagePicker
                                boardSizePicker
                                modeTiles
                                startButton
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .onAppear {
                switch selectedVariant {
                case .small:  selectedModeId = "classic"
                case .medium: selectedModeId = "extended"
                case .large:  selectedModeId = "challenge"
                }
            }
            .toolbar{
                ToolbarItem(placement:.topBarLeading) {
                    QCircleButton(size: 40, action: { dismiss(); onBack?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.qInk)
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Modes")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.qInk.opacity(0.4), radius: 0, x: 0, y: 2)
                        Text("Choose your game")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .shadow(color: Color.qInk.opacity(0.3), radius: 0, x: 0, y: 1)
                    }
                }
            }
        }
    }

    // MARK: - Language Picker

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.qGrape2)
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
                                Text(lang.displayName)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.qGrape2)
                Text("Game Mode")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qInk)
            }
            .padding(.horizontal, 2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(modes.prefix(4), id: \.id) { mode in
                    modeTile(mode)
                }
            }

            ForEach(modes.dropFirst(4), id: \.id) { mode in
                modeTile(mode, fullWidth: true)
            }
        }
        .padding(12)
        .qCard(cornerRadius: 20)
    }

    private func modeTile(_ mode: ModeConfig, fullWidth: Bool = false) -> some View {
        let isSelected = mode.id == selectedModeId
        return Button {
            guard !mode.locked else { return }
            selectedModeId = mode.id
            switch mode.id {
            case "classic":   selectedVariant = .small
            case "extended":  selectedVariant = .medium
            case "challenge": selectedVariant = .large
            case "blitz":     selectedVariant = .small
            case "daily":     selectedVariant = .small
            case "sprint":    selectedVariant = .small
            default: break
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: mode.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Color.white.opacity(0.9) : Color.white.opacity(0.35),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    )
                    .shadow(color: mode.gradient.last!.opacity(0.35), radius: 0, x: 0, y: 5)
                    .shadow(color: mode.gradient.last!.opacity(isSelected ? 0.40 : 0.15), radius: isSelected ? 16 : 10, x: 0, y: 5)

                if fullWidth {
                    HStack(spacing: 14) {
                        Text(mode.icon).font(.system(size: 36))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.label)
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: Color.black.opacity(0.25), radius: 0, x: 0, y: 2)
                            Text(mode.desc)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.95))
                        }
                        Spacer()
                        if mode.locked, let unlock = mode.unlock {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
                                Text(unlock).font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(Color.black.opacity(0.25)))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top) {
                            Text(mode.icon).font(.system(size: 32))
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .shadow(color: Color.black.opacity(0.2), radius: 0, x: 0, y: 1)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        Text(mode.label)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: Color.black.opacity(0.25), radius: 0, x: 0, y: 2)
                        Text(mode.desc)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.9))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        if mode.locked, let unlock = mode.unlock {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
                                Text(unlock).font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(Color.black.opacity(0.25)))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .frame(minHeight: 120)
                }

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
            .ignoresSafeArea(edges: .top)
            .opacity(mode.locked ? 0.72 : 1.0)
            .scaleEffect(isSelected && !mode.locked ? 1.025 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.68), value: isSelected)
        }
        .buttonStyle(ModeTileButtonStyle())
        .disabled(mode.locked)
    }

    // MARK: - Board Size Picker

    private var boardSizePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.qGrape2)
                Text("Board Size")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qInk)
            }

            HStack(spacing: 8) {
                ForEach(BoardVariant.allCases) { variant in
                    let selected = variant == selectedVariant
                    Button { selectedVariant = variant } label: {
                        VStack(spacing: 2) {
                            Text("\(variant.rawValue)×\(variant.rawValue)")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundStyle(selected ? .white : Color.qInk)
                            Text(LocalizedStringKey(variant.label))
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
        Button {
            onStart(GameSettings(
                language: selectedLanguage,
                boardVariant: selectedVariant,
                gameMode: derivedGameMode
            ))
        } label: {
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

// MARK: - Mode Tile Button Style

private struct ModeTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
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

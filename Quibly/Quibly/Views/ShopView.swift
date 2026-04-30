import SwiftUI

struct ShopView: View {
    var onBack: (() -> Void)? = nil

    @AppStorage("SlideWords_Coins")          private var coins:          Int = 125
    @AppStorage("SlideWords_HintCharges")    private var hintCharges:    Int = 2
    @AppStorage("SlideWords_ShuffleCharges") private var shuffleCharges: Int = 1
    @AppStorage("SlideWords_BombCharges")    private var bombCharges:    Int = 1
    @AppStorage("SlideWords_WildCharges")    private var wildCharges:    Int = 1

    @Environment(\.dismiss) private var dismiss

    private let hintCost    = 25
    private let shuffleCost = 50
    private let wildCost    = 60
    private let bombCost    = 75

    private struct PowerUp {
        let id: String
        let icon: String
        let name: String
        let desc: String
        let cost: Int
        let gradient: [Color]
    }

    private let powerUps: [PowerUp] = [
        .init(id: "hint",    icon: "lightbulb.fill", name: "Hint",    desc: "Reveals a pending word match",       cost: 25, gradient: [Color.qSun1, Color.qSun2]),
        .init(id: "shuffle", icon: "shuffle",         name: "Shuffle", desc: "Randomly rearranges all tiles",      cost: 50, gradient: [Color.qSky1, Color.qSky2]),
        .init(id: "wild",    icon: "wand.and.stars",  name: "Wild",    desc: "Converts any tile into a joker",     cost: 60, gradient: [Color.qGrape1, Color.qGrape2]),
        .init(id: "bomb",    icon: "burst.fill",       name: "Bomb",    desc: "Clears a full row and column",       cost: 75, gradient: [Color.qCoral1, Color.qCoral2]),
    ]

    private let themes: [(name: String, bg: [Color], textColor: Color, cost: Int, owned: Bool, locked: Bool)] = [
        ("Cream",    [Color.qCream, Color(red: 1, green: 0.95, blue: 0.88)], Color.qInk,                                    0,   true,  false),
        ("Mint",     [Color.qMint1, Color.qMint2],                           Color(red: 0.12, green: 0.43, blue: 0.23),     400, false, false),
        ("Galaxy",   [Color(red: 0.35, green: 0.23, blue: 0.64), Color(red: 0.17, green: 0.11, blue: 0.39)], Color.qSun1,   800, false, false),
        ("Bubble",   [Color.qBubble1, Color.qBubble2],                       Color(red: 0.66, green: 0.24, blue: 0.43),     400, false, false),
        ("Lemonade", [Color(red: 1, green: 0.97, blue: 0.70), Color(red: 1, green: 0.84, blue: 0.29)], Color(red: 0.65, green: 0.42, blue: 0), 500, false, false),
        ("Sky",      [Color.qSky1, Color.qSky2],                             Color(red: 0.12, green: 0.34, blue: 0.55),     500, false, true),
    ]

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(red: 0.93, green: 0.89, blue: 1.0),
                         Color(red: 1.0, green: 0.88, blue: 0.93),
                         Color(red: 1.0, green: 0.95, blue: 0.85)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Sparkle dots
            GeometryReader { geo in
                ForEach(0..<12, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
                        .position(
                            x: CGFloat(i) / 12 * geo.size.width + CGFloat(i * 37 % 80) - 40,
                            y: CGFloat(i * 73 % Int(geo.size.height))
                        )
                }
            }
            .allowsHitTesting(false)

            // Header
            VStack(spacing: 0) {
                HStack {
                    QCircleButton(size: 40, action: { onBack?() ?? dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.qInk)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.qInk)
                        Text("Shop")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.qInk)
                    }
                    Spacer()
                    CoinChip(amount: coins, big: true)
                }
                .padding(.horizontal, 16)
                .padding(.top, 52)
                .padding(.bottom, 14)
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.45), Color.white.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }

            // Scrollable content
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 110)

                    VStack(spacing: 0) {
                        // Hero bundle
                        heroBundle
                            .padding(.bottom, 4)

                        // Power-Ups
                        QSectionHeader(title: "Power-Ups", subtitle: "Spend coins for extra charges")
                        VStack(spacing: 10) {
                            ForEach(powerUps, id: \.id) { pu in
                                powerUpRow(pu)
                            }
                        }

                        // Coin Packs
                        QSectionHeader(title: "Coin Packs", subtitle: "Free — no purchase required")
                        HStack(spacing: 10) {
                            coinPackCard(amount: 100, label: "Starter",
                                         tintColors: [Color(red: 0.85, green: 0.93, blue: 1.0), Color(red: 0.62, green: 0.79, blue: 1.0)],
                                         accentColor: Color(red: 0.23, green: 0.47, blue: 0.76), popular: false)
                            coinPackCard(amount: 300, label: "Builder",
                                         tintColors: [Color(red: 0.84, green: 0.97, blue: 0.85), Color(red: 0.55, green: 0.89, blue: 0.61)],
                                         accentColor: Color(red: 0.12, green: 0.61, blue: 0.36), popular: true)
                            coinPackCard(amount: 750, label: "Master",
                                         tintColors: [Color(red: 1, green: 0.95, blue: 0.77), Color(red: 1, green: 0.81, blue: 0.42)],
                                         accentColor: Color(red: 0.65, green: 0.42, blue: 0), popular: false)
                        }

                        // Tile Themes
                        QSectionHeader(title: "Tile Themes", subtitle: "Re-skin your board")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(themes.indices, id: \.self) { i in
                                let t = themes[i]
                                themeCard(name: t.name, gradient: t.bg, textColor: t.textColor, cost: t.cost, owned: t.owned, locked: t.locked)
                            }
                        }

                        Text("Coin packs are free — no purchase required.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.qInk.opacity(0.55))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 18)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    // MARK: - Hero Bundle

    private var heroBundle: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: [Color.qGrape1, Color.qBubble2, Color.qSun1],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .shadow(color: Color(red: 0.31, green: 0.12, blue: 0.51).opacity(0.4), radius: 0, x: 0, y: 6)
                .shadow(color: Color(red: 0.31, green: 0.12, blue: 0.51).opacity(0.2), radius: 14, x: 0, y: 8)

            // Radial shine
            Circle()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(0.5), Color.white.opacity(0)],
                    center: .center, startRadius: 0, endRadius: 80
                ))
                .frame(width: 160, height: 160)
                .offset(x: 60, y: -30)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 4) {
                Text("LIMITED · 48H")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .tracking(1)

                Text("Sparkle Bundle")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color(red: 0.31, green: 0.12, blue: 0.51).opacity(0.45), radius: 0, x: 0, y: 2)

                Text("1,500 coins · 5 of every power-up · Sunset theme")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.95))

                HStack(spacing: 12) {
                    Text("$4.99")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.66, green: 0.24, blue: 0.43))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: Color(red: 0.66, green: 0.24, blue: 0.43).opacity(0.3), radius: 0, x: 0, y: 3)
                        )

                    Text("$9.99")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .strikethrough()

                    Spacer()

                    Text("−50%")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.25)))
                }
                .padding(.top, 8)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 8)
    }

    // MARK: - Power-Up Row

    private func powerUpRow(_ pu: PowerUp) -> some View {
        let owned: Int = {
            switch pu.id {
            case "hint":    return hintCharges
            case "shuffle": return shuffleCharges
            case "wild":    return wildCharges
            case "bomb":    return bombCharges
            default:        return 0
            }
        }()
        let canAfford = coins >= pu.cost

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: pu.gradient, startPoint: .top, endPoint: .bottom))
                    .shadow(color: pu.gradient.last!.opacity(0.3), radius: 0, x: 0, y: 3)
                Image(systemName: pu.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(pu.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.qInk)
                    Text("×\(owned) owned")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.qInk.opacity(0.55))
                }
                Text(pu.desc)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.qInk.opacity(0.70))
            }

            Spacer()

            Button {
                guard canAfford else { return }
                coins -= pu.cost
                switch pu.id {
                case "hint":    hintCharges += 1
                case "shuffle": shuffleCharges += 1
                case "wild":    wildCharges += 1
                case "bomb":    bombCharges += 1
                default: break
                }
            } label: {
                HStack(spacing: 5) {
                    Circle()
                        .fill(RadialGradient(colors: [Color(red: 1, green: 0.96, blue: 0.7), Color(red: 0.94, green: 0.64, blue: 0.13)], center: .topLeading, startRadius: 0, endRadius: 8))
                        .frame(width: 14, height: 14)
                    Text("\(pu.cost)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.qGoldDeep)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(LinearGradient(
                            colors: canAfford
                                ? [Color(red: 1, green: 0.97, blue: 0.85), Color(red: 1, green: 0.89, blue: 0.60)]
                                : [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .shadow(color: Color(red: 0.71, green: 0.43, blue: 0).opacity(canAfford ? 0.35 : 0), radius: 0, x: 0, y: 3)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAfford)
        }
        .padding(12)
        .qCard(cornerRadius: 20)
    }

    // MARK: - Coin Pack Card

    private func coinPackCard(amount: Int, label: String, tintColors: [Color], accentColor: Color, popular: Bool) -> some View {
        Button { coins += amount } label: {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: tintColors, startPoint: .top, endPoint: .bottom))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.85), lineWidth: 1)
                    )
                    .shadow(color: Color.qInk.opacity(0.18), radius: 0, x: 0, y: 4)

                VStack(spacing: 4) {
                    Spacer().frame(height: popular ? 10 : 6)
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color(red: 1, green: 0.96, blue: 0.7), Color(red: 0.94, green: 0.64, blue: 0.13)],
                            center: .topLeading, startRadius: 0, endRadius: 18
                        ))
                        .frame(width: 36, height: 36)
                        .shadow(color: Color(red: 0.55, green: 0.31, blue: 0).opacity(0.4), radius: 0, x: -2, y: -3)

                    Text("+\(amount)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(accentColor)
                    Text(label.uppercased())
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.qInk.opacity(0.65))
                        .tracking(0.6)

                    Text("FREE")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(Capsule().fill(Color.qMint2).shadow(color: Color(red: 0.08, green: 0.39, blue: 0.20).opacity(0.4), radius: 0, x: 0, y: 2))
                        .padding(.bottom, 6)
                }
                .frame(maxWidth: .infinity)

                if popular {
                    Text("BEST VALUE")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Capsule().fill(Color.qBubble2).shadow(color: Color(red: 0.63, green: 0.12, blue: 0.35).opacity(0.4), radius: 0, x: 0, y: 2))
                        .offset(y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Theme Card

    private func themeCard(name: String, gradient: [Color], textColor: Color, cost: Int, owned: Bool, locked: Bool) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                ForEach(["Q","U"], id: \.self) { letter in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom))
                            .shadow(color: Color.qInk.opacity(0.18), radius: 0, x: 0, y: 2)
                        Text(letter)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(textColor)
                    }
                    .frame(width: 28, height: 28)
                    .opacity(locked ? 0.5 : 1)
                }
            }

            Text(name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.qInk)

            if owned {
                Text("EQUIPPED")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.qMint2)
            } else if locked {
                HStack(spacing: 3) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("Lvl 20")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color.qInk.opacity(0.6))
            } else {
                HStack(spacing: 3) {
                    Circle()
                        .fill(RadialGradient(colors: [Color(red: 1, green: 0.96, blue: 0.7), Color(red: 0.94, green: 0.64, blue: 0.13)], center: .topLeading, startRadius: 0, endRadius: 6))
                        .frame(width: 10, height: 10)
                    Text("\(cost)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.qGoldDeep)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.85), lineWidth: 1))
                .shadow(color: Color.qInk.opacity(0.15), radius: 0, x: 0, y: 3)
        )
    }
}

#Preview("Shop") {
    ShopView()
}

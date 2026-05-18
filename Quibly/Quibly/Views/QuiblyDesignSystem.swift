// QuiblyDesignSystem.swift
// Shared design tokens, backgrounds, card styles, and UI primitives for the Quibly design.

import SwiftUI

// MARK: - Color Tokens

extension Color {
    static let qInk      = Color(red: 0.227, green: 0.165, blue: 0.471)  // #3a2a78
    static let qInkSoft  = Color(red: 0.227, green: 0.165, blue: 0.471).opacity(0.65)
    static let qGrape1   = Color(red: 0.702, green: 0.608, blue: 1.000)  // #b39bff
    static let qGrape2   = Color(red: 0.486, green: 0.361, blue: 0.898)  // #7c5ce5
    static let qBubble1  = Color(red: 1.000, green: 0.835, blue: 0.918)  // #ffd5ea
    static let qBubble2  = Color(red: 1.000, green: 0.486, blue: 0.714)  // #ff7cb6
    static let qPeach1   = Color(red: 1.000, green: 0.757, blue: 0.659)  // #ffc1a8
    static let qSun1     = Color(red: 1.000, green: 0.886, blue: 0.478)  // #ffe27a
    static let qSun2     = Color(red: 1.000, green: 0.686, blue: 0.227)  // #ffaf3a
    static let qMint1    = Color(red: 0.557, green: 0.906, blue: 0.678)  // #8ee8ad
    static let qMint2    = Color(red: 0.212, green: 0.753, blue: 0.443)  // #36c071
    static let qCoral1   = Color(red: 1.000, green: 0.616, blue: 0.541)  // #ff9d8a
    static let qCoral2   = Color(red: 1.000, green: 0.353, blue: 0.267)  // #ff5a44
    static let qSky1     = Color(red: 0.604, green: 0.831, blue: 1.000)  // #9ad4ff
    static let qSky2     = Color(red: 0.200, green: 0.596, blue: 1.000)  // #3398ff
    static let qGoldDeep = Color(red: 0.478, green: 0.271, blue: 0.000)  // #7a4500
    static let qCream    = Color(red: 1.000, green: 0.980, blue: 0.941)  // tile base
    static let qSunset1  = Color(red: 1.000, green: 0.847, blue: 0.608)  // #FFD89B warm amber
    static let qSunset2  = Color(red: 1.000, green: 0.557, blue: 0.325)  // #FF8E53 sunset orange
}

// MARK: - Tile Theme

struct TileTheme: Identifiable, Equatable {
    let id: String
    let displayName: String
    let tileColors: [Color]   // normal tile gradient (top → bottom)
    let letterColor: Color    // letter on a normal tile
    let shadowColor: Color    // drop-shadow tint on a normal tile
    let backgroundImage: String  // asset name for the full-screen background
    let cost: Int             // 0 = free
    let unlockLevel: Int?     // nil = no level gate
    let bundleOnly: Bool      // true = only obtainable via Sparkle Bundle IAP

    static let cream = TileTheme(
        id: "cream", displayName: "Cream",
        tileColors: [Color.qCream, Color(red: 1, green: 0.95, blue: 0.88)],
        letterColor: Color.qInk,
        shadowColor: Color.qInk,
        backgroundImage: "Quibly Background",
        cost: 0, unlockLevel: nil, bundleOnly: false
    )
    static let mint = TileTheme(
        id: "mint", displayName: "Mint",
        tileColors: [Color.qMint1, Color.qMint2],
        letterColor: Color(red: 0.11, green: 0.43, blue: 0.24),
        shadowColor: Color(red: 0.11, green: 0.43, blue: 0.24),
        backgroundImage: "Forest Theme",
        cost: 400, unlockLevel: nil, bundleOnly: false
    )
    static let bubble = TileTheme(
        id: "bubble", displayName: "Bubble",
        tileColors: [Color.qBubble1, Color.qBubble2],
        letterColor: Color(red: 0.66, green: 0.24, blue: 0.43),
        shadowColor: Color(red: 0.66, green: 0.24, blue: 0.43),
        backgroundImage: "Bubble Theme",
        cost: 400, unlockLevel: nil, bundleOnly: false
    )
    static let lemonade = TileTheme(
        id: "lemonade", displayName: "Lemonade",
        tileColors: [Color(red: 1, green: 0.980, blue: 0.647), Color(red: 1, green: 0.839, blue: 0.290)],
        letterColor: Color(red: 0.647, green: 0.416, blue: 0.000),
        shadowColor: Color(red: 0.647, green: 0.416, blue: 0.000),
        backgroundImage: "Lemonade Theme",
        cost: 500, unlockLevel: nil, bundleOnly: false
    )
    static let sky = TileTheme(
        id: "sky", displayName: "Sky",
        tileColors: [Color.qSky1, Color.qSky2],
        letterColor: Color(red: 0.12, green: 0.34, blue: 0.55),
        shadowColor: Color(red: 0.12, green: 0.34, blue: 0.55),
        backgroundImage: "Sky Theme",
        cost: 500, unlockLevel: 20, bundleOnly: false
    )
    static let galaxy = TileTheme(
        id: "galaxy", displayName: "Galaxy",
        tileColors: [Color(red: 0.353, green: 0.231, blue: 0.639), Color(red: 0.169, green: 0.110, blue: 0.392)],
        letterColor: Color.qSun1,
        shadowColor: Color(red: 0.106, green: 0.055, blue: 0.243),
        backgroundImage: "Space Theme",
        cost: 800, unlockLevel: nil, bundleOnly: false
    )
    static let sunset = TileTheme(
        id: "sunset", displayName: "Sunset",
        tileColors: [Color.qSunset1, Color.qSunset2],
        letterColor: Color(red: 0.541, green: 0.145, blue: 0.000),
        shadowColor: Color(red: 0.541, green: 0.145, blue: 0.000),
        backgroundImage: "Sunset Theme",
        cost: 0, unlockLevel: nil, bundleOnly: true
    )

    static let all: [TileTheme] = [.cream, .mint, .bubble, .lemonade, .sky, .galaxy, .sunset]

    static func find(id: String) -> TileTheme {
        all.first { $0.id == id } ?? .cream
    }
}

// MARK: - Dream Background (theme-aware)

struct DreamBackground<Content: View>: View {
    @AppStorage("SlideWords_ActiveTheme") private var activeThemeID: String = "cream"
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        ZStack {
            Image(TileTheme.find(id: activeThemeID).backgroundImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .id(activeThemeID)  // force image swap when theme changes
            content
        }
    }
}

// MARK: - Glass Card Modifier

struct QCard: ViewModifier {
    var cornerRadius: CGFloat = 22
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.82))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                    )
                    .shadow(color: Color.qInk.opacity(0.18), radius: 0, x: 0, y: 4)
                    .shadow(color: Color.qInk.opacity(0.08), radius: 14, x: 0, y: 8)
            )
    }
}

extension View {
    func qCard(cornerRadius: CGFloat = 22) -> some View {
        modifier(QCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Puffy Button Style (Gold / Ghost / Grape)

enum PuffyVariant { case gold, ghost, grape }

struct PuffyButtonStyle: ButtonStyle {
    var variant: PuffyVariant = .gold

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 999)
                    .fill(gradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.85), Color.white.opacity(0.2)],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: shadowColor.opacity(0.40), radius: 0, x: 0, y: 4)
                    .shadow(color: shadowColor.opacity(0.20), radius: 10, x: 0, y: 6)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }

    private var gradient: LinearGradient {
        switch variant {
        case .gold:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.973, blue: 0.855),
                         Color(red: 1.0, green: 0.890, blue: 0.604)],
                startPoint: .top, endPoint: .bottom
            )
        case .ghost:
            return LinearGradient(
                colors: [Color.white.opacity(0.65), Color.white.opacity(0.45)],
                startPoint: .top, endPoint: .bottom
            )
        case .grape:
            return LinearGradient(
                colors: [Color.qGrape1, Color.qGrape2],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .gold:  return Color(red: 0.71, green: 0.43, blue: 0.00)
        case .ghost: return Color.black.opacity(0.15)
        case .grape: return Color(red: 0.31, green: 0.16, blue: 0.69)
        }
    }
}

// MARK: - Circle Button

struct QCircleButton<Content: View>: View {
    let size: CGFloat
    let action: () -> Void
    @ViewBuilder let content: Content

    init(size: CGFloat = 40, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.size = size
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.5))
                        .shadow(color: Color.qInk.opacity(0.18), radius: 0, x: 0, y: 3)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Coin Chip

struct CoinChip: View {
    let amount: Int
    var big: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 1, green: 0.98, blue: 0.70),
                                     Color(red: 0.94, green: 0.64, blue: 0.13)],
                            center: .topLeading, startRadius: 0, endRadius: big ? 14 : 10
                        )
                    )
                Text("$")
                    .font(.system(size: big ? 11 : 8, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.71, green: 0.43, blue: 0))
            }
            .frame(width: big ? 20 : 14, height: big ? 20 : 14)
            Text("\(amount)")
                .font(.system(size: big ? 17 : 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.qInk)
        }
        .padding(.horizontal, big ? 12 : 8)
        .padding(.vertical, big ? 8 : 5)
        .background(
            Capsule()
                .fill(LinearGradient(
                    colors: [Color(red: 1, green: 0.973, blue: 0.855),
                             Color(red: 1, green: 0.890, blue: 0.604)],
                    startPoint: .top, endPoint: .bottom
                ))
                .overlay(Capsule().stroke(Color.white.opacity(0.85), lineWidth: 1))
                .shadow(color: Color(red: 0.71, green: 0.43, blue: 0).opacity(0.3), radius: 0, x: 0, y: 2)
        )
    }
}

// MARK: - Quibly Logo

struct QuiblyLogo: View {
    var size: CGFloat = 68

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(LinearGradient(
                    colors: [Color.qGrape1, Color.qGrape2],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1.5)
                )
                .shadow(color: Color.qInk.opacity(0.40), radius: 0, x: 0, y: 4)
                .shadow(color: Color.qInk.opacity(0.20), radius: 12, x: 0, y: 8)
            Text("Q")
                .font(.system(size: size * 0.58, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .shadow(color: Color.qInk.opacity(0.40), radius: 0, x: 0, y: 2)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Floating Animation

struct FloatModifier: ViewModifier {
    @State private var up = false
    let delay: Double
    let duration: Double
    let distance: CGFloat

    init(delay: Double = 0, duration: Double = 3.4, distance: CGFloat = 5) {
        self.delay = delay
        self.duration = duration
        self.distance = distance
    }

    func body(content: Content) -> some View {
        content
            .offset(y: up ? -distance : distance)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) { up = true }
            }
    }
}

extension View {
    func floatingAnimation(delay: Double = 0, duration: Double = 3.4, distance: CGFloat = 5) -> some View {
        modifier(FloatModifier(delay: delay, duration: duration, distance: distance))
    }
}

// MARK: - Wiggle Animation

struct WiggleModifier: ViewModifier {
    @State private var angle: Double = 0
    let active: Bool

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .onChange(of: active) { isActive in
                if isActive {
                    withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                        angle = 4
                    }
                } else {
                    withAnimation { angle = 0 }
                }
            }
            .onAppear {
                if active {
                    withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
                        angle = 4
                    }
                }
            }
    }
}

extension View {
    func wiggle(active: Bool) -> some View {
        modifier(WiggleModifier(active: active))
    }
}

// MARK: - Stat Chip (Menu stats row)

struct QStatChip: View {
    let icon: String        // SF Symbol name
    let iconColor: Color
    let label: LocalizedStringKey
    let value: String
    let gradient: [Color]
    var coinStyle: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if coinStyle {
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color(red: 1, green: 0.98, blue: 0.70),
                                     Color(red: 0.94, green: 0.64, blue: 0.13)],
                            center: .topLeading, startRadius: 0, endRadius: 10
                        ))
                    Text("$")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.71, green: 0.43, blue: 0))
                }
                .frame(width: 18, height: 18)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.qInk.opacity(0.65))
                    .tracking(0.6)
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qInk)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(colors: gradient, startPoint: .top, endPoint: .bottom))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                )
                .shadow(color: Color.qInk.opacity(0.18), radius: 0, x: 0, y: 3)
        )
    }
}

// MARK: - Section Header (Shop)

struct QSectionHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.qInk)
            Text(subtitle)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.qInk.opacity(0.60))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
        .padding(.bottom, 6)
    }
}

// MARK: - Popup Modal Container

struct QModal<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content

    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { withAnimation(.easeOut(duration: 0.2)) { isPresented = false } }

            content
                .padding(.horizontal, 24)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isPresented)
    }
}

// MARK: - XP Bar

struct XPBarView: View {
    @AppStorage("SlideWords_TotalXP") private var totalXP: Int = 0

    private let xpPerLevel = 500

    private var level: Int { totalXP / xpPerLevel + 1 }
    private var xpInLevel: Int { totalXP % xpPerLevel }
    private var progress: Double { Double(xpInLevel) / Double(xpPerLevel) }

    var body: some View {
        VStack(spacing: 3) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 999)
                    .fill(Color.qInk.opacity(0.10))
                    .frame(height: 8)
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 999)
                        .fill(LinearGradient(
                            colors: [Color.qSun1, Color.qBubble2, Color.qGrape1],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: max(geo.size.width * progress, progress > 0 ? 8 : 0), height: 8)
                }
                .frame(height: 8)
            }
            HStack {
                Text("Lvl \(level)")
                Spacer()
                Text("\(xpInLevel) / \(xpPerLevel) xp")
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color.qInk.opacity(0.65))
        }
    }
}

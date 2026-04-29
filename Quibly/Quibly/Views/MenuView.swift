import SwiftUI

struct MenuView: View {
    var onStart: (GameSettings) -> Void

    @EnvironmentObject private var audio: AudioManager
    @AppStorage("SlideWords_BestScore") private var bestScore: Int = 0
    @AppStorage("SlideWords_Coins") private var coins: Int = 125
    @State private var selectedLanguage: GameLanguage = .english
    @State private var selectedVariant: BoardVariant = .small
    @State private var activePage: MenuPage?

    private let cream = Color(red: 0.98, green: 0.94, blue: 0.88)
    private let ink = Color(red: 0.31, green: 0.23, blue: 0.57)

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 18) {
                titleSection
                summaryBar
                boardPreview
                playButton
                bottomActions
            }
            .padding(.horizontal, 42)
            .padding(.top, 38)
            .padding(.bottom, 52)
        }
        .onAppear { audio.play() }
        .sheet(item: $activePage) { page in
            MenuDetailsPage(page: page, selectedLanguage: $selectedLanguage, selectedVariant: $selectedVariant)
        }
    }

    private var backgroundLayer: some View {
        Image("Quibly Background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }

    private var titleSection: some View {
        Spacer()
            .frame(maxWidth: 320)
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.top, 8)
    }

    private var summaryBar: some View {
        HStack(spacing: 12) {
            summaryItem(label: "Highscore", value: "\(bestScore)", symbol: "trophy.fill", tint: Color(red: 1, green: 0.82, blue: 0.6))
            summaryItem(label: "Coins", value: "\(coins)", symbol: "bitcoinsign.circle.fill", tint: Color(red: 1, green: 0.72, blue: 0.5))
        }
    }

    private func summaryItem(label: String, value: String, symbol: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.65))
                Text(value)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(tint)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                )
        )
    }

    private var boardPreview: some View {
        let letters: [[String]] = [
            ["Q", "U", "I", "B"],
            ["L", "P", "A", "R"],
            ["E", "L", "A", "Y"],
            ["W", "O", "R", "D"]
        ]

        return VStack(spacing: 8) {
            ForEach(Array(letters.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 8) {
                    ForEach(Array(row.enumerated()), id: \.offset) { columnIndex, letter in
                        tile(letter: letter, highlighted: isHighlighted(row: rowIndex, col: columnIndex))
                    }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: 282)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.34))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                )
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 7)
        )
        .overlay(alignment: .center) {
            HStack(spacing: 40) {
                Circle().fill(Color.white.opacity(0.82)).frame(width: 8, height: 8)
                Circle().fill(Color.white.opacity(0.82)).frame(width: 8, height: 8)
            }
            .offset(x: 16, y: 32)
        }
    }

    private func isHighlighted(row: Int, col: Int) -> Bool {
        (row == 1 && col == 1) || (row == 2 && (1...3).contains(col))
    }

    private func tile(letter: String, highlighted: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17)
                .fill(highlighted ? Color(red: 0.99, green: 0.87, blue: 0.34) : cream)
                .shadow(color: .black.opacity(0.10), radius: 5, x: 0, y: 3)

            Text(letter)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(highlighted ? Color(red: 0.42, green: 0.28, blue: 0.12) : ink)
        }
        .frame(width: 54, height: 54)
    }

    private var playButton: some View {
        Button(action: startGame) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Play")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: 282)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.99, green: 0.87, blue: 0.34), Color(red: 0.97, green: 0.68, blue: 0.20)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(Color.white.opacity(0.7), lineWidth: 1.2)
                    )
                    .shadow(color: Color(red: 0.72, green: 0.40, blue: 0.15).opacity(0.45), radius: 8, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }

    private var bottomActions: some View {
        HStack(spacing: 14) {
            menuButton(page: .daily, tint: Color(red: 0.90, green: 0.82, blue: 0.97), symbol: "calendar", title: "Daily", iconColor: Color(red: 0.50, green: 0.36, blue: 0.84))
            menuButton(page: .modes, tint: Color(red: 0.78, green: 0.87, blue: 0.99), symbol: "square.grid.2x2.fill", title: "Modes", iconColor: Color(red: 0.14, green: 0.44, blue: 0.79))
            menuButton(page: .stats, tint: Color(red: 0.88, green: 0.95, blue: 0.82), symbol: "chart.bar.fill", title: "Stats", iconColor: Color(red: 0.23, green: 0.63, blue: 0.50))
        }
    }

    private func menuButton(page: MenuPage, tint: Color, symbol: String, title: String, iconColor: Color) -> some View {
        Button(action: { activePage = page }) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(tint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.75), lineWidth: 1.1)
                    )
                    .shadow(color: .black.opacity(0.16), radius: 7, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }

    private func startGame() {
        let settings = GameSettings(language: selectedLanguage, boardVariant: selectedVariant)
        onStart(settings)
    }
}

private enum MenuPage: String, Identifiable {
    case daily = "Daily"
    case modes = "Modes"
    case stats = "Stats"

    var id: String { rawValue }
}

private struct MenuDetailsPage: View {
    let page: MenuPage
    @Binding var selectedLanguage: GameLanguage
    @Binding var selectedVariant: BoardVariant
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                switch page {
                case .daily:
                    Section("Today's Challenge") {
                        Label("Find 12 words in one run", systemImage: "target")
                        Label("Use at least one 5-letter word", systemImage: "textformat.abc")
                        Label("Bonus: clear a full row", systemImage: "sparkles")
                    }
                case .modes:
                    Section("Language") {
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(GameLanguage.allCases) { lang in
                                Text("\(lang.flag) \(lang.rawValue)").tag(lang)
                            }
                        }
                    }

                    Section("Board Size") {
                        Picker("Board Size", selection: $selectedVariant) {
                            ForEach(BoardVariant.allCases) { variant in
                                Text("\(variant.displayName) (\(variant.label))").tag(variant)
                            }
                        }
                    }
                case .stats:
                    Section("Profile") {
                        statRow("Best Score", value: "0")
                        statRow("Games Played", value: "0")
                        statRow("Longest Word", value: "—")
                    }
                }
            }
            .navigationTitle(page.rawValue)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Menu") {
    MenuView(onStart: { _ in })
        .environmentObject(AudioManager())
}

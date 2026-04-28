// MenuView.swift
// Game start screen: language selection and board size variant.
// Tapping "Start Game" returns a configured GameSettings to the caller.

import SwiftUI

struct MenuView: View {
    var onStart: (GameSettings) -> Void

    @State private var selectedLanguage: GameLanguage = .english
    @State private var selectedVariant: BoardVariant = .small

    private let bgColor = Color(red: 0.97, green: 0.97, blue: 0.98)
    private let accentBlue = Color(red: 0.30, green: 0.42, blue: 0.70)
    private let cardBlue = Color(red: 0.40, green: 0.55, blue: 0.85)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Title
                    titleSection

                    // Language picker
                    sectionCard(title: "Language") {
                        VStack(spacing: 10) {
                            ForEach(GameLanguage.allCases) { lang in
                                languageRow(lang)
                            }
                        }
                    }

                    // Board variant picker
                    sectionCard(title: "Board Size") {
                        HStack(spacing: 12) {
                            ForEach(BoardVariant.allCases) { variant in
                                variantButton(variant)
                            }
                        }
                    }

                    // Scrabble values preview
                    sectionCard(title: "Letter Values (\(selectedLanguage.rawValue))") {
                        scrabblePreview
                    }

                    // Start button
                    startButton
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 6) {
            Text("SlideWords")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.22))
            Text("slide tiles · form words · score big")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.top, 10)
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
    }

    // MARK: - Language Row

    private func languageRow(_ lang: GameLanguage) -> some View {
        let selected = selectedLanguage == lang
        return Button(action: { selectedLanguage = lang }) {
            HStack(spacing: 14) {
                Text(lang.flag)
                    .font(.system(size: 26))
                Text(lang.rawValue)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(selected ? .white : Color(red: 0.18, green: 0.18, blue: 0.22))
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selected ? accentBlue : Color(red: 0.95, green: 0.95, blue: 0.97))
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: selected)
    }

    // MARK: - Board Variant Button

    private func variantButton(_ variant: BoardVariant) -> some View {
        let selected = selectedVariant == variant
        return Button(action: { selectedVariant = variant }) {
            VStack(spacing: 6) {
                Text(variant.displayName)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(selected ? .white : accentBlue)
                Text(variant.label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(selected ? .white.opacity(0.85) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? cardBlue : Color(red: 0.93, green: 0.95, blue: 1.0))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(selected ? cardBlue : Color(red: 0.80, green: 0.84, blue: 0.95), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.2), value: selected)
    }

    // MARK: - Scrabble Values Preview

    private var scrabblePreview: some View {
        let values = selectedLanguage.scrabbleValues
        // Show a compact grid of letter values (only the letters in our spawn alphabet)
        let letters: [Character] = ["a","e","i","o","r","t","n","s","l","c","d","h","m","p","b","f","g","k","w"]

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 8) {
            ForEach(letters, id: \.self) { letter in
                VStack(spacing: 2) {
                    Text(String(letter).uppercased())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.22))
                    Text("\(values[letter] ?? 1)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(letterColor(letter))
                )
            }
        }
    }

    private func letterColor(_ letter: Character) -> Color {
        switch letter {
        case "a","e","i","o": return Color(red: 0.96, green: 0.87, blue: 0.70)
        case "r","t","n","s","l": return Color(red: 0.75, green: 0.88, blue: 0.96)
        default: return Color(red: 0.90, green: 0.94, blue: 0.90)
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button(action: {
            let settings = GameSettings(language: selectedLanguage, boardVariant: selectedVariant)
            onStart(settings)
        }) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                Text("Start Game")
            }
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [cardBlue, accentBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: accentBlue.opacity(0.45), radius: 12, x: 0, y: 5)
            )
        }
        .padding(.bottom, 8)
    }
}

#Preview("Menu") {
    MenuView(onStart: { _ in })
}

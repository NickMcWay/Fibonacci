// TileView.swift
// Renders a single letter tile with:
//   - Rounded rectangle background
//   - Bold centered letter
//   - Spawn scale-in animation (isNew flag)
//   - Clear pop-out animation (isClearing flag)
//   - Subtle shadow for depth

import SwiftUI

struct TileView: View {
    let tile: Tile
    let size: CGFloat

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(tileColor(for: tile.letter))
                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)

            Text(String(tile.letter).uppercased())
                .font(.system(size: size * 0.44, weight: .bold, design: .rounded))
                .foregroundColor(textColor(for: tile.letter))
        }
        .frame(width: size, height: size)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            if tile.isNew {
                scale = 0.01
                opacity = 0
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
        .onChange(of: tile.isClearing) { _, clearing in
            if clearing {
                withAnimation(.easeOut(duration: 0.2)) {
                    scale = 1.3
                    opacity = 0
                }
            }
        }
    }

    // MARK: - Color Palette
    // Calm, modern palette — different hue groups per vowel/consonant category.

    private func tileColor(for letter: Character) -> Color {
        switch letter.lowercased() {
        case "a", "e", "i", "o", "u":
            return Color(red: 0.96, green: 0.87, blue: 0.70)  // warm amber — vowels
        case "r", "t", "n", "s", "l":
            return Color(red: 0.75, green: 0.88, blue: 0.96)  // cool blue — common consonants
        case "c", "d", "h", "m", "p":
            return Color(red: 0.82, green: 0.94, blue: 0.82)  // soft green — secondary
        default:
            return Color(red: 0.90, green: 0.83, blue: 0.96)  // lavender — tertiary
        }
    }

    private func textColor(for letter: Character) -> Color {
        Color(red: 0.18, green: 0.18, blue: 0.22)  // near-black, highly readable
    }
}

// MARK: - Preview

#Preview("Tile - Vowel") {
    TileView(tile: Tile(letter: "A", row: 0, col: 0), size: 72)
        .padding()
}

#Preview("Tile - Consonant") {
    TileView(tile: Tile(letter: "T", row: 0, col: 1), size: 72)
        .padding()
}

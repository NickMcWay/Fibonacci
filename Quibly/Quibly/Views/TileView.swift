// TileView.swift
// Renders a single letter tile with:
//   - Rounded rectangle background (colour keyed to letter category)
//   - Scrabble point value badge in the top-right corner
//   - Spawn scale-in animation (isNew flag)
//   - Clear pop-out animation (isClearing flag)
//   - Draw-selection highlight (isSelected flag)
//   - Pending-confirmation glow pulse (isPending flag)

import SwiftUI

struct TileView: View {
    let tile: Tile
    let size: CGFloat
    var isSelected: Bool = false
    var isPending: Bool = false
    var scrabbleValue: Int? = nil   // shown as a small badge; nil hides it

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var glowOpacity: Double = 0.5

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.20)
                .fill(tileColor(for: tile.letter))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.20)
                        .stroke(Color.white.opacity(0.65), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.14), radius: 8, x: 0, y: 5)

            // White wash + border while finger is tracing this tile
            if isSelected {
                RoundedRectangle(cornerRadius: size * 0.20)
                    .fill(Color.white.opacity(0.35))
                RoundedRectangle(cornerRadius: size * 0.20)
                    .strokeBorder(Color.white, lineWidth: size * 0.07)
            }

            // Pulsing green ring for confirmed-but-not-yet-submitted words
            if isPending {
                RoundedRectangle(cornerRadius: size * 0.20)
                    .strokeBorder(
                        Color(red: 1.00, green: 0.89, blue: 0.38),
                        lineWidth: size * 0.10
                    )
                    .opacity(glowOpacity)
                    .onAppear {
                        glowOpacity = 0.5
                        withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                            glowOpacity = 1.0
                        }
                    }
            }

            Text(tile.isJoker ? "★" : String(tile.letter).uppercased())
                .font(.system(size: size * 0.44, weight: .bold, design: .rounded))
                .foregroundColor(textColor(for: tile.letter, isPending: isPending))

            if tile.hasCoin {
                Image(systemName: "centsign.circle.fill")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundColor(Color(red: 0.93, green: 0.70, blue: 0.12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.bottom, size * 0.08)
                    .padding(.trailing, size * 0.08)
            }

            // Scrabble point value — small superscript in top-right corner
            if let value = scrabbleValue {
                Text("\(value)")
                    .font(.system(size: size * 0.20, weight: .bold, design: .rounded))
                    .foregroundColor(textColor(for: tile.letter, isPending: isPending).opacity(0.60))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, size * 0.07)
                    .padding(.trailing, size * 0.07)
            }
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

    private func tileColor(for letter: Character) -> Color {
        if isPending {
            return Color(red: 0.98, green: 0.82, blue: 0.30)
        }
        return Color(red: 0.98, green: 0.95, blue: 0.93)
    }

    private func textColor(for letter: Character, isPending: Bool) -> Color {
        isPending ? Color(red: 0.44, green: 0.26, blue: 0.11) : Color(red: 0.23, green: 0.20, blue: 0.47)
    }
}

// MARK: - Previews

#Preview("Tile - Vowel with value") {
    TileView(tile: Tile(letter: "A", row: 0, col: 0), size: 72, scrabbleValue: 1)
        .padding()
}

#Preview("Tile - Selected") {
    TileView(tile: Tile(letter: "C", row: 0, col: 0), size: 72, isSelected: true, scrabbleValue: 3)
        .padding()
}

#Preview("Tile - Pending") {
    TileView(tile: Tile(letter: "T", row: 0, col: 1), size: 72, isPending: true, scrabbleValue: 1)
        .padding()
}

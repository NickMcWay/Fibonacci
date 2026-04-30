// TileView.swift
// Renders a single letter tile with Quibly's puffy, candy aesthetic.

import SwiftUI

struct TileView: View {
    let tile: Tile
    let size: CGFloat
    var isSelected: Bool = false
    var isPending: Bool = false
    var scrabbleValue: Int? = nil
    var temporaryResolvedLetter: Character? = nil

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var glowOpacity: Double = 0.5

    var body: some View {
        ZStack {
            // Base tile shape
            RoundedRectangle(cornerRadius: size * 0.20)
                .fill(tileBackground)
                .overlay(
                    // Inner top sheen
                    RoundedRectangle(cornerRadius: size * 0.20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.80), Color.white.opacity(0.10)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: shadowColor.opacity(0.28), radius: 0, x: 0, y: size * 0.06)
                .shadow(color: shadowColor.opacity(0.12), radius: size * 0.12, x: 0, y: size * 0.10)

            // Selected state: white wash
            if isSelected {
                RoundedRectangle(cornerRadius: size * 0.20)
                    .fill(Color.white.opacity(0.30))
                RoundedRectangle(cornerRadius: size * 0.20)
                    .strokeBorder(Color.white, lineWidth: size * 0.07)
            }

            // Pending (hint) glow: pulsing gold ring
            if isPending {
                RoundedRectangle(cornerRadius: size * 0.20)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.qSun1, Color.qSun2],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
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

            // Letter
            Text(displayedLetter)
                .font(.system(size: size * 0.44, weight: .bold, design: .rounded))
                .foregroundStyle(letterColor)
                .opacity(jokerLetterOpacity)
                .shadow(color: shadowColor.opacity(0.25), radius: 0, x: 0, y: 1)

            // Coin tile indicator
            if tile.hasCoin {
                Image(systemName: "centsign.circle.fill")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(Color(red: 0.93, green: 0.70, blue: 0.12))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.bottom, size * 0.08)
                    .padding(.trailing, size * 0.08)
            }

            // Scrabble point value badge
            if let value = scrabbleValue {
                Text("\(value)")
                    .font(.system(size: size * 0.20, weight: .bold, design: .rounded))
                    .foregroundStyle(letterColor.opacity(0.55))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, size * 0.07)
                    .padding(.trailing, size * 0.07)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(isSelected ? 1.06 : scale)
        .opacity(opacity)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isSelected)
        .onAppear {
            if tile.isNew {
                scale = 0.01
                opacity = 0
                withAnimation(.spring(response: 0.32, dampingFraction: 0.58)) {
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

    // MARK: - Computed Properties

    private var displayedLetter: String {
        if tile.isJoker, let resolved = (tile.jokerResolvedLetter ?? temporaryResolvedLetter) {
            return String(resolved).uppercased()
        }
        return tile.isJoker ? "★" : String(tile.letter).uppercased()
    }

    private var jokerLetterOpacity: Double {
        (tile.isJoker && (tile.jokerResolvedLetter != nil || temporaryResolvedLetter != nil)) ? 0.65 : 1.0
    }

    private var tileBackground: LinearGradient {
        if isPending {
            return LinearGradient(
                colors: [Color.qSun1, Color(red: 1, green: 0.78, blue: 0.22)],
                startPoint: .top, endPoint: .bottom
            )
        }
        if tile.isJoker {
            return LinearGradient(
                colors: [Color.qGrape1, Color.qGrape2],
                startPoint: .top, endPoint: .bottom
            )
        }
        if isSelected {
            return LinearGradient(
                colors: [Color.qSun1.opacity(0.9), Color.qSun2.opacity(0.9)],
                startPoint: .top, endPoint: .bottom
            )
        }
        // Default cream tile
        return LinearGradient(
            colors: [Color.qCream, Color(red: 1.0, green: 0.95, blue: 0.88)],
            startPoint: .top, endPoint: .bottom
        )
    }

    private var letterColor: Color {
        if isPending   { return Color.qGoldDeep }
        if tile.isJoker { return .white }
        if isSelected  { return Color.qGoldDeep }
        return Color.qInk
    }

    private var shadowColor: Color {
        if tile.isJoker { return Color.qGrape2 }
        return Color.qInk
    }
}

// MARK: - Previews

#Preview("Tile - Normal") {
    TileView(tile: Tile(letter: "A", row: 0, col: 0), size: 72, scrabbleValue: 1)
        .padding()
        .background(Color.qPeach1)
}

#Preview("Tile - Selected") {
    TileView(tile: Tile(letter: "C", row: 0, col: 0), size: 72, isSelected: true, scrabbleValue: 3)
        .padding()
        .background(Color.qPeach1)
}

#Preview("Tile - Pending") {
    TileView(tile: Tile(letter: "T", row: 0, col: 1), size: 72, isPending: true, scrabbleValue: 1)
        .padding()
        .background(Color.qPeach1)
}

#Preview("Tile - Joker") {
    var joker = Tile(letter: "*", row: 0, col: 0)
    joker.isJoker = true
    return TileView(tile: joker, size: 72)
        .padding()
        .background(Color.qPeach1)
}

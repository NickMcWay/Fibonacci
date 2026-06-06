# Quibly

**Quibly** is an iOS word-puzzle game that blends the satisfying tile-sliding of 2048 with the vocabulary challenge of a classic letter game.

## How it works

The board starts with a few letter tiles. Each swipe — up, down, left, or right — slides all tiles to that edge, then spawns a new letter in a vacant spot. Whenever valid words appear in a row or column after the slide, those tiles are highlighted and can be confirmed for points. Cleared tiles collapse back in the swipe direction, potentially triggering chain reactions that earn combo multipliers.

You can also draw words by tracing a path across adjacent tiles on the board, scoring the word immediately without needing a swipe.

The game ends when the board is completely full and no swipe can move any tile.

## Scoring

Letter values follow Scrabble conventions for the selected language — common vowels are worth 1 point while rare letters like Q and Z score up to 10. Chain reactions multiply the score of each subsequent word cleared in the same turn.

## Features

- **Three board sizes** — Classic (4×4), Extended (5×5), Challenge (6×6)
- **Five languages** — English, Dutch, German, French, Spanish, each with their own letter frequency and point values
- **Hint system** — if a word is waiting to be confirmed, a power-up button appears after 5 seconds; after 10 seconds the matching tiles glow automatically
- **Drawn-word mode** — trace any path of adjacent tiles to spell and score a word directly
- **Best-score tracking** — your all-time high score is saved across sessions
- **Haptic feedback** — light, medium, and heavy taps reflect the weight of each action

## Tech

Built with SwiftUI (iOS) using an MVVM architecture. Game logic is fully separated from the UI in pure value-type models (`BoardModel`, `GameEngine`, `WordValidator`, `LetterSpawnEngine`), making the core easy to test independently.

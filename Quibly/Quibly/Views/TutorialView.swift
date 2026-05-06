import SwiftUI

// MARK: - Tutorial Step Model

private struct TutorialStep {
    let icon: String
    let iconColors: [Color]
    let title: LocalizedStringKey
    let body: LocalizedStringKey
    let illustration: AnyView?

    init(icon: String, iconColors: [Color], title: LocalizedStringKey, body: LocalizedStringKey, illustration: AnyView? = nil) {
        self.icon = icon
        self.iconColors = iconColors
        self.title = title
        self.body = body
        self.illustration = illustration
    }
}

// MARK: - Tutorial View

struct TutorialView: View {
    var onDismiss: () -> Void

    @State private var currentStep = 0
    @State private var direction: Int = 1  // 1 = forward, -1 = back
    @AppStorage("SlideWords_SelectedLanguage") private var selectedLanguageRaw: String = GameLanguage.english.rawValue

    private let languageStepIndex = 1

    private let steps: [TutorialStep] = [
        TutorialStep(
            icon: "hand.wave.fill",
            iconColors: [Color.qSun1, Color.qSun2],
            title: "Welcome to Quibly!",
            body: "A word-sliding puzzle game. Slide tiles across the board to form words and score points."
        ),
        TutorialStep(
            icon: "globe",
            iconColors: [Color.qGrape1, Color.qGrape2],
            title: "Choose Your Language",
            body: "Words are validated in your chosen language. You can change this any time in Settings."
        ),
        TutorialStep(
            icon: "square.grid.2x2.fill",
            iconColors: [Color.qGrape1, Color.qGrape2],
            title: "The Board",
            body: "Tiles sit on a grid. Each tile carries a letter with a point value — rarer letters score more.",
            illustration: AnyView(BoardIllustration())
        ),
        TutorialStep(
            icon: "arrow.left.arrow.right",
            iconColors: [Color.qSky1, Color.qSky2],
            title: "Swipe to Slide",
            body: "Swipe left, right, up, or down to slide all tiles in that direction. A new tile spawns after each valid swipe.",
            illustration: AnyView(SwipeIllustration())
        ),
        TutorialStep(
            icon: "checkmark.circle.fill",
            iconColors: [Color.qMint1, Color.qMint2],
            title: "Form Words",
            body: "When sliding tiles creates a valid word in a row or column, those tiles clear and you earn points. Longer words score bigger!"
        ),
        TutorialStep(
            icon: "bolt.fill",
            iconColors: [Color.qCoral1, Color.qCoral2],
            title: "Power-Ups",
            body: "Use Hint, Shuffle, Joker, and Bomb to get out of tough spots. Earn coins by clearing tiles to buy more.",
            illustration: AnyView(PowerUpIllustration())
        ),
        TutorialStep(
            icon: "play.fill",
            iconColors: [Color.qSun1, Color.qSun2],
            title: "You're Ready!",
            body: "Swipe smart, clear the board, and chase the high score. Good luck!"
        )
    ]

    var body: some View {
        DreamBackground {
            VStack(spacing: 0) {
                Spacer()

                // Card
                VStack(spacing: 24) {
                    stepIcon
                    stepText
                    if currentStep == languageStepIndex {
                        LanguagePicker(selectedRaw: $selectedLanguageRaw)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    } else if let illustration = steps[currentStep].illustration {
                        illustration
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                    progressDots
                    actionButtons
                }
                .padding(28)
                .qCard(cornerRadius: 32)
                .padding(.horizontal, 24)
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentStep)

                Spacer()
            }
            .overlay(alignment: .topTrailing) {
                Button(action: onDismiss) {
                    Text("Skip")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.qInk.opacity(0.65))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.6))
                                .overlay(Capsule().stroke(Color.white.opacity(0.85), lineWidth: 1))
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 56)
                .padding(.trailing, 20)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Icon

    private var stepIcon: some View {
        let step = steps[currentStep]
        return ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: step.iconColors,
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .shadow(color: step.iconColors.last?.opacity(0.45) ?? .clear, radius: 0, x: 0, y: 4)
                .shadow(color: step.iconColors.last?.opacity(0.2) ?? .clear, radius: 12, x: 0, y: 6)
            Image(systemName: step.icon)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 80, height: 80)
        .id("icon-\(currentStep)")
        .transition(.scale(scale: 0.6).combined(with: .opacity))
    }

    // MARK: - Text

    private var stepText: some View {
        let step = steps[currentStep]
        return VStack(spacing: 10) {
            Text(step.title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.qInk)
                .multilineTextAlignment(.center)
            Text(step.body)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.qInkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .id("text-\(currentStep)")
        .transition(.opacity)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<steps.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentStep
                        ? LinearGradient(colors: steps[currentStep].iconColors, startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [Color.qInk.opacity(0.18), Color.qInk.opacity(0.18)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: i == currentStep ? 22 : 7, height: 7)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentStep)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        let isLast = currentStep == steps.count - 1
        return VStack(spacing: 10) {
            Button(action: advance) {
                HStack(spacing: 8) {
                    if isLast {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                    }
                    Text(isLast ? "Let's Play!" : "Next")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.qGoldDeep)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(PuffyButtonStyle(variant: .gold))

            if currentStep > 0 {
                Button(action: goBack) {
                    Text("Back")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.qInk.opacity(0.55))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Navigation

    private func advance() {
        direction = 1
        if currentStep < steps.count - 1 {
            withAnimation { currentStep += 1 }
        } else {
            onDismiss()
        }
    }

    private func goBack() {
        direction = -1
        if currentStep > 0 {
            withAnimation { currentStep -= 1 }
        }
    }
}

// MARK: - Board Illustration

private struct BoardIllustration: View {
    private let letters: [[(String, Bool)]] = [
        [("Q", false), ("U", false), ("I", true), ("B", true)],
        [("L", false), ("P", true), ("L", true), ("A", false)],
        [("P", false), ("A", false), ("Y", false), ("R", false)]
    ]

    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { r in
                HStack(spacing: 5) {
                    ForEach(0..<4, id: \.self) { c in
                        miniTile(letter: letters[r][c].0, highlighted: letters[r][c].1)
                    }
                }
            }
        }
        .padding(10)
        .qCard(cornerRadius: 20)
    }

    private func miniTile(letter: String, highlighted: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(highlighted
                    ? LinearGradient(colors: [Color.qSun1, Color.qSun2], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [Color.qCream, Color(red: 1, green: 0.95, blue: 0.88)], startPoint: .top, endPoint: .bottom)
                )
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.75), lineWidth: 1))
                .shadow(color: Color.qInk.opacity(0.15), radius: 0, x: 0, y: 2)
            Text(letter)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(highlighted ? Color.qGoldDeep : Color.qInk)
        }
        .frame(width: 38, height: 38)
    }
}

// MARK: - Swipe Illustration

private struct SwipeIllustration: View {
    private let letters = ["W", "O", "R", "D"]
    private let tileSize: CGFloat = 42
    private let gap: CGFloat = 6

    @State private var progress: CGFloat = 0

    private var totalWidth: CGFloat { CGFloat(letters.count) * tileSize + CGFloat(letters.count - 1) * gap }
    private func cx(_ i: Int) -> CGFloat { CGFloat(i) * (tileSize + gap) + tileSize / 2 }
    private var startX: CGFloat { cx(0) }
    private var endX: CGFloat { cx(letters.count - 1) }
    private var fingerX: CGFloat { startX + progress * (endX - startX) }

    private func isHighlighted(_ i: Int) -> Bool {
        progress >= CGFloat(i) / CGFloat(letters.count - 1)
    }

    var body: some View {
        ZStack {
            // Drawn line behind tiles
            Path { p in
                p.move(to: CGPoint(x: startX, y: tileSize / 2))
                p.addLine(to: CGPoint(x: endX, y: tileSize / 2))
            }
            .trim(from: 0, to: progress)
            .stroke(
                LinearGradient(colors: [Color.qSky1, Color.qSky2], startPoint: .leading, endPoint: .trailing),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )

            // Tiles
            HStack(spacing: gap) {
                ForEach(Array(letters.enumerated()), id: \.offset) { i, letter in
                    swipeTile(letter: letter, highlighted: isHighlighted(i))
                }
            }

            // Finger circle
            Circle()
                .fill(Color.qSky1.opacity(0.4))
                .overlay(Circle().stroke(Color.qSky2, lineWidth: 2.5))
                .shadow(color: Color.qSky2.opacity(0.4), radius: 6, x: 0, y: 2)
                .frame(width: tileSize + 10, height: tileSize + 10)
                .offset(x: fingerX - totalWidth / 2)
        }
        .frame(width: totalWidth, height: tileSize)
        .padding(.horizontal, 16).padding(.vertical, 14)
        .qCard(cornerRadius: 20)
        .onAppear { runLoop() }
    }

    private func runLoop() {
        progress = 0
        withAnimation(.easeInOut(duration: 1.4).delay(0.3)) {
            progress = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeIn(duration: 0.15)) { progress = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { runLoop() }
        }
    }

    private func swipeTile(letter: String, highlighted: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(highlighted
                    ? LinearGradient(colors: [Color.qSun1, Color.qSun2], startPoint: .top, endPoint: .bottom)
                    : LinearGradient(colors: [Color.qCream, Color(red: 1, green: 0.95, blue: 0.88)], startPoint: .top, endPoint: .bottom)
                )
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.75), lineWidth: 1))
                .shadow(color: Color.qInk.opacity(0.15), radius: 0, x: 0, y: 2)
            Text(letter)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(highlighted ? Color.qGoldDeep : Color.qInk)
        }
        .frame(width: tileSize, height: tileSize)
        .animation(.easeInOut(duration: 0.15), value: highlighted)
    }
}

// MARK: - Power-Up Illustration

private struct PowerUpIllustration: View {
    private let powerUps: [(String, [Color], LocalizedStringKey)] = [
        ("lightbulb.fill", [Color.qSun1, Color.qSun2], "Hint"),
        ("shuffle",        [Color.qSky1, Color.qSky2], "Shuffle"),
        ("wand.and.stars", [Color.qGrape1, Color.qGrape2], "Joker"),
        ("burst.fill",     [Color.qCoral1, Color.qCoral2], "Bomb")
    ]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(powerUps, id: \.0) { pu in
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: pu.1, startPoint: .top, endPoint: .bottom))
                            .shadow(color: pu.1.last?.opacity(0.35) ?? .clear, radius: 0, x: 0, y: 3)
                        Image(systemName: pu.0)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 36, height: 36)
                    Text(pu.2)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.qInkSoft)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .qCard(cornerRadius: 20)
    }
}

// MARK: - Language Picker

private struct LanguagePicker: View {
    @Binding var selectedRaw: String

    var body: some View {
        VStack(spacing: 6) {
            ForEach(GameLanguage.allCases) { language in
                let isSelected = selectedRaw == language.rawValue
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedRaw = language.rawValue
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text(language.flag)
                            .font(.system(size: 22))
                        Text(language.displayName)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(isSelected ? Color.qGrape2 : Color.qInk)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.qGrape2)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected
                                ? LinearGradient(colors: [Color.qGrape1.opacity(0.25), Color.qGrape2.opacity(0.12)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.white.opacity(0.5), Color.white.opacity(0.4)], startPoint: .leading, endPoint: .trailing)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? Color.qGrape1.opacity(0.6) : Color.white.opacity(0.6), lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview("Tutorial") {
    TutorialView(onDismiss: {})
        .environmentObject(AudioManager())
}

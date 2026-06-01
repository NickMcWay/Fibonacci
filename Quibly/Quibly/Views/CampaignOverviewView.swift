import SwiftUI

struct CampaignOverviewView: View {
    let language: GameLanguage
    let isSweep: Bool
    var onBack: () -> Void
    var onStart: (GameSettings) -> Void

    @Environment(\.dismiss) private var dismiss

    private var maxUnlocked: Int { CampaignProgress.maxUnlockedLevel(sweep: isSweep) }
    private let totalDisplayed = 20

    private var accentGradient: [Color] {
        isSweep
            ? [Color(red:0.28,green:0.72,blue:0.52), Color(red:0.14,green:0.54,blue:0.40)]
            : [Color(red:0.98,green:0.55,blue:0.25), Color(red:0.88,green:0.28,blue:0.18)]
    }

    var body: some View {
        NavigationView {
            DreamBackground {
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 110)
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
                        ) {
                            ForEach(1...totalDisplayed, id: \.self) { level in
                                levelCell(level: level)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    QCircleButton(size: 40, action: { dismiss(); onBack() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.qInk)
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(isSweep ? "Sweep" : "Campaign")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.qInk.opacity(0.4), radius: 0, x: 0, y: 2)
                        Text("Choose a level")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .shadow(color: Color.qInk.opacity(0.3), radius: 0, x: 0, y: 1)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func levelCell(level: Int) -> some View {
        let unlocked  = level <= maxUnlocked
        let completed = level < maxUnlocked
        let best      = CampaignProgress.bestScore(level: level, sweep: isSweep)
        let target    = isSweep ? nil as Int? : LevelDifficulty.campaignTargetScore(level: level)

        Button {
            guard unlocked else { return }
            dismiss()
            let settings = GameSettings(
                language: language,
                boardVariant: .small,
                gameMode: isSweep ? .sweep : .campaign,
                campaignLevel: level
            )
            onStart(settings)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        unlocked
                            ? LinearGradient(colors: accentGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                completed ? Color.white.opacity(0.7) : Color.white.opacity(0.25),
                                lineWidth: completed ? 2 : 1
                            )
                    )
                    .shadow(
                        color: unlocked ? accentGradient.last!.opacity(0.35) : Color.clear,
                        radius: 8, x: 0, y: 4
                    )

                VStack(spacing: 6) {
                    if completed {
                        Text("✓")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(Color.white)
                    } else if unlocked {
                        Text(isSweep ? "🧹" : "🏆")
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }

                    Text("\(level)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(unlocked ? Color.white : Color.white.opacity(0.4))

                    if completed && best > 0 {
                        Text(isSweep ? "\(best)▾" : "\(best)pt")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .lineLimit(1)
                    } else if let t = target, unlocked {
                        Text("→\(t)")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                }
                .padding(.vertical, 14)
            }
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .opacity(unlocked ? 1.0 : 0.55)
    }
}

#Preview {
    CampaignOverviewView(
        language: .english,
        isSweep: false,
        onBack: {},
        onStart: { _ in }
    )
}

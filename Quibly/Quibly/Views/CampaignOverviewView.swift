import SwiftUI

// MARK: - Campaign Progress Persistence

enum CampaignProgress {
    private static let key = "SlideWords_CompletedCampaignLevels"

    static var completedLevels: Set<Int> {
        let arr = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        return Set(arr)
    }

    static func markCompleted(level: Int) {
        var levels = completedLevels
        levels.insert(level)
        UserDefaults.standard.set(Array(levels), forKey: key)
    }

    static var highestReached: Int {
        (UserDefaults.standard.integer(forKey: "SlideWords_CampaignLevel")).clamped(to: 1...999)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Campaign Overview View

struct CampaignOverviewView: View {
    let language: GameLanguage
    var onBack: () -> Void
    var onStartLevel: (GameSettings) -> Void

    @State private var completedLevels: Set<Int> = CampaignProgress.completedLevels
    @State private var highestReached: Int = max(1, CampaignProgress.highestReached)

    private let totalLevels = 20

    private func isCompleted(_ level: Int) -> Bool { completedLevels.contains(level) }
    private func isUnlocked(_ level: Int) -> Bool { level <= highestReached }

    var body: some View {
        NavigationView {
            DreamBackground {
                ZStack(alignment: .top) {
                    ScrollView {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 110)
                            levelGrid
                                .padding(.horizontal, 16)
                                .padding(.bottom, 40)
                        }
                    }
                }
            }
            .onAppear {
                completedLevels = CampaignProgress.completedLevels
                highestReached = max(1, CampaignProgress.highestReached)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    QCircleButton(size: 40, action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.qInk)
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Campaign")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.qInk.opacity(0.4), radius: 0, x: 0, y: 2)
                        Text("Level by level · rising stakes")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .shadow(color: Color.qInk.opacity(0.3), radius: 0, x: 0, y: 1)
                    }
                }
            }
        }
    }

    private var levelGrid: some View {
        VStack(spacing: 16) {
            // Progress header
            progressHeader

            // Level cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(1...totalLevels, id: \.self) { level in
                    levelCard(level)
                }
            }

            // Endless hint
            Text("More levels unlock as you progress")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.6))
                .padding(.top, 4)
        }
    }

    private var progressHeader: some View {
        let completed = completedLevels.filter { $0 <= totalLevels }.count
        return VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(completed) / \(totalLevels) Levels")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.qInk)
                    Text("Completed")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.qInk.opacity(0.6))
                }
                Spacer()
                Text("🏆")
                    .font(.system(size: 32))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.qInk.opacity(0.12))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [Color(red:0.98,green:0.55,blue:0.25), Color(red:0.88,green:0.28,blue:0.18)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * CGFloat(completed) / CGFloat(totalLevels), height: 10)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: completed)
                }
            }
            .frame(height: 10)
        }
        .padding(14)
        .qCard(cornerRadius: 20)
    }

    private func levelCard(_ level: Int) -> some View {
        let completed = isCompleted(level)
        let unlocked  = isUnlocked(level)
        let isCurrent = level == highestReached && !completed

        let gradient: [Color] = completed
            ? [Color(red:0.28,green:0.72,blue:0.52), Color(red:0.14,green:0.54,blue:0.40)]
            : isCurrent
                ? [Color(red:0.98,green:0.55,blue:0.25), Color(red:0.88,green:0.28,blue:0.18)]
                : [Color.white.opacity(0.55), Color.white.opacity(0.40)]

        return Button {
            guard unlocked else { return }
            let settings = GameSettings(
                language: language,
                boardVariant: .small,
                gameMode: .campaign,
                campaignStartLevel: level
            )
            onStartLevel(settings)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.white)
                    } else if unlocked {
                        Text("\(level)")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }
                .frame(height: 34)

                Text("Lvl \(level)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(unlocked ? Color.white.opacity(0.9) : Color.qInk.opacity(0.5))

                Text(targetLabel(level))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(unlocked ? Color.white.opacity(0.75) : Color.qInk.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isCurrent ? Color.white.opacity(0.9) : Color.white.opacity(0.3),
                                lineWidth: isCurrent ? 2.5 : 1
                            )
                    )
                    .shadow(color: gradient.last!.opacity(unlocked ? 0.3 : 0.0), radius: 0, x: 0, y: 4)
            )
            .opacity(unlocked ? 1.0 : 0.5)
            .scaleEffect(isCurrent ? 1.04 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.68), value: isCurrent)
        }
        .buttonStyle(ModeTileButtonStyle())
        .disabled(!unlocked)
    }

    private func targetLabel(_ level: Int) -> String {
        let pts = LevelDifficulty.campaignTargetScore(level: level)
        return pts >= 1000 ? String(format: "%.1fk pts", Double(pts) / 1000) : "\(pts) pts"
    }
}

// MARK: - Reuse ModeTileButtonStyle locally

private struct ModeTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

#Preview("Campaign Overview") {
    CampaignOverviewView(
        language: .english,
        onBack: {},
        onStartLevel: { _ in }
    )
}

import SwiftUI

struct SettingsView: View {
    var onBack: (() -> Void)?

    @EnvironmentObject private var audio: AudioManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage("SlideWords_SoundEnabled")   private var soundOn:   Bool   = true
    @AppStorage("SlideWords_MusicEnabled")   private var musicOn:   Bool   = true
    @AppStorage("SlideWords_HapticsEnabled") private var hapticsOn: Bool   = true
    @AppStorage("SlideWords_AutoHints")      private var autoHints: Bool   = true
    @AppStorage("SlideWords_DarkMode")       private var darkMode:  Bool   = false
    @AppStorage("SlideWords_SelectedLanguage") private var selectedLanguageRaw: String = GameLanguage.english.rawValue
    @AppStorage("SlideWords_SelectedVariant")  private var selectedVariantRaw:  Int    = BoardVariant.small.rawValue

    private var selectedLanguage: GameLanguage { GameLanguage(rawValue: selectedLanguageRaw) ?? .english }
    private var selectedVariant:  BoardVariant  { BoardVariant(rawValue: selectedVariantRaw)  ?? .small }

    var body: some View {
        NavigationView{
            DreamBackground {
                ZStack(alignment: .top) {
                    // Scrollable settings
                    ScrollView {
                        VStack(spacing: 0) {
                            Spacer().frame(height: 160)
                            
                            VStack(spacing: 0) {
                                settingsGroup(title: "Audio & Haptics") {
                                    toggleRow(icon: "speaker.wave.2.fill", label: "Sound effects",
                                              binding: Binding(get: { soundOn }, set: { v in soundOn = v; audio.isSoundEnabled = v }))
                                    toggleRow(icon: "music.note", label: "Music",
                                              binding: Binding(get: { musicOn }, set: { v in musicOn = v; audio.isMusicEnabled = v }))
                                    toggleRow(icon: "waveform", label: "Haptics", binding: $hapticsOn)
                                }
                                
                                settingsGroup(title: "Gameplay") {
                                    toggleRow(icon: "lightbulb.fill", label: "Auto-hints", sublabel: "Glow tiles after 10s", binding: $autoHints)
                                    pickerRow(icon: "globe", label: "Language", value: "\(selectedLanguage.flag) \(selectedLanguage.rawValue)")
                                    pickerRow(icon: "square.grid.2x2.fill", label: "Default board", value: "\(selectedVariant.displayName) (\(selectedVariant.label))")
                                }
                                
                                settingsGroup(title: "Look & Feel") {
                                    toggleRow(icon: "moon.fill", label: "Dark mode", sublabel: "Use system setting", binding: $darkMode)
                                    pickerRow(icon: "paintbrush.fill", label: "Tile theme", value: "Cream")
                                    pickerRow(icon: "sun.max.fill", label: "Background", value: "Dawn")
                                }
                                
                                settingsGroup(title: "Account") {
                                    actionRow(icon: "heart.fill", label: "Restore purchases") {}
                                    actionRow(icon: "hand.raised.fill", label: "Privacy") {}
                                    actionRow(icon: "doc.text.fill", label: "Terms of service") {}
                                }
                                
                                Text("Quibly v1.4.2 · made with 💜")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.qInk.opacity(0.55))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 20)
                                    .padding(.bottom, 40)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    
                }
                
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    QCircleButton(size: 40, action: { dismiss(); onBack?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.qInk)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.qInk.opacity(0.4), radius: 0, x: 0, y: 2)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Keep spacing symmetrical with a clear view matching the button size
                    Color.clear.frame(width: 40, height: 40)
                }
            }
        }
    }

    // MARK: - Settings Group

    @ViewBuilder
    private func settingsGroup(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.95))
                .shadow(color: Color.qInk.opacity(0.4), radius: 0, x: 0, y: 1)
                .tracking(0.8)
                .padding(.horizontal, 4)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.82))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.95), lineWidth: 1.5))
                    .shadow(color: Color.qInk.opacity(0.18), radius: 0, x: 0, y: 4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding(.top, 16)
    }

    // MARK: - Toggle Row

    private func toggleRow(icon: String, label: String, sublabel: String? = nil, binding: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.qInk)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qInk)
                if let sub = sublabel {
                    Text(sub)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.qInk.opacity(0.65))
                }
            }

            Spacer()

            QToggle(isOn: binding)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.qInk.opacity(0.08))
                .frame(height: 1)
                .padding(.leading, 56)
        }
    }

    // MARK: - Picker Row

    private func pickerRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.qInk)
                .frame(width: 30)

            Text(label)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.qInk)

            Spacer()

            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.qInk.opacity(0.70))
                Text("›")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.qInk.opacity(0.55))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.qInk.opacity(0.08))
                .frame(height: 1)
                .padding(.leading, 56)
        }
    }

    // MARK: - Action Row (chevron only)

    private func actionRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.qInk)
                    .frame(width: 30)

                Text(label)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.qInk)

                Spacer()

                Text("›")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.qInk.opacity(0.55))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.qInk.opacity(0.08))
                    .frame(height: 1)
                    .padding(.leading, 56)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quibly Toggle Switch

struct QToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn
                        ? LinearGradient(colors: [Color.qMint1, Color.qMint2], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.qInk.opacity(0.18), Color.qInk.opacity(0.12)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 48, height: 28)
                    .overlay(
                        Capsule().stroke(Color.white.opacity(isOn ? 0.5 : 0.3), lineWidth: 1)
                    )
                    .shadow(color: isOn ? Color.qMint2.opacity(0.4) : Color.clear, radius: 0, x: 0, y: 2)

                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: Color.qInk.opacity(0.25), radius: 0, x: 0, y: 2)
                    .padding(2)
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isOn)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Settings") {
    SettingsView(onBack: {})
}

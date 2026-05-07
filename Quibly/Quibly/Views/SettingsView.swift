import SwiftUI

struct SettingsView: View {
    var onBack: (() -> Void)?

    @EnvironmentObject private var audio: AudioManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage("SlideWords_SoundEnabled")   private var soundOn:   Bool   = true
    @AppStorage("SlideWords_MusicEnabled")   private var musicOn:   Bool   = true
    @AppStorage("SlideWords_HapticsEnabled") private var hapticsOn: Bool   = true
    @AppStorage("SlideWords_AutoHints")      private var autoHints: Bool   = true
    @AppStorage("SlideWords_DarkMode")       private var darkMode:  Bool   = false
    @AppStorage("SlideWords_SelectedLanguage") private var selectedLanguageRaw: String = GameLanguage.english.rawValue
    @AppStorage("SlideWords_SelectedVariant")  private var selectedVariantRaw:  Int    = BoardVariant.small.rawValue

    @State private var showLanguagePicker    = false
    @State private var showBoardPicker       = false
    @State private var showThemeAlert        = false
    @State private var showBackgroundAlert   = false
    @State private var showRestoreAlert      = false
    @State private var showPrivacyAlert      = false
    @State private var showTermsAlert        = false

    private var selectedLanguage: GameLanguage { GameLanguage(rawValue: selectedLanguageRaw) ?? .english }
    private var selectedVariant:  BoardVariant  { BoardVariant(rawValue: selectedVariantRaw)  ?? .small }

    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "v\(version)"
        }
        return "v1.0"
    }

    var body: some View {
        NavigationView {
            settingsContent
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
            }
            // Language picker
            .confirmationDialog("Select Language", isPresented: $showLanguagePicker, titleVisibility: .visible) {
                ForEach(GameLanguage.allCases) { lang in
                    Button("\(lang.flag)  \(lang.displayName)") { selectedLanguageRaw = lang.rawValue }
                }
                Button("Cancel", role: .cancel) {}
            }
            // Board size picker
            .confirmationDialog("Select Board Size", isPresented: $showBoardPicker, titleVisibility: .visible) {
                ForEach(BoardVariant.allCases) { variant in
                    Button("\(variant.displayName) — \(variant.label)") { selectedVariantRaw = variant.rawValue }
                }
                Button("Cancel", role: .cancel) {}
            }
            // Coming soon alerts
            .alert("Coming Soon", isPresented: $showThemeAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("More tile themes are on their way in a future update!")
            }
            .alert("Coming Soon", isPresented: $showBackgroundAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Additional backgrounds are coming in a future update!")
            }
            // Restore purchases
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("Restore", role: .none) {}
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Any previous purchases will be restored to your account.")
            }
            // Privacy
            .alert("Privacy Policy", isPresented: $showPrivacyAlert) {
                Button("Open in Browser") {
                    if let url = URL(string: "https://quibly.app/privacy") { openURL(url) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("View the full Quibly Privacy Policy in your browser.")
            }
            // Terms
            .alert("Terms of Service", isPresented: $showTermsAlert) {
                Button("Open in Browser") {
                    if let url = URL(string: "https://quibly.app/terms") { openURL(url) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("View the full Quibly Terms of Service in your browser.")
            }
        }
    }

    // Extracted to help the type-checker
    private var settingsContent: some View {
        DreamBackground {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 160)

                        VStack(spacing: 0) {
                            settingsGroup(title: "Audio & Haptics") {
                                toggleRow(icon: "speaker.wave.2.fill", label: "Sound effects",
                                          binding: Binding<Bool>(get: { soundOn }, set: { v in soundOn = v; audio.isSoundEnabled = v }))
                                toggleRow(icon: "music.note", label: "Music",
                                          binding: Binding<Bool>(get: { musicOn }, set: { v in musicOn = v; audio.isMusicEnabled = v }))
                                toggleRow(icon: "waveform", label: "Haptics", binding: $hapticsOn)
                            }

                            settingsGroup(title: "Gameplay") {
                                toggleRow(icon: "lightbulb.fill", label: "Auto-hints", sublabel: "Glow tiles after 10s", binding: $autoHints)
                                pickerRow(icon: "globe", label: "Language",
                                          value: "\(selectedLanguage.flag) \(selectedLanguage.displayName)") { showLanguagePicker = true }
                                pickerRow(icon: "square.grid.2x2.fill", label: "Default board",
                                          value: selectedVariant.displayName) { showBoardPicker = true }
                            }

                            settingsGroup(title: "Look & Feel") {
//                                toggleRow(icon: "moon.fill", label: "Dark mode", sublabel: "Use system setting", binding: $darkMode)
                                pickerRow(icon: "paintbrush.fill", label: "Tile theme", value: "Cream") { showThemeAlert = true }
                                pickerRow(icon: "sun.max.fill", label: "Background", value: "Dawn") { showBackgroundAlert = true }
                            }

                            settingsGroup(title: "Account") {
                                actionRow(icon: "heart.fill",       label: "Restore purchases")  { showRestoreAlert  = true }
                                actionRow(icon: "hand.raised.fill", label: "Privacy")             { showPrivacyAlert  = true }
                                actionRow(icon: "doc.text.fill",    label: "Terms of service")   { showTermsAlert    = true }
                            }

                            Text("Quibly \(appVersion) · made with 💜")
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
    }

    // MARK: - Settings Group

    @ViewBuilder
    private func settingsGroup(title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .textCase(.uppercase)
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

    private func toggleRow(icon: String, label: LocalizedStringKey, sublabel: LocalizedStringKey? = nil, binding: Binding<Bool>) -> some View {
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

    private func pickerRow(icon: String, label: LocalizedStringKey, value: String, action: @escaping () -> Void) -> some View {
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
        .buttonStyle(.plain)
    }

    // MARK: - Action Row

    private func actionRow(icon: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
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
        .environmentObject(AudioManager())
}

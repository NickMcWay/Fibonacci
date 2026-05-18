// AudioManager.swift
// Background music playback with mute toggle.
// Plays teacup-metronome.mp3 (bundled in the app target).
// Falls back gracefully if the file is missing.

import AVFoundation
import SwiftUI
import Combine
import UIKit

@MainActor
final class AudioManager: ObservableObject {

    @Published var isMuted: Bool {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: muteKey)
            isMuted ? pause() : play()
        }
    }

    @Published var isMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "SlideWords_MusicEnabled")
            if isMusicEnabled && !isMuted { player?.play() } else { player?.pause() }
        }
    }

    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "SlideWords_SoundEnabled")
        }
    }

    private var player: AVAudioPlayer?
    private var correctPlayer: AVAudioPlayer?
    private var wrongPlayer: AVAudioPlayer?
    private var countdownPlayer: AVAudioPlayer?
    private var registerPlayer: AVAudioPlayer?
    private var countdownFadeTask: Task<Void, Never>?
    private var themeObserver: NSObjectProtocol?
    private let muteKey = "SlideWords_IsMuted"
    private let themeKey = "SlideWords_ActiveTheme"

    init() {
        isMuted        = UserDefaults.standard.bool(forKey: "SlideWords_IsMuted")
        isMusicEnabled = UserDefaults.standard.object(forKey: "SlideWords_MusicEnabled") as? Bool ?? true
        isSoundEnabled = UserDefaults.standard.object(forKey: "SlideWords_SoundEnabled") as? Bool ?? true
        let themeID = UserDefaults.standard.string(forKey: "SlideWords_ActiveTheme") ?? "cream"
        setupPlayer(trackName: trackName(for: themeID))
        setupEffects()
        observeThemeChanges()
        NotificationCenter.default.addObserver(forName: .adWillPresent, object: nil, queue: .main) { [weak self] _ in self?.pause() }
        NotificationCenter.default.addObserver(forName: .adDidDismiss,  object: nil, queue: .main) { [weak self] _ in self?.play()  }
    }

    private func trackName(for themeID: String) -> String {
        switch themeID {
        case "mint":      return "Forest Theme"
        case "bubble":    return "Bubblegum Theme"
        case "lemonade":  return "Lemonade Theme"
        case "sky":       return "Sky Theme"
        case "galaxy":    return "Galaxy Theme"
        case "sunset":    return "Sunset Theme"
        default:          return "Main Theme"
        }
    }

    private func observeThemeChanges() {
        themeObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let themeID = UserDefaults.standard.string(forKey: self.themeKey) ?? "cream"
            let track = self.trackName(for: themeID)
            guard track != self.currentTrackName else { return }
            self.switchTrack(to: track)
        }
    }

    private var currentTrackName: String = ""

    private func setupPlayer(trackName: String) {
        currentTrackName = trackName
        if let url = Bundle.main.url(forResource: trackName, withExtension: "mp3") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.volume = 0.35
            player?.prepareToPlay()
        }
        // Configure audio session so the game music can play alongside or
        // respect the system silent switch.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func switchTrack(to trackName: String) {
        let wasPlaying = player?.isPlaying ?? false
        player?.stop()
        setupPlayer(trackName: trackName)
        if wasPlaying { play() }
    }

    private func setupEffects() {
        correctPlayer = loadEffect(named: "Correct")
        wrongPlayer = loadEffect(named: "Wrong")
        countdownPlayer = loadCountdownEffect()
        registerPlayer = loadEffect(named: "RegisterSound")
        registerPlayer?.volume = 1.0
    }

    private func loadEffect(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3"),
              let effectPlayer = try? AVAudioPlayer(contentsOf: url) else {
            return nil
        }
        effectPlayer.numberOfLoops = 0
        effectPlayer.volume = 2.0
        effectPlayer.prepareToPlay()
        return effectPlayer
    }

    func play() {
        guard !isMuted, isMusicEnabled else { return }
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
    }

    func playCorrectSelectionFeedback() {
        playEffect(correctPlayer)
        playSubtleHaptic(intensity: 0.55)
    }

    func playWrongSelectionFeedback() {
        playEffect(wrongPlayer)
        playSubtleHaptic(intensity: 0.45)
    }

    private func playEffect(_ effectPlayer: AVAudioPlayer?) {
        guard !isMuted, isSoundEnabled else { return }
        guard let effectPlayer else { return }
        effectPlayer.currentTime = 0
        effectPlayer.play()
    }

    private func playSubtleHaptic(intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    func playRegisterSound() {
        playEffect(registerPlayer)
        playSubtleHaptic(intensity: 0.65)
    }

    func toggleMute() {
        isMuted.toggle()
    }

    // MARK: - Countdown Sound

    private func loadCountdownEffect() -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: "Countdown", withExtension: "mp3"),
              let p = try? AVAudioPlayer(contentsOf: url) else { return nil }
        p.numberOfLoops = 0
        p.volume = 1.0
        p.prepareToPlay()
        return p
    }

    func playCountdownSound() {
        guard !isMuted, isSoundEnabled else { return }
        countdownFadeTask?.cancel()
        countdownFadeTask = nil
        countdownPlayer?.volume = 1.0
        countdownPlayer?.currentTime = 0
        countdownPlayer?.play()
    }

    func fadeOutCountdownSound(duration: TimeInterval = 0.2) {
        countdownFadeTask?.cancel()
        guard let p = countdownPlayer, p.isPlaying else { return }
        p.setVolume(0, fadeDuration: duration)
        countdownFadeTask = Task {
            try? await Task.sleep(nanoseconds: UInt64((duration + 0.05) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            p.stop()
            p.volume = 1.0
        }
    }
}

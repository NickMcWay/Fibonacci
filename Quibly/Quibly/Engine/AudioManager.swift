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
    private let muteKey = "SlideWords_IsMuted"

    init() {
        isMuted        = UserDefaults.standard.bool(forKey: "SlideWords_IsMuted")
        isMusicEnabled = UserDefaults.standard.object(forKey: "SlideWords_MusicEnabled") as? Bool ?? true
        isSoundEnabled = UserDefaults.standard.object(forKey: "SlideWords_SoundEnabled") as? Bool ?? true
        setupPlayer()
        setupEffects()
    }

    private func setupPlayer() {
        // Primary track — teacup metronome loop bundled with the app.
        // Falls back to any other audio file found in the bundle.
        let candidates = [
            ("teacup-metronome", "mp3"),
            ("background_music", "mp3"),
            ("background_music", "wav"),
            ("background_music", "m4a"),
            ("music", "mp3"),
        ]
        for (name, ext) in candidates {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                player = try? AVAudioPlayer(contentsOf: url)
                player?.numberOfLoops = -1  // loop indefinitely
                player?.volume = 0.35
                player?.prepareToPlay()
                break
            }
        }
        // Configure audio session so the game music can play alongside or
        // respect the system silent switch.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
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

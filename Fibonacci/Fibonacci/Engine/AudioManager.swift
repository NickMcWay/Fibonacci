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

    private var player: AVAudioPlayer?
    private var correctPlayer: AVAudioPlayer?
    private var wrongPlayer: AVAudioPlayer?
    private let muteKey = "SlideWords_IsMuted"

    init() {
        isMuted = UserDefaults.standard.bool(forKey: "SlideWords_IsMuted")
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
    }

    private func loadEffect(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3"),
              let effectPlayer = try? AVAudioPlayer(contentsOf: url) else {
            return nil
        }
        effectPlayer.numberOfLoops = 0
        effectPlayer.volume = 0.65
        effectPlayer.prepareToPlay()
        return effectPlayer
    }

    func play() {
        guard !isMuted else { return }
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
        guard !isMuted else { return }
        guard let effectPlayer else { return }
        effectPlayer.currentTime = 0
        effectPlayer.play()
    }

    private func playSubtleHaptic(intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    func toggleMute() {
        isMuted.toggle()
    }
}

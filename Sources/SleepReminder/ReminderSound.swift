//
//  ReminderSound.swift
//  SleepReminder
//
//  Plays the built-in macOS Purr sound through the current media output.
//

import AVFoundation
import Foundation

@MainActor
final class ReminderSound {
    private var player: AVAudioPlayer?

    func play(volume: Double, repeating: Bool = false) {
        // Volume changes during a reminder should not restart the sound.
        if repeating, let player, player.isPlaying, player.numberOfLoops == -1 {
            updateVolume(volume)
            return
        }
        stop()
        let volume = clampedVolume(volume)
        guard volume > 0 else { return }

        do {
            // Load the system-provided file using media playback so it follows
            // YouTube's output (e.g. AirPods), not the separate alert device.
            let url = URL(fileURLWithPath: "/System/Library/Sounds/Purr.aiff")
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.numberOfLoops = repeating ? -1 : 0
            self.player = player
            if !player.play() {
                print("Could not play reminder sound")
            }
        } catch {
            // Never fall back to a potentially loud system beep.
            print("Could not load reminder sound: \(error)")
        }
    }

    func updateVolume(_ volume: Double) {
        player?.volume = clampedVolume(volume)
    }

    func stop() {
        player?.stop()
        player = nil
    }

    private func clampedVolume(_ volume: Double) -> Float {
        guard volume.isFinite else { return 0 }
        return Float(min(max(volume, 0), ConfigDefaults.maximumReminderSoundVolume))
    }
}

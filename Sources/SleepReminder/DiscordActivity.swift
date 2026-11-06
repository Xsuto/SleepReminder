//
//  DiscordActivity.swift
//  SleepReminder
//
//  Reads microphone activity without recording audio.
//

import AppKit
import CoreAudio

@MainActor
enum DiscordActivity {
    private static let bundleIdentifier = "com.hnc.Discord"

    static var isUsingMicrophone: Bool {
        do {
            let processes = try AudioHardwareSystem.shared.processes
            for process in processes {
                // A process may exit while we inspect it. Discord may capture
                // audio in its main process or one of its Electron helpers.
                guard let bundleID = try? process.bundleID,
                      bundleID == bundleIdentifier || bundleID.hasPrefix(bundleIdentifier + ".") else {
                    continue
                }

                if try process.isRunningInput {
                    return true
                }
            }
            return false
        } catch {
            // Preserve the previous protection if audio activity is unavailable.
            print("Could not check Discord microphone activity: \(error)")
            return !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
        }
    }
}

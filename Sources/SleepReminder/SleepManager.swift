//
//  SleepManager.swift
//  SleepReminder
//
//  Core logic for sleep reminder functionality
//

import Foundation
import AppKit
import SwiftUI
import Observation

@Observable
@MainActor
final class SleepManager: NSObject, NSWindowDelegate {
    // MARK: - Dependencies
    
    private let config = ConfigManager.shared
    private let reminderSound = ReminderSound()
    
    // MARK: - State
    
    /// Whether the reminder popup is currently showing
    var isShowingReminder = false
    
    /// Countdown seconds remaining before forced sleep
    var countdownSeconds: Int = 60
    
    /// Time when snooze expires (nil if not snoozed)
    var snoozeUntil: Date?
    
    /// Current status message for the menu bar
    var statusMessage: String {
        if let snoozeUntil, Date() < snoozeUntil {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Snoozed until \(formatter.string(from: snoozeUntil))"
        } else if isInSleepWindow {
            if !isShowingReminder, let blocker = reminderBlocker {
                return "Blocked by \(blocker)"
            }
            return "Active (monitoring)"
        } else {
            return "Outside sleep window"
        }
    }
    
    /// Whether current time is within the sleep reminder window
    var isInSleepWindow: Bool {
        isTimeInSleepWindow(Date())
    }
    
    // MARK: - Private Properties
    
    private var checkTimer: Timer?
    private var countdownTimer: Timer?
    private var reminderPanel: NSPanel?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        startMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Start the periodic check timer
    func startMonitoring() {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: config.checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.performCheck()
            }
        }
        // Also perform an immediate check
        performCheck()
    }
    
    /// Restart monitoring with updated config (call after config changes)
    func restartMonitoring() {
        startMonitoring()
    }
    
    /// Stop all timers
    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
        stopCountdown()
        reminderSound.stop()
    }
    
    /// User pressed snooze button
    func snooze() {
        snoozeUntil = Date().addingTimeInterval(config.snoozeInterval)
        dismissReminder()
    }
    
    /// Dismiss the reminder popup
    func dismissReminder() {
        isShowingReminder = false
        reminderSound.stop()
        stopCountdown()
        countdownSeconds = Int(config.popupTimeout)
        closeReminderPanel()
    }
    
    /// Show the reminder (called from test button or timer)
    func triggerReminder() {
        showReminder()
    }
    
    /// Preview only the audio, without showing a popup or starting a countdown.
    func previewReminderSound() {
        guard config.reminderSoundEnabled, !isShowingReminder else { return }
        reminderSound.play(volume: config.reminderSoundVolume)
    }

    /// Apply mute and volume changes immediately, including during playback.
    func updateReminderSound() {
        guard config.reminderSoundEnabled else {
            reminderSound.stop()
            return
        }
        if isShowingReminder {
            reminderSound.play(volume: config.reminderSoundVolume, repeating: true)
        } else {
            reminderSound.updateVolume(config.reminderSoundVolume)
        }
    }

    // MARK: - Private Methods

    /// Add future blockers here so the status and popup use the same checks.
    private var reminderBlocker: String? {
        if DiscordActivity.isUsingMicrophone {
            return "Discord"
        }
        return nil
    }
    
    private func performCheck() {
        // Skip if already showing reminder
        guard !isShowingReminder else { return }
        
        // Check if we're in the sleep window
        guard isTimeInSleepWindow(Date()) else { return }
        
        // Check if we're currently snoozed
        if let snoozeUntil, Date() < snoozeUntil {
            return
        }
        
        // Clear expired snooze
        if snoozeUntil != nil && Date() >= snoozeUntil! {
            snoozeUntil = nil
        }
        
        // Show the reminder
        showReminder()
    }
    
    private func showReminder() {
        guard !isShowingReminder else { return }

        // Defer until the next monitoring check while any blocker is active.
        guard reminderBlocker == nil else { return }

        countdownSeconds = Int(config.popupTimeout)
        isShowingReminder = true
        openReminderPanel()
        updateReminderSound()
        startCountdown()
    }
    
    private func startCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickCountdown()
            }
        }
    }
    
    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func tickCountdown() {
        countdownSeconds -= 1
        
        if countdownSeconds <= 0 {
            forceSleep()
        }
    }
    
    private func forceSleep() {
        dismissReminder()
        
        // Use pmset to put the Mac to sleep
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["sleepnow"]
        
        do {
            try process.run()
        } catch {
            print("Failed to execute sleep command: \(error)")
        }
    }
    
    /// Check if the given time is within the sleep reminder window
    /// Handles the case where the window crosses midnight (e.g., 23:00 to 06:00)
    private func isTimeInSleepWindow(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        let currentMinutes = hour * 60 + minute
        let startMinutes = config.sleepWindowStart.hour * 60 + config.sleepWindowStart.minute
        let endMinutes = config.sleepWindowEnd.hour * 60 + config.sleepWindowEnd.minute
        
        if startMinutes <= endMinutes {
            // Window doesn't cross midnight (e.g., 09:00 to 17:00)
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        } else {
            // Window crosses midnight (e.g., 23:00 to 06:00)
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        }
    }
    
    // MARK: - Panel Management
    
    private func openReminderPanel() {
        // Close existing panel if any
        closeReminderPanel()
        
        // Create the SwiftUI content
        let contentView = ReminderWindow()
            .environment(self)
        
        // Create hosting view
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 400, height: 350)
        
        // Create panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.delegate = self
        panel.title = "Sleep Reminder"
        panel.contentView = hostingView
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = NSColor.windowBackgroundColor
        
        // Center on screen
        panel.center()
        
        // Show the panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        reminderPanel = panel
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let panel = notification.object as? NSPanel, panel === reminderPanel else { return }
        // Closing via the title bar must also stop looping audio and countdown.
        reminderPanel = nil
        dismissReminder()
    }

    private func closeReminderPanel() {
        reminderPanel?.delegate = nil
        reminderPanel?.close()
        reminderPanel = nil
    }
}

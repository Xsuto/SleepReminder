//
//  Config.swift
//  SleepReminder
//
//  Sleep Reminder Configuration with UserDefaults persistence
//

import Foundation
import SwiftUI
import Observation

// MARK: - UserDefaults Keys

private enum ConfigKey: String {
    case sleepWindowStartHour = "sleepWindowStartHour"
    case sleepWindowStartMinute = "sleepWindowStartMinute"
    case sleepWindowEndHour = "sleepWindowEndHour"
    case sleepWindowEndMinute = "sleepWindowEndMinute"
    case checkInterval = "checkInterval"
    case snoozeInterval = "snoozeInterval"
    case popupTimeout = "popupTimeout"
    case reminderSoundEnabled = "reminderSoundEnabled"
    case reminderSoundVolume = "reminderSoundVolume"
}

// MARK: - Default Values

enum ConfigDefaults {
    static let sleepWindowStartHour = 23
    static let sleepWindowStartMinute = 0
    static let sleepWindowEndHour = 6
    static let sleepWindowEndMinute = 0
    static let checkInterval: TimeInterval = 15 * 60  // 15 minutes
    static let snoozeInterval: TimeInterval = 60 * 60  // 1 hour
    static let popupTimeout: TimeInterval = 60  // 1 minute
    static let reminderSoundEnabled = true
    static let reminderSoundVolume = 0.06
    static let maximumReminderSoundVolume = 0.20
}

// MARK: - Observable Config Manager

@Observable
@MainActor
final class ConfigManager {
    static let shared = ConfigManager()
    
    // MARK: - Sleep Window Start
    
    var sleepWindowStartHour: Int {
        didSet { UserDefaults.standard.set(sleepWindowStartHour, forKey: ConfigKey.sleepWindowStartHour.rawValue) }
    }
    
    var sleepWindowStartMinute: Int {
        didSet { UserDefaults.standard.set(sleepWindowStartMinute, forKey: ConfigKey.sleepWindowStartMinute.rawValue) }
    }
    
    var sleepWindowStart: (hour: Int, minute: Int) {
        (sleepWindowStartHour, sleepWindowStartMinute)
    }
    
    // MARK: - Sleep Window End
    
    var sleepWindowEndHour: Int {
        didSet { UserDefaults.standard.set(sleepWindowEndHour, forKey: ConfigKey.sleepWindowEndHour.rawValue) }
    }
    
    var sleepWindowEndMinute: Int {
        didSet { UserDefaults.standard.set(sleepWindowEndMinute, forKey: ConfigKey.sleepWindowEndMinute.rawValue) }
    }
    
    var sleepWindowEnd: (hour: Int, minute: Int) {
        (sleepWindowEndHour, sleepWindowEndMinute)
    }
    
    // MARK: - Timer Intervals
    
    /// How often to check if we should show the reminder (in minutes)
    var checkIntervalMinutes: Int {
        didSet {
            let seconds = TimeInterval(checkIntervalMinutes * 60)
            UserDefaults.standard.set(seconds, forKey: ConfigKey.checkInterval.rawValue)
        }
    }
    
    /// Check interval in seconds (for timer use)
    var checkInterval: TimeInterval {
        TimeInterval(checkIntervalMinutes * 60)
    }
    
    /// How long the snooze lasts (in minutes)
    var snoozeIntervalMinutes: Int {
        didSet {
            let seconds = TimeInterval(snoozeIntervalMinutes * 60)
            UserDefaults.standard.set(seconds, forKey: ConfigKey.snoozeInterval.rawValue)
        }
    }
    
    /// Snooze interval in seconds (for timer use)
    var snoozeInterval: TimeInterval {
        TimeInterval(snoozeIntervalMinutes * 60)
    }
    
    /// How long to wait before forcing sleep if user doesn't respond (in seconds)
    var popupTimeoutSeconds: Int {
        didSet {
            UserDefaults.standard.set(TimeInterval(popupTimeoutSeconds), forKey: ConfigKey.popupTimeout.rawValue)
        }
    }
    
    /// Popup timeout in seconds (for timer use)
    var popupTimeout: TimeInterval {
        TimeInterval(popupTimeoutSeconds)
    }
    
    // MARK: - Reminder Sound

    var reminderSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(reminderSoundEnabled, forKey: ConfigKey.reminderSoundEnabled.rawValue) }
    }

    /// Playback gain, independent of system volume. Capped again during playback.
    var reminderSoundVolume: Double {
        didSet { UserDefaults.standard.set(reminderSoundVolume, forKey: ConfigKey.reminderSoundVolume.rawValue) }
    }

    // MARK: - Initialization
    
    private init() {
        let defaults = UserDefaults.standard
        
        // Register defaults
        defaults.register(defaults: [
            ConfigKey.sleepWindowStartHour.rawValue: ConfigDefaults.sleepWindowStartHour,
            ConfigKey.sleepWindowStartMinute.rawValue: ConfigDefaults.sleepWindowStartMinute,
            ConfigKey.sleepWindowEndHour.rawValue: ConfigDefaults.sleepWindowEndHour,
            ConfigKey.sleepWindowEndMinute.rawValue: ConfigDefaults.sleepWindowEndMinute,
            ConfigKey.checkInterval.rawValue: ConfigDefaults.checkInterval,
            ConfigKey.snoozeInterval.rawValue: ConfigDefaults.snoozeInterval,
            ConfigKey.popupTimeout.rawValue: ConfigDefaults.popupTimeout,
            ConfigKey.reminderSoundEnabled.rawValue: ConfigDefaults.reminderSoundEnabled,
            ConfigKey.reminderSoundVolume.rawValue: ConfigDefaults.reminderSoundVolume
        ])
        
        // Load values
        sleepWindowStartHour = defaults.integer(forKey: ConfigKey.sleepWindowStartHour.rawValue)
        sleepWindowStartMinute = defaults.integer(forKey: ConfigKey.sleepWindowStartMinute.rawValue)
        sleepWindowEndHour = defaults.integer(forKey: ConfigKey.sleepWindowEndHour.rawValue)
        sleepWindowEndMinute = defaults.integer(forKey: ConfigKey.sleepWindowEndMinute.rawValue)
        
        let checkSeconds = defaults.double(forKey: ConfigKey.checkInterval.rawValue)
        checkIntervalMinutes = Int(checkSeconds / 60)
        
        let snoozeSeconds = defaults.double(forKey: ConfigKey.snoozeInterval.rawValue)
        snoozeIntervalMinutes = Int(snoozeSeconds / 60)
        
        popupTimeoutSeconds = Int(defaults.double(forKey: ConfigKey.popupTimeout.rawValue))
        reminderSoundEnabled = defaults.bool(forKey: ConfigKey.reminderSoundEnabled.rawValue)
        let savedVolume = defaults.double(forKey: ConfigKey.reminderSoundVolume.rawValue)
        reminderSoundVolume = savedVolume.isFinite
            ? min(max(savedVolume, 0), ConfigDefaults.maximumReminderSoundVolume)
            : ConfigDefaults.reminderSoundVolume
    }
    
    // MARK: - Reset to Defaults
    
    func resetToDefaults() {
        sleepWindowStartHour = ConfigDefaults.sleepWindowStartHour
        sleepWindowStartMinute = ConfigDefaults.sleepWindowStartMinute
        sleepWindowEndHour = ConfigDefaults.sleepWindowEndHour
        sleepWindowEndMinute = ConfigDefaults.sleepWindowEndMinute
        checkIntervalMinutes = Int(ConfigDefaults.checkInterval / 60)
        snoozeIntervalMinutes = Int(ConfigDefaults.snoozeInterval / 60)
        popupTimeoutSeconds = Int(ConfigDefaults.popupTimeout)
        reminderSoundEnabled = ConfigDefaults.reminderSoundEnabled
        reminderSoundVolume = ConfigDefaults.reminderSoundVolume
    }
}

// MARK: - Legacy Config (for backward compatibility)

@MainActor
enum Config {
    static var sleepWindowStart: (hour: Int, minute: Int) {
        ConfigManager.shared.sleepWindowStart
    }
    
    static var sleepWindowEnd: (hour: Int, minute: Int) {
        ConfigManager.shared.sleepWindowEnd
    }
    
    static var checkInterval: TimeInterval {
        ConfigManager.shared.checkInterval
    }
    
    static var snoozeInterval: TimeInterval {
        ConfigManager.shared.snoozeInterval
    }
    
    static var popupTimeout: TimeInterval {
        ConfigManager.shared.popupTimeout
    }
}

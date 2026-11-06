//
//  SettingsWindow.swift
//  SleepReminder
//
//  Settings window for configuring the app
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @Environment(ConfigManager.self) private var config
    @Environment(SleepManager.self) private var sleepManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        @Bindable var configBinding = config
        
        Form {
            Section("Sleep Window") {
                HStack {
                    Text("Start time")
                    Spacer()
                    Picker("", selection: $configBinding.sleepWindowStartHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(String(format: "%02d", hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 70)
                    
                    Text(":")
                    
                    Picker("", selection: $configBinding.sleepWindowStartMinute) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 70)
                }
                
                HStack {
                    Text("End time")
                    Spacer()
                    Picker("", selection: $configBinding.sleepWindowEndHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(String(format: "%02d", hour)).tag(hour)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 70)
                    
                    Text(":")
                    
                    Picker("", selection: $configBinding.sleepWindowEndMinute) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text(String(format: "%02d", minute)).tag(minute)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 70)
                }
            }
            
            Section("Timing") {
                Picker("Check interval", selection: $configBinding.checkIntervalMinutes) {
                    Text("1 minute").tag(1)
                    Text("5 minutes").tag(5)
                    Text("10 minutes").tag(10)
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                }
                .onChange(of: config.checkIntervalMinutes) {
                    sleepManager.restartMonitoring()
                }
                
                Picker("Snooze duration", selection: $configBinding.snoozeIntervalMinutes) {
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("2 hours").tag(120)
                }
                
                Picker("Force sleep after", selection: $configBinding.popupTimeoutSeconds) {
                    Text("30 seconds").tag(30)
                    Text("1 minute").tag(60)
                    Text("2 minutes").tag(120)
                    Text("5 minutes").tag(300)
                }
            }
            
            Section("Reminder Sound") {
                Toggle("Repeat macOS Purr sound", isOn: $configBinding.reminderSoundEnabled)
                    .onChange(of: config.reminderSoundEnabled) {
                        sleepManager.updateReminderSound()
                    }

                HStack {
                    Slider(value: $configBinding.reminderSoundVolume,
                           in: 0...ConfigDefaults.maximumReminderSoundVolume, step: 0.01) {
                        Text("Volume")
                    }
                    Text("\(Int((config.reminderSoundVolume * 100).rounded()))%")
                        .monospacedDigit()
                        .frame(width: 40, alignment: .trailing)
                }
                .disabled(!config.reminderSoundEnabled)
                .onChange(of: config.reminderSoundVolume) {
                    sleepManager.updateReminderSound()
                }

                Button("Preview Sound") {
                    sleepManager.previewReminderSound()
                }
                .disabled(!config.reminderSoundEnabled || config.reminderSoundVolume == 0 || sleepManager.isShowingReminder)

                Text("The built-in macOS Purr sound loops while the popup is open, through your current audio output. Playback volume is capped at \(Int((ConfigDefaults.maximumReminderSoundVolume * 100).rounded()))%; headphone and Mac volume still affect loudness. Preview plays once without starting the sleep countdown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Button("Reset to Defaults") {
                        config.resetToDefaults()
                        sleepManager.restartMonitoring()
                    }
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 570)
        .fixedSize()
    }
}

// MARK: - Settings Window Controller

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    
    private init() {}
    
    func open(config: ConfigManager, sleepManager: SleepManager) {
        // If window already exists, bring it to front
        if let window = window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create the SwiftUI view
        let settingsView = SettingsView()
            .environment(config)
            .environment(sleepManager)
        
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 570),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Sleep Reminder Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.window = window
    }
}

#Preview {
    SettingsView()
        .environment(ConfigManager.shared)
        .environment(SleepManager())
}

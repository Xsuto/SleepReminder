//
//  SleepReminderApp.swift
//  SleepReminder
//
//  Created by Michał Sutowicz on 25/01/2026.
//

import SwiftUI

@main
struct SleepReminderApp: App {
    @State private var sleepManager = SleepManager()
    @State private var loginItemManager = LoginItemManager()
    private var configManager = ConfigManager.shared
    
    var body: some Scene {
        // Menu bar item only - no dock icon, no main window
        MenuBarExtra("Sleep Reminder", systemImage: "moon.zzz.fill") {
            MenuBarView(
                onOpenSettings: {
                    SettingsWindowController.shared.open(
                        config: configManager,
                        sleepManager: sleepManager
                    )
                },
                onTestReminder: { sleepManager.triggerReminder() }
            )
            .environment(sleepManager)
            .environment(loginItemManager)
            .environment(configManager)
        }
    }
}

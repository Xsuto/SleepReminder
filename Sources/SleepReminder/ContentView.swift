//
//  ContentView.swift
//  SleepReminder
//
//  Menu bar dropdown view
//

import SwiftUI

struct MenuBarView: View {
    @Environment(SleepManager.self) private var sleepManager
    @Environment(LoginItemManager.self) private var loginItemManager
    @Environment(ConfigManager.self) private var config
    var onOpenSettings: () -> Void
    var onTestReminder: () -> Void
    
    var body: some View {
        @Bindable var loginItem = loginItemManager
        
        VStack(alignment: .leading, spacing: 4) {
            // Status section
            Text("Status")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TimelineView(.periodic(from: .now, by: 5)) { _ in
                Text(sleepManager.statusMessage)
                    .font(.headline)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Time window info
            Text("Active hours: \(formatTime(config.sleepWindowStart)) – \(formatTime(config.sleepWindowEnd))")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Divider()
                .padding(.vertical, 4)
            
            // Launch at login toggle
            Toggle("Launch at Login", isOn: $loginItem.isEnabled)
            
            Divider()
                .padding(.vertical, 4)
            
            // Settings button
            Button("Settings...") {
                onOpenSettings()
            }
            
            // Test button (useful for debugging)
            Button("Test Reminder") {
                onTestReminder()
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Quit button
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(8)
        .frame(width: 220)
    }
    
    private func formatTime(_ time: (hour: Int, minute: Int)) -> String {
        String(format: "%02d:%02d", time.hour, time.minute)
    }
}

#Preview {
    MenuBarView(onOpenSettings: {}, onTestReminder: {})
        .environment(SleepManager())
        .environment(LoginItemManager())
        .environment(ConfigManager.shared)
}

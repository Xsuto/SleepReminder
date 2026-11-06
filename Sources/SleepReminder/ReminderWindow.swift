//
//  ReminderWindow.swift
//  SleepReminder
//
//  Popup window asking user if they're still awake
//

import SwiftUI

struct ReminderWindow: View {
    @Environment(SleepManager.self) private var sleepManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Moon icon
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            // Title
            Text("Are you still awake?")
                .font(.title)
                .fontWeight(.semibold)
            
            // Subtitle with countdown
            Text("Your Mac will sleep in \(sleepManager.countdownSeconds) seconds")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            // Progress indicator
            ProgressView(value: Double(sleepManager.countdownSeconds), total: Config.popupTimeout)
                .progressViewStyle(.linear)
                .frame(width: 250)
            
            // Snooze button
            Button(action: {
                sleepManager.snooze()
            }) {
                Text("Stay awake for 1 hour")
                    .font(.headline)
                    .frame(width: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // Time info
            Text("Sleep reminder active: \(formatTime(Config.sleepWindowStart)) – \(formatTime(Config.sleepWindowEnd))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(width: 400, height: 350)
    }
    
    private func formatTime(_ time: (hour: Int, minute: Int)) -> String {
        String(format: "%02d:%02d", time.hour, time.minute)
    }
}

#Preview {
    ReminderWindow()
        .environment(SleepManager())
}

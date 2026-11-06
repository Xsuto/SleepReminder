//
//  LoginItemManager.swift
//  SleepReminder
//
//  Manages launch at login functionality using SMAppService
//

import Foundation
import ServiceManagement
import Observation

@Observable
@MainActor
final class LoginItemManager {
    /// Whether the app is set to launch at login
    var isEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            setLoginItem(enabled: newValue)
        }
    }
    
    /// Current status description
    var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled:
            return "Enabled"
        case .notRegistered:
            return "Disabled"
        case .notFound:
            return "Not found"
        case .requiresApproval:
            return "Requires approval in System Settings"
        @unknown default:
            return "Unknown"
        }
    }
    
    /// Toggle the login item setting
    private func setLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") login item: \(error)")
        }
    }
}

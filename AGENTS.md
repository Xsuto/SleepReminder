# AGENTS.md - SleepReminder

Guidelines for AI agents working on this macOS menu bar application.

## Project Overview

SleepReminder is a macOS menu bar app that reminds users to sleep during configured hours.
- **Platform**: macOS 26 (Tahoe) only
- **Framework**: SwiftUI with AppKit integration
- **Architecture**: Menu bar app (no dock icon, `LSUIElement = YES`)
- **Sandbox**: Disabled (required for `pmset sleepnow` command)

## Build Commands

```bash
# Build dist/SleepReminder.app
./build.sh

# Run
open dist/SleepReminder.app

# Compile only (Debug)
swift build

# Clean build
swift package clean && ./build.sh

# Build and show only errors/warnings
swift build 2>&1 | grep -E "(error:|warning:)"
```

Run the app from `dist/`, not with `swift run` or from Xcode: those start a bare executable with no app bundle, so `LSUIElement` and `SMAppService` don't work.

## Testing

This project is not tested. We don't want tests

## Project Structure

```
Package.swift                # Swift package, compiler settings
build.sh                     # Builds and ad-hoc signs dist/SleepReminder.app
Resources/Info.plist         # App bundle metadata
Sources/SleepReminder/
├── SleepReminderApp.swift   # @main entry point, MenuBarExtra setup
├── Config.swift             # All configuration constants
├── SleepManager.swift       # Core logic: timers, sleep window, countdown
├── LoginItemManager.swift   # Launch at login via SMAppService
├── ContentView.swift        # MenuBarView (menu bar dropdown)
├── ReminderWindow.swift     # Popup window UI
├── SettingsWindow.swift     # Settings window UI
├── ReminderSound.swift      # Looping reminder sound
└── DiscordActivity.swift    # Discord microphone activity check
```

# AGENTS.md — SayToIt

## Project Overview
SayToIt is a native macOS menu-bar app that captures microphone audio, streams it to Deepgram for real-time transcription, and copies the result to the clipboard.

## Architecture
- **SayToItCore**: Shared library — audio capture, Deepgram WebSocket client, Keychain storage, hotkey manager, clipboard service
- **SayToIt**: macOS app target — SwiftUI MenuBarExtra, views, app state

## Key Conventions
- Swift 5.9+, SwiftPM (no Xcode project files)
- macOS 14+ (Sonoma) minimum deployment target
- All async work uses Swift Concurrency (async/await, actors)
- Protocols for all services (testability via dependency injection)
- Keychain for secrets — never store API keys in plaintext or UserDefaults
- CGEvent tap for global hotkeys (requires Accessibility permission)

## Testing
- `swift test` runs all unit tests
- Core services have protocol-based mocks
- Tests must pass before any commit

## Build & Run
```bash
make build   # swift build
make test    # swift test
make run     # swift run SayToIt
make clean   # swift package clean
```

## File Layout
```
Sources/SayToItCore/
  Audio/AudioCaptureService.swift       — AVAudioEngine mic capture
  Transcription/DeepgramClient.swift    — WebSocket streaming
  Transcription/TranscriptionService.swift — Protocol
  Transcription/TranscriptionResult.swift  — Result types
  Storage/SecureStorage.swift           — Keychain wrapper
  Hotkey/HotkeyManager.swift           — Global shortcut
  Clipboard/ClipboardService.swift      — Clipboard operations

Sources/SayToIt/
  SayToItApp.swift                     — @main entry
  Views/MenuBarView.swift              — Menu bar popover
  Views/TranscriptionView.swift        — Live transcript
  Views/SettingsView.swift             — Settings
  ViewModels/AppState.swift            — Central state
```

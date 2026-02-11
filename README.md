# SayToIt

**Say it. See it. Ship it.**

A voice-first transcription app for macOS. Speak naturally, get instant text — powered by [Deepgram](https://deepgram.com).

> 🚧 **Under active development** — Star the repo to follow along!

## What is SayToIt?

SayToIt lives in your menu bar. Press a hotkey, speak, and your words appear as text — copied to your clipboard, ready to paste anywhere. Write emails, commit messages, Slack replies, and documentation without touching the keyboard.

### Features

- 🎙️ **Real-time transcription** — streaming via Deepgram WebSocket API
- ⌨️ **Global hotkey** — `⌘⇧S` to start/stop (customisable)
- 📋 **Auto-clipboard** — transcript copied automatically
- 🔐 **Secure** — API keys stored in macOS Keychain
- 🪶 **Lightweight** — native SwiftUI menu bar app, minimal footprint
- 🆓 **BYOK** — Bring Your Own Key. No subscriptions, no middlemen.

## Quick Start

### Prerequisites

- macOS 14 (Sonoma) or later
- A [Deepgram](https://console.deepgram.com/signup) API key (free $200 credit on signup)

### Install

```bash
# Homebrew (coming soon)
brew install --cask saytoit

# Or build from source
git clone https://github.com/rameshreddy-adutla/saytoit.git
cd saytoit
make build
make run
```

### Setup

1. Launch SayToIt — it appears in your menu bar
2. Click the icon → Settings
3. Paste your Deepgram API key
4. Press `⌘⇧S` and start talking!

## Development

```bash
make build   # Build the app
make test    # Run tests
make run     # Build and run
make clean   # Clean build artifacts
```

### Architecture

- **SayToItCore** — shared library: audio capture, Deepgram client, Keychain, hotkey
- **SayToIt** — macOS app: SwiftUI MenuBarExtra, views, app state

Built with Swift 5.9+, SwiftPM, SwiftUI, and AVAudioEngine.

## Contributing

Contributions welcome! See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE) © 2025 Ramesh Reddy Adutla

---

🌐 [saytoit.com](https://saytoit.com)

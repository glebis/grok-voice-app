# GrokVoice

A macOS notch-native voice assistant powered by xAI's Grok Voice Agent API with Obsidian vault integration.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Notch-native UI**: Expands from the MacBook notch for seamless interaction
- **Real-time voice**: Speech-to-speech via xAI Grok Voice Agent API
- **7 voice options**: Sal, Rex, Eve, Leo, Ara, Mika, Valentin
- **Wake word activation**: Say "Computer" to activate (Picovoice Porcupine)
- **Obsidian integration**: Search, read, and write notes via Claude Agent SDK
- **Tool visualization**: Animated feedback during AI tool execution

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GrokVoice macOS App                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ NotchWindow │  │ VoiceViewModel│ │  LiveKitService    │  │
│  │   (UI)      │──│   (State)    │──│  (WebRTC Audio)    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└────────────────────────────┬────────────────────────────────┘
                             │ WebRTC
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      LiveKit Server                          │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                  Python Voice Agent                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ xAI Grok    │  │ VaultAgent  │  │ Claude Agent SDK    │  │
│  │ Voice API   │  │  (Tools)    │──│ (Obsidian Access)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Requirements

### macOS App
- macOS 14.0+
- MacBook with notch (M1 Pro/Max/Ultra or later)
- Microphone access

### Backend
- Python 3.11+
- LiveKit Server (local or cloud)
- xAI API key
- Picovoice access key (for wake word)
- Claude API key (for Obsidian tools)

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/glebis/grok-voice-app.git
cd grok-voice-app
```

### 2. Configure the Python agent

```bash
cd ../livekit-grok-voice-agent
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Create `.env`:
```
XAI_API_KEY=your_xai_api_key
LIVEKIT_URL=ws://localhost:7880
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
ANTHROPIC_API_KEY=your_claude_api_key
PICOVOICE_ACCESS_KEY=your_picovoice_key
OBSIDIAN_VAULT_PATH=/path/to/your/vault
```

### 3. Start LiveKit Server

```bash
# Development mode
livekit-server --dev
```

### 4. Start the Python agent

```bash
python agent.py dev
```

### 5. Configure the macOS app

Open in Xcode, build and run. In settings:
- LiveKit URL: `ws://localhost:7880`
- Token: Generate with `lk token create --api-key devkey --api-secret secret --room voice-agent-room --identity macos-user --valid-for 24h --join --grant '{"canPublish":true,"canSubscribe":true,"canPublishData":true}'`
- Select voice preference

## Usage

1. Click the blob in the notch to expand
2. Speak your query
3. Wait for Grok's response
4. Click again or use wake word to continue

### Voice Commands (Obsidian)
- "Search for notes about [topic]"
- "Read my daily note"
- "Add [content] to today's note"

## Development

### Project Structure

```
GrokVoice/
├── App/           # App lifecycle, window management
├── Core/          # ViewModels, settings, geometry
├── Models/        # Data types (VoicePhase, GrokVoice)
├── Services/      # LiveKit, Keychain, Audio devices
├── UI/
│   ├── Views/     # SwiftUI views
│   ├── Components/# Reusable UI components
│   └── Window/    # Custom NSWindow/NSPanel
└── Resources/     # Entitlements, Info.plist
```

### Building

```bash
xcodebuild -scheme GrokVoice -configuration Debug build
```

## API Pricing

- xAI Grok Voice Agent API: $0.05/minute connection time
- Supports 100+ languages with native accents

## License

MIT

## Credits

- [xAI](https://x.ai) - Grok Voice Agent API
- [LiveKit](https://livekit.io) - WebRTC infrastructure
- [Anthropic](https://anthropic.com) - Claude Agent SDK
- [Picovoice](https://picovoice.ai) - Wake word detection

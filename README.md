# TimeTagger macOS Client

A native macOS menu-bar app for [TimeTagger](https://timetagger.io) time tracking. One click to start, stop, or switch between your most-used time entries.

> **Status:** Under active development — see [DEVELOPMENT.md](DEVELOPMENT.md) for the roadmap.

## Features

- Lives in your menu bar — always one click away, no Dock clutter
- Quick-action button matrix for your most-used tag combinations
- Configurable buttons — add, remove, reorder, and color-code
- Smart suggestions based on your TimeTagger history
- Secure — API token stored in macOS Keychain, never on disk
- Works with [timetagger.io](https://timetagger.io) and self-hosted instances
- Universal binary — runs natively on Apple Silicon and Intel Macs

## Requirements

- macOS 13.0 (Ventura) or later
- A [TimeTagger](https://timetagger.io) account (free or paid)

## Installation

1. Download the latest `TimeTaggerMac-vX.X.X.dmg` from [Releases](../../releases)
2. Open the DMG and drag `TimeTaggerMac.app` to your Applications folder
3. On first launch, macOS may show a security warning because the app is not notarized

   **Bypass Gatekeeper (one-time):** Right-click the app icon → **Open** → click **Open** in the dialog

4. Enter your TimeTagger API token (found in TimeTagger → Settings → API tokens)

## Building from Source

```bash
git clone https://github.com/<your-username>/timetagger_macclient.git
cd timetagger_macclient/TimeTaggerMac
xcodebuild -project TimeTaggerMac.xcodeproj -scheme TimeTaggerMac build
```

Requires Xcode 16 or later.

## Running Tests

```bash
xcodebuild test \
  -project TimeTaggerMac/TimeTaggerMac.xcodeproj \
  -scheme TimeTaggerMac \
  -destination 'platform=macOS'
```

## Contributing

Contributions welcome. Please read [DEVELOPMENT.md](DEVELOPMENT.md) before opening a PR.

## License

[CC BY-SA 4.0](LICENSE) — Attribution + ShareAlike. Commercial use permitted.

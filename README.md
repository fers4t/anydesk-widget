<div align="center">

# AnyDesk Widget

**A focused macOS menu bar utility for starting AnyDesk sessions with minimal friction.**

[![Latest release](https://img.shields.io/github/v/release/fers4t/anydesk-widget?display_name=tag&sort=semver)](https://github.com/fers4t/anydesk-widget/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-000000?logo=apple)](https://support.apple.com/macos)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://www.swift.org/)
[![No dependencies](https://img.shields.io/badge/dependencies-none-2ea44f)](Package.swift)

[Download the latest release](https://github.com/fers4t/anydesk-widget/releases/latest) · [Report an issue](https://github.com/fers4t/anydesk-widget/issues/new)

</div>

## Overview

AnyDesk Widget keeps remote-session initiation in the macOS menu bar. Open the widget, enter an AnyDesk ID or alias, and press Return. If AnyDesk is not running, macOS launches it before forwarding the connection request.

The application is intentionally narrow in scope: it does not replace AnyDesk, manage credentials, or implement a remote desktop protocol. It provides a faster native entry point to AnyDesk's supported URL handler.

## Capabilities

- Start a session with an AnyDesk ID or alias
- Detect copied 9–10 digit AnyDesk IDs, open the widget, and prefill the connection field
- Open or dismiss the widget with a configurable global keyboard shortcut
- Normalize spaces in numeric AnyDesk IDs before connecting
- Launch AnyDesk automatically through its registered URL handler
- Follow the preferred macOS language: English, Turkish, French, or Italian
- Check GitHub Releases automatically, verify and download updates in the background, then install them on demand
- Start automatically when the user logs in, with an opt-out in Settings
- Check for updates manually from Settings
- Persist shortcut preferences locally between launches
- Detect unavailable shortcut combinations without discarding the active shortcut
- Run as a menu bar utility without a Dock presence

AnyDesk Widget is implemented with SwiftUI, AppKit, and Carbon. It has no third-party runtime or package dependencies.

## Requirements

| Component | Requirement |
| --- | --- |
| Operating system | macOS 13 Ventura or later |
| Architecture | Apple silicon |
| AnyDesk | Standard macOS client with URL-handler support |
| Source builds | Xcode Command Line Tools |

## Installation

1. Download the current ZIP archive from [GitHub Releases](https://github.com/fers4t/anydesk-widget/releases/latest).
2. Extract `AnyDesk Bağlan.app`.
3. Move the application to `/Applications`.
4. Launch it once from Finder.

Release artifacts are ad-hoc signed but not notarized with an Apple Developer certificate. Depending on your Gatekeeper settings, macOS may require explicit approval under **System Settings → Privacy & Security** before the first launch.

Starting with version 1.3.0, updates are delivered from this repository's GitHub Releases. The widget checks periodically without interrupting your work. When a newer build is ready, the menu bar icon changes and the popover presents an **Update and Restart** action.

Before installation, the updater verifies the downloaded archive against the SHA-256 digest published by GitHub, confirms the application bundle identifier and version, and validates the bundle's code signature. If any check fails, the installed application is left untouched.

## Usage

1. Select the display icon in the menu bar, or press `⌥⌘A`.
2. Enter a numeric AnyDesk ID or alias.
3. Press Return or select **Connect**.

Use the gear button to record a different system-wide shortcut. The shortcut must include at least one modifier key—Command, Option, Control, or Shift—and is saved immediately.

Clipboard detection is enabled by default and can be disabled from the same settings screen. Detection is intentionally strict: only clipboard text consisting entirely of a supported 9–10 digit AnyDesk ID format triggers the widget.

The widget registers itself as a macOS Login Item on first launch. You can disable automatic startup or check for updates manually from the Settings screen.

## Build from source

```sh
git clone https://github.com/fers4t/anydesk-widget.git
cd anydesk-widget
./build-app.sh
open "dist/AnyDesk Bağlan.app"
```

The build script compiles an optimized Swift executable, assembles the `.app` bundle, and applies an ad-hoc code signature. The resulting application is written to `dist/`.

## Architecture

| Component | Responsibility |
| --- | --- |
| `AppDelegate` | Status item lifecycle, popover presentation, and application activation |
| `ContentView` | Connection and settings interfaces |
| `ShortcutSettingsModel` | Shortcut persistence, validation, and registration state |
| `GlobalHotKeyManager` | System-wide shortcut registration through Carbon |
| `Localization` | Runtime language selection and interface copy |
| `UpdateModel` | GitHub release discovery, background download, verification, installation, and relaunch |

Connections are initiated with AnyDesk's official `anydesk:<id-or-alias>` URL format. macOS resolves the scheme to the installed AnyDesk client; authentication, session approval, and remote-access permissions remain entirely under AnyDesk's control. See the [AnyDesk URL handler documentation](https://support.anydesk.com/url-handler) for protocol details.

## Privacy and permissions

AnyDesk Widget:

- does not collect analytics or telemetry;
- does not store submitted AnyDesk IDs or aliases;
- does not handle unattended-access passwords;
- does not require Accessibility or Input Monitoring permission for its global shortcut;
- inspects changed plain-text clipboard values only while clipboard detection is enabled, without retaining their contents;
- stores only the selected shortcut and clipboard-detection preference in the application's local `UserDefaults` domain.
- contacts GitHub's public Releases API periodically to check for application updates; no account token or personal identifier is sent.

AnyDesk may require separate macOS permissions for remote-control functionality. Those permissions are managed by the AnyDesk client, not by this utility.

## Contributing

Issues and focused pull requests are welcome. Before submitting a change, verify that the release build succeeds:

```sh
./build-app.sh
codesign --verify --deep --strict "dist/AnyDesk Bağlan.app"
```

Please keep proposed changes aligned with the project's scope: a small, dependable launcher rather than an alternative AnyDesk client.

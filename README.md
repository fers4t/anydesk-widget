# AnyDesk Widget for macOS

A tiny, native macOS menu bar utility for starting AnyDesk sessions without opening the full AnyDesk window first.

Click the menu bar icon, enter an AnyDesk ID or alias, and press Return. The widget launches AnyDesk when needed and immediately starts the connection.

## Features

- Lives entirely in the macOS menu bar
- Connects using an AnyDesk ID or alias
- Automatically removes spaces from numeric IDs
- Launches AnyDesk when it is not already running
- Shows a clear message when AnyDesk is not installed
- Automatically follows the system language (English, Turkish, French, or Italian)
- Configurable system-wide keyboard shortcut to show or hide the widget
- Native SwiftUI interface with no third-party dependencies

## Requirements

- macOS 13 or later
- AnyDesk for macOS
- Xcode Command Line Tools for building from source

## Build

```sh
chmod +x build-app.sh
./build-app.sh
open "dist/AnyDesk Bağlan.app"
```

The generated application is ad-hoc signed and placed in `dist/`. Move it to `/Applications` for everyday use.

To launch the widget automatically, add it under **System Settings → General → Login Items**.

The default global shortcut is `⌥⌘A`. Open the gear menu to record your own shortcut; the selection is saved automatically.

## How it works

The app uses AnyDesk's official `anydesk:<id-or-alias>` URL handler. macOS routes the URL to AnyDesk, launching it automatically if necessary.

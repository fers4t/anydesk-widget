#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
APP_NAME="AnyDesk Bağlan"
BUILD_DIR="$SCRIPT_DIR/dist"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

cd "$SCRIPT_DIR"
export CLANG_MODULE_CACHE_PATH="$SCRIPT_DIR/.build/ModuleCache"
export SWIFTPM_MODULECACHE_OVERRIDE="$SCRIPT_DIR/.build/ModuleCache"
swift build -c release --disable-sandbox
BIN_DIR="$(swift build -c release --disable-sandbox --show-bin-path)"

mkdir -p "$APP_DIR/Contents/MacOS"
cp "$BIN_DIR/AnyDeskWidget" "$APP_DIR/Contents/MacOS/AnyDeskWidget"
cp "$SCRIPT_DIR/App/Info.plist" "$APP_DIR/Contents/Info.plist"

codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"

#!/usr/bin/env bash
# omacosy-bar, vendored from github.com/paulsp94/omacosy @ 59f6694 (MIT, see LICENSE)
# ponytail: must be an .app bundle, unbundled binaries can't read the wifi SSID
set -euo pipefail
cd "$(dirname "$0")"
APP=~/.local/share/omacosy/omacosy-bar.app
mkdir -p "$APP/Contents/MacOS"
swiftc -O -F /System/Library/PrivateFrameworks -framework SkyLight -framework DisplayServices \
  -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker bar-info.plist \
  -o "$APP/Contents/MacOS/omacosy-bar" bar.swift
cp bar-info.plist "$APP/Contents/Info.plist"

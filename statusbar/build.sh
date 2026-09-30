#!/usr/bin/env bash
# statusbar, vendored from github.com/paulsp94/omacosy @ 59f6694 (omacosy-bar, MIT, see LICENSE)
# ponytail: must be an .app bundle, unbundled binaries can't read the wifi SSID
set -euo pipefail
cd "$(dirname "$0")"
APP=~/.local/share/statusbar/statusbar.app
mkdir -p "$APP/Contents/MacOS"
swiftc -O -F /System/Library/PrivateFrameworks -framework SkyLight -framework DisplayServices \
  -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker statusbar-info.plist \
  -o "$APP/Contents/MacOS/statusbar" statusbar.swift
cp statusbar-info.plist "$APP/Contents/Info.plist"

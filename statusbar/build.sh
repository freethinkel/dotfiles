#!/usr/bin/env bash
# statusbar, vendored from github.com/paulsp94/omacosy @ 59f6694 (omacosy-bar, MIT, see LICENSE)
# an .app bundle: Info.plist carries the TCC usage strings, and a bundle id keeps
# UserDefaults and the launchd label in one place
set -euo pipefail
cd "$(dirname "$0")"
APP=~/.local/share/statusbar/statusbar.app
mkdir -p "$APP/Contents/MacOS"
swiftc -O -F /System/Library/PrivateFrameworks -framework SkyLight -framework DisplayServices \
  -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker statusbar-info.plist \
  -o "$APP/Contents/MacOS/statusbar" statusbar.swift
cp statusbar-info.plist "$APP/Contents/Info.plist"
# A real identity, not the linker's ad-hoc one: ad-hoc pins TCC grants to the
# binary's hash, so every rebuild re-asked for bluetooth, calendar, location.
# ponytail: first Apple Development cert; ad-hoc (and the prompts) without one
SIGN_ID=$(security find-identity -v -p codesigning | awk '/Apple Development/ {print $2; exit}')
codesign --force --sign "${SIGN_ID:--}" --identifier dev.freethinkel.statusbar "$APP" \
  || echo "statusbar: signing failed" >&2

# start at login, restart on crash; re-running build.sh reloads the new binary
AGENT=~/Library/LaunchAgents/dev.freethinkel.statusbar.plist
cat > "$AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>dev.freethinkel.statusbar</string>
  <key>ProgramArguments</key><array><string>$HOME/.local/share/statusbar/statusbar.app/Contents/MacOS/statusbar</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>ProcessType</key><string>Interactive</string>
  <!-- a crash (SIGABRT from a private framework, say) leaves its last words here -->
  <key>StandardErrorPath</key><string>/tmp/statusbar.err</string>
  <!-- lets the bar raise the location prompt; without it the weather falls back to the tz city -->
  <key>EnvironmentVariables</key><dict><key>STATUSBAR_MANAGED</key><string>1</string></dict>
</dict>
</plist>
PLIST
# already loaded: restart on the new binary (bootout+bootstrap races launchd)
# ponytail: a changed plist itself applies after make bar-off bar-on
launchctl bootstrap "gui/$UID" "$AGENT" 2>/dev/null || launchctl kickstart -k "gui/$UID/dev.freethinkel.statusbar"

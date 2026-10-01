#!/usr/bin/env bash
# Shares the Magic Trackpad pairing between macOS and Asahi, so it needs no re-pairing after a reboot.
# macOS:  make bt-trackpad       saves the link key, byte-reversed for bluez, to scripts/bt-trackpad.key
# Asahi:  sudo make bt-trackpad  writes that key for bluez and restarts bluetooth
# Re-pairing in either OS changes the key: run it on macOS again and commit.
set -euo pipefail
KEYFILE="$(dirname "$0")/bt-trackpad.key"

TRACKPAD=3C:A6:F6:BC:0F:CE

if [[ $(uname) == Darwin ]]; then
  # `security -w` exits 36 (errSecInteractionNotAllowed) on this item, so it's copied from the GUI
  open "/System/Library/CoreServices/Applications/Keychain Access.app" 2>/dev/null || open -a "Keychain Access"
  echo "Keychain Access: System -> search MobileBluetooth -> $TRACKPAD -> Show password, copy it all"
  read -rp "then press Enter "
  # the password is a plist: <key>LinkKey</key><string>10-76-...</string>
  key=$(pbpaste | plutil -extract LinkKey raw -o - -) || { echo "clipboard has no LinkKey plist" >&2; exit 1; }
  key=${key//-/}
  [[ $key =~ ^[0-9a-fA-F]{32}$ ]] || { echo "unexpected key format: $key" >&2; exit 1; }
  # macOS stores the key byte-reversed relative to bluez
  echo "$key" | fold -w2 | tail -r | tr -d '\n' | tr a-f A-F > "$KEYFILE"
  echo "saved to $KEYFILE"
  exit
fi

key=$(cat "$KEYFILE") || { echo "no $KEYFILE, run this on macOS first" >&2; exit 1; }
[[ $key =~ ^[0-9A-F]{32}$ ]] || { echo "$KEYFILE must hold 32 uppercase hex chars" >&2; exit 1; }
# ponytail: first adapter only, Macs have one
adapter=$(ls /var/lib/bluetooth | grep -m1 :) || { echo "no adapter in /var/lib/bluetooth, start bluetooth once" >&2; exit 1; }
dir=/var/lib/bluetooth/$adapter/$TRACKPAD
mkdir -p "$dir"
cat > "$dir/info" <<EOF
[General]
Name=Magic Trackpad
Trusted=true
Blocked=false
Services=00001124-0000-1000-8000-00805f9b34fb;00001200-0000-1000-8000-00805f9b34fb;

[LinkKey]
Key=$key
Type=5
PINLength=0
EOF
chmod 600 "$dir/info"
systemctl restart bluetooth
echo "written $dir/info; if the trackpad doesn't connect, try the key in the macOS byte order"

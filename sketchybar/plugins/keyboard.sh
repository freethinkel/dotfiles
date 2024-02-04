#!/usr/bin/env sh

mouse_clicked() {
  echo ""
}

update() {
  CURRENT_LAYOUT=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources | grep 'KeyboardLayout Name' | sed -E 's/^.+ = \"?([^\"]+)\"?;$/\1/');
  LABEL="A";
  case "$CURRENT_LAYOUT" in 
    "ABC") LABEL="􀂕" ;;
    "RussianWin") LABEL="􀂳" ;;
  esac

  sketchybar --set $NAME icon="$LABEL"
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked ;;
  *) update ;;
esac

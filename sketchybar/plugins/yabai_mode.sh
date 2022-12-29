#!/usr/bin/env sh

update() {
  sketchybar --set $NAME label="$(yabai -m query --spaces --space | jq -r '.type')"
}

mouse_clicked() {
  LAYOUT="$(yabai -m query --spaces --space | jq -r '.type')"

  echo "$LAYOUT"

  case $LAYOUT in
    "bsp") yabai -m space --layout stack
    ;; 
    "stack") yabai -m space --layout bsp
    ;;
  esac

  update
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  *) update
  ;;
esac

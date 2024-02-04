#!/usr/bin/env sh
source "$HOME/.config/sketchybar/vars.sh"

update() {
  if ( pgrep -x 'caffeinate' ); then
      sketchybar --set $NAME icon.color=$YELLOW_COLOR icon="􀸙"
  else
      sketchybar --set $NAME icon="􀸘"
  fi
}

mouse_clicked() {
  if ( pgrep -x 'caffeinate' ); then
      killall caffeinate
  else
      caffeinate -di & disown
  fi

  update
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  *) update
  ;;
esac

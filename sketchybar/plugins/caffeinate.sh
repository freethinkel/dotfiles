#!/usr/bin/env sh

update() {
  if ( pgrep -x 'caffeinate' ); then
      sketchybar --set $NAME icon="􀸙"
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

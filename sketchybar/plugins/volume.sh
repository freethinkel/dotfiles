#!/usr/bin/env sh

ICONS=("􀊣" "􀊡" "􀊥" "􀊧" "􀊩")
WIDTH=100
VALUE=100
ICON=${ICONS[2]}

volume_change() {
  INITIAL_WIDTH=$(sketchybar --query $NAME | jq ".icon.width")
  VALUE=$INFO

  case $VALUE in
     100) ICON=${ICONS[4]} ;;
     9[0-9]) ICON=${ICONS[4]} ;;
     8[0-9]) ICON=${ICONS[3]} ;;
     7[0-9]) ICON=${ICONS[3]} ;;
     6[0-9]) ICON=${ICONS[3]} ;;
     5[0-9]) ICON=${ICONS[3]} ;;
     4[0-9]) ICON=${ICONS[2]} ;;
     3[0-9]) ICON=${ICONS[2]} ;;
     2[0-9]) ICON=${ICONS[2]} ;;
     1[0-9]) ICON=${ICONS[1]} ;;
     *) ICON=${ICONS[0]} ;;
  esac

  update

  if [ "$INITIAL_WIDTH" -eq "0" ]; then
    sketchybar --animate tanh 30 --set $NAME width=$WIDTH icon.width=$INFO
  else
    sketchybar --set $NAME icon.width=$INFO width=$WIDTH
  fi

  sleep 2
  FINAL_WIDTH=$(sketchybar --query $NAME | jq ".icon.width")
  if [ "$FINAL_WIDTH" -eq "$INFO" ]; then
    sketchybar --animate tanh 30 --set $NAME width=0 icon.width=0
  fi
}

update() {
  sketchybar --set volume_icon icon="$ICON"
}

case "$SENDER" in
  "volume_change") volume_change
  ;;
  "update") update
  ;;
esac 

#!/usr/bin/env sh
source "$HOME/.config/sketchybar/vars.sh"

update() {
  PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
  CHARGING=$(pmset -g batt | grep 'AC Power')
  ICONS=("􀛪" "􀛩" "􀺶" "􀺸" "􀛨")
  ICON_CHARGING="􀢋"

  if [ $PERCENTAGE = "" ]; then
    exit 0
  fi

  COLOR=$GREEN_COLOR

  case ${PERCENTAGE} in
     100) COLOR=$GREEN_COLOR ;;
     9[0-9]) COLOR=$GREEN_COLOR ;;
     8[0-9]) COLOR=$GREEN_COLOR ;;
     7[0-9]) COLOR=$GREEN_COLOR ;;
     6[0-9]) COLOR=$YELLOW_COLOR ;;
     5[0-9]) COLOR=$YELLOW_COLOR ;;
     4[0-9]) COLOR=$YELLOW_COLOR ;;
     3[0-9]) COLOR=$YELLOW_COLOR ;;
     2[0-9]) COLOR=$RED_COLOR ;;
     1[0-9]) COLOR=$RED_COLOR ;;
     *) COLOR=$RED_COLOR ;;
  esac

  case $PERCENTAGE in
     100) ICON=${ICONS[4]} ;;
     9[0-9]) ICON=${ICONS[4]} ;;
     8[0-9]) ICON=${ICONS[3]} ;;
     7[0-9]) ICON=${ICONS[3]} ;;
     6[0-9]) ICON=${ICONS[3]} ;;
     5[0-9]) ICON=${ICONS[2]} ;;
     4[0-9]) ICON=${ICONS[2]} ;;
     3[0-9]) ICON=${ICONS[1]} ;;
     2[0-9]) ICON=${ICONS[1]} ;;
     1[0-9]) ICON=${ICONS[0]} ;;
     *) ICON=${ICONS[0]} ;;
  esac

  [ "$CHARGING" != "" ] && ICON=${ICON_CHARGING}

  sketchybar --set $NAME icon.color=$COLOR icon=$ICON
}

mouse_clicked() {
  sleep 1
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked ;;
  *) update ;;
esac

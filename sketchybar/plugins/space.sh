#!/usr/bin/env sh

# echo "FW: $FOCUSED_WORKSPACE"
FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)

SELECTED="off"
if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  SELECTED="on"
else
  SELECTED="off"
fi

sketchybar --animate tanh 5 --set $NAME icon.highlight=$SELECTED label.highlight=$SELECTED

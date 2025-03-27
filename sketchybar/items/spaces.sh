#!/usr/bin/env sh

SPACE_ICONS=("􀎭" "􀡅" "􁒙" "􀑪" "􀈪" "" "" "" "")
SPACE_LABELS=("web" "code" "chat" "music" "terms")

sketchybar --add event aerospace_workspace_change

for sid in $(aerospace list-workspaces --all); do

  sketchybar --add item "space.$sid" left                \
   --subscribe "space.$sid" aerospace_workspace_change  \
   --set "space.$sid"                                   \
   icon="${SPACE_ICONS[sid-1]}"                         \
   icon.highlight_color=$ACTIVE_COLOR                   \
   label.highlight_color=$ACTIVE_COLOR                  \
   label=${SPACE_LABELS[sid-1]}                         \
   icon.font="$ICON_FONT:Regular:14.0"                  \
   label.font="$FONT:Regular:14.0"                      \
   label.y_offset=1                                     \
   label.padding_left=5                                 \
   background.padding_left=8                            \
   background.padding_right=8                           \
   click_script="aerospace workspace $sid"              \
   script="$PLUGIN_DIR/space.sh $sid"

done


sketchybar  --add bracket spaces space.1 space.2 space.3 space.4 space.5 \
            --set spaces background.border_color=$BORDER_COLOR                                              \
            background.border_width=1                                                                       \
            background.corner_radius=$BORDER_RADIUS                                                         \
            background.padding_left=4                                                                       \
            background.padding_right=4                                                                      \
            background.color=$BACKGROUND_COLOR                                                              \
            background.drawing=on

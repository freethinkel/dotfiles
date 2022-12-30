#!/usr/bin/env sh

SPACE_ICONS=("􀎭" "􀡅" "􁒙" "􀑪" "􀈪" "" "" "" "")
SPACE_LABELS=("web" "code" "chat" "music" "terms")

sid=0
spaces=()

for i in "${!SPACE_ICONS[@]}"; do

 sid=$(($i + 1))
 sketchybar --add space space.$sid left           \
   --set space.$sid associated_space=$sid         \
   icon=${SPACE_ICONS[i]}                         \
   icon.highlight_color=$ACTIVE_COLOR             \
   label.highlight_color=$ACTIVE_COLOR            \
   label=${SPACE_LABELS[i]}                       \
   icon.font="$ICON_FONT:Regular:14.0"            \
   label.font="$FONT:Regular:14.0"                \
   label.y_offset=1                               \
   label.padding_left=5                           \
   background.padding_left=8                      \
   background.padding_right=8                     \
   script="$PLUGIN_DIR/space.sh"                  \
   --subscribe space.$sid mouse.clicked
done


sketchybar  --add bracket spaces space.1 space.2 space.3 space.4 space.5 space.6 \
            --set spaces background.border_color=$BORDER_COLOR                                              \
            background.border_width=1                                                                       \
            background.corner_radius=$BORDER_RADIUS                                                         \
            background.padding_left=4                                                                       \
            background.padding_right=4                                                                      \
            background.color=$BACKGROUND_COLOR                                                              \
            background.drawing=on
